#!/usr/bin/ruby
#
# These classes provide the basis of the build runtime.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-packaged/build/LocationManager.rb'
require 'tapestry-packaged/build/Graph.rb'
require 'tapestry-packaged/build/ProductionEngine.rb'
require 'tapestry-packaged/build/BuildEngine.rb'
require 'tapestry-packaged/build/interpreter/Interpreter.rb'

module Tapestry
module Build


#
# build arranges its work in zones.  Each zone is independent, and all 
# files created by the zone are created in the root of its target directory. 
# Unless otherwise specified, the zone's target directory is the same as its
# home directory.

class Zone

   #
   # The zone acts as a hub for the processes of a set of files within a
   # directory.  The actual work is performed by related objects.

   @interpreter = nil    # The user instructions describing the zone
   @location    = nil    # Directory handling for the zone

   @aliases     = nil    # Target aliases - a hash of name/targets pairs
   @macros      = nil    # Action targets - a hash of name/[code, dependencies] pairs

   @producer    = nil    # The production engine, for calculating the build graph
   @builder     = nil    # The build engine, for creating targets

   attr_reader :location, :interpreter, :producer, :builder


   #
   # buildfile is the path to the buildfile, either relative to home,
   # or absolute.  The buildfile is executed immediately, but only
   # productions are run.  Building is started with startBuild().

   def initialize( buildfile, home = Dir.pwd(), targets = home, parent = nil )

      if System.verbosity > 1 then
         System.skip(2)
         System.puts( "loading Zone in: #{home}" )
      end


      @location = Tapestry::Build::LocationManager.new( home, targets )
      register()


      absolute = @location.offsetHome( buildfile )
      begin
         file = File.open(absolute)

         globals = ( parent.nil? ? nil : parent.instance_eval{@interpreter}.globals )
         @interpreter = Tapestry::Build::Interpreter::Interpreter.new( self, file, absolute, globals )

      rescue SystemCallError
         raise_instructionsFileError( absolute )
      ensure
         file.close unless file.nil?
      end


      @producer = ProductionEngine.new( self )
      @builder  = BuildEngine.new( self )

      @macros   = {}
      @aliases  = {}
      @aliases["@defined-sources"] = {}   # Maintained by registerSources()
      @aliases["@all-targets"]     = {}   # Maintained by notify*()
      @aliases["@end-targets"]     = {}   # Maintained by notify*()

      @location.chdirHome()
      @interpreter.run()

   end


   def to_s()
      return @interpreter.to_s()
   end



 #-----------------------------------------------------------------------------
 # ZONE DATA STRUCTURE MANAGEMENT


   #
   # A simple wrapper on ProductionEngine.addRule().  See it for details on the
   # parameters.

   def registerProduction( name, priority, dynamicSource, source, dynamicTarget, target, action, supplement )
      @producer.addRule( name, priority, dynamicSource, source, dynamicTarget, target, action, supplement )
   end


   #
   # Adds sources to the production engine, which populates the build graph.  
   # Also updates builtin alias "defined-sources".

   def registerSources( sources, localScope = @interpreter.globals, code = nil )
      unless System.forHelpOnly?
         @producer.process( localScope, sources, code )
      end
   end


   #
   # Adds an alias to the zone.  If the alias already exists, it is 
   # replaced with the new definition.

   def registerAlias( name, targets )
      @aliases[name] = targets unless name.begins("@")
   end


   #
   # Adds a macro to the zone.  If the macro already exists, it is
   # replaced with the new definition.  Returns the cleaned 
   # dependencies.

   def registerMacro( macro, code, dependencies = nil )

      clean = []
      unless dependencies.nil?
         clean = dependencies.map do |dependency|
            offsetHome(dependency)
         end
      end

      @macros[macro] = [code, clean]

      return clean

   end


   #
   # A simple wrapper on BuildEngine.addAnalyzer().  See it for details on 
   # the parameters.

   def registerAnalyzer( name, dynamicSource, source, target )
      @builder.addAnalyzer( name, dynamicSource, source, target )
   end


   #
   # A simple wrapper on BuildEngine.addAction().  See it for details on the
   # parameters.

   def registerAction( name, code, style )
      @builder.addAction( name, code, style )
   end



 #-----------------------------------------------------------------------------
 # INFORMATION ROUTINES


   #
   # Converts a path relative this zone to an absolute path.

   def offsetHome( path )
      return @location.offsetHome(path)
   end

   def offsetTargets( path )
      return @location.offsetTargets(path)
   end


   #
   # Returns various important zone paths.

   def home()
      return @location.home
   end

   def targets()
      return @location.targets
   end


   #
   # Converts an absolute path to one relative this zone, if
   # possible.  An absolute path is returned if the absolute path
   # is branches more than three directory levels above the 
   # zone home.

   def relativeHome( path )
      return @location.relativeHome(path)
   end

   def relativeTargets( path )
      return @location.relativeTargets(path)
   end


   #
   # Returns true if this zone has an alternate target directory.

   def retargetted()
      return @location.home != @location.targets
   end


   #
   # Given a suggested target path, returns the acceptable logical target,
   # as dictated by system policy.  Currently, all logical zone targets 
   # are placed in the root of the zone home directory.

   def enforceLogicalTargetPolicy( location )
      return offsetHome( File.basename(location) )
   end


   #
   # Given a suggested target path, returns the acceptable actual target,
   # as dictated by system policy.  Currently, all actual zone targets 
   # are placed in the root of the zone target directory.

   def enforceActualTargetPolicy( location )

      location = enforceLogicalTargetPolicy( location )

      if retargetted() then
         location = offsetTargets( File.basename(location) )
      end

      return location

   end



 #-----------------------------------------------------------------------------
 # MACROS, ALIASES, AND TARGETS

   #
   # Returns true if the named target is a macro

   def macro?( name )
      return @macros.member?(name)
   end


   #
   # Returns true if the named target is an alias

   def alias?( name )
      return @aliases.member?(name)
   end


   #
   # Returns the named user alias, or nil if it isn't an alias

   def resolveAlias( name, default = nil )

      value = default

      if alias?(name) then
         value = @aliases[name]

         if value.kind_of?(Hash) then
            value = value.keys
         end
      end

      return value

   end


   #
   # Iterates through the aliases, passing name, value to your block.

   def each_alias()
      @aliases.each_pair do |name, set|
         set = set.keys if set.kind_of?(Hash) 
         yield( name, set )
      end
   end


   #
   # Iterates through the macros, passing name, value to your block

   def each_macro()
      @macros.each_pair do |name, code|
         yield( name, code )
      end
   end



   #
   # Resolves a wildcard target into a list of actual targets.
   # Matches against all zones.

   def Zone.resolveWildcard( absolute, defaultZone )

      targets = []

      directory = Dir.normalize_path(File.dirname(absolute))
      pattern   = Wildcard.compile( directory + "name" )

      Zone.each_zone do |location, zone|
         if (location + "name") =~ pattern then
            set = zone.resolveWildcard( absolute )
            set.each do |target|
               targets.append( zone.offsetHome(target) )
            end
         end
      end

      return targets

   end


   #
   # Once we know the wildcard is local, we simply expand it using
   # our macros, aliases, and targets.

   def resolveWildcard( absolute )

      targets = {}
      pattern = Wildcard.compile( offsetHome(absolute) )

      resolveAlias("@all-targets").each do |target|
         targets[relativeHome(target)] = true if target =~ pattern
      end

      each_alias do |name, value|
         targets[name] = true if offsetHome(name) =~ pattern
      end

      each_macro do |name, value|
         targets[name] = true if offsetHome(name) =~ pattern
      end

      return targets.keys

   end




 #-----------------------------------------------------------------------------
 # THE POINT OF IT ALL

   #
   # Kicks of the build process for the named targets.  Macros and aliases
   # are handled here, in the order in which they appear.  Returns the
   # number of targets built as a result of this call.

   def build( targets, errorSet = Tapestry::ErrorSet( System.tolerance ), report = false )

      count = 0
      targets = [targets] unless targets.kind_of?(Array)

      until targets.empty?
       begin

         target   = targets.remove_head()
         absolute = offsetHome( target )

         if Wildcard.count(target) > 0 then
            resolved = []
            if Wildcard.directory?(target) then
               resolved = Zone.resolveWildcard( absolute, self )
            else
               resolved = resolveWildcard( target )
            end

            if System.verbosity > 4 then
               System.puts "#{target} resolved to: "
               resolved.each do |current|
                  System.puts( current, 3 )
               end
            end

            resolved.each do |current|
               targets.prepend( current )
            end

            next
         end


         zone = Zone.find( absolute )

         #
         # First validate that this target belongs to us and leave
         # this iteration if it doesn't.  Target errors cause build()
         # to terminate immediately.  They are only raised by build().

         if zone.nil? then
            raise_targetError( target )

         elsif zone != self then
            count += zone.build( [absolute] )            
            next

         end


         #
         # We are still here, so ensure the target is resolved.

         target = relativeHome( absolute )


         #
         # If it is a macro, execute it, and add one to the built count

         if macro?(target) then
            code, dependencies = @macros[target]
            unless code.nil?

               dependenciesBuilt = false
               unless dependencies.nil?
                  begin 
                     count += build( dependencies, errorSet )
                     dependenciesBuilt = true

                  rescue Tapestry::ErrorSet => error
                     errorSet.merge( error )          # Raises errorSet if cause?

                  rescue Tapestry::Error => error
                     errorSet.add( error )            # Raises errorSet if cause?
                  end
               end

               raise errorSet unless dependenciesBuilt

               begin
                  unless @interpreter.booleanize( @interpreter.interpret(code) )
                     raise_targetError( target, "macro failed" )
                  end
               rescue Tapestry::Error => error
                  error.fatal = true
                  raise error
               end

               count += 1
            end


         #
         # If it is an alias, expand it in place.

         elsif alias?(target) then
            targets = resolveAlias(target) + targets


         #
         # Otherwise, build it as a target.

         else
            node = Graph.find( absolute, true )
            assert( node.zone(self) == self, "somehow, a target in this zone is not in this zone..." )

            count += @builder.build( node, errorSet )
         end


       rescue Tapestry::ErrorSet => error
          errorSet.merge( error )                # Raises if errorSet.cause?

       rescue Tapestry::Error => error
          errorSet.add( error )                  # Raises if errorSet.cause?

       end
      end

      raise errorSet unless errorSet.empty?
      return count

   end



 #-----------------------------------------------------------------------------
 # ZONE REGISTRATION AND LOOKUP

   #
   # Each zone is described by a Buildfile, which covers the directory it 
   # is in and all subdirectories that do not contain their own Buildfiles.
   # We register each zone under its absolute path, and provide facilities
   # to search.

   @@zones = {}  # A hash of BuildZone objects, keyed on absolute path


   #
   # Registers a zone.  You don't need to use it directly.

   def register()
      @@zones[@location.home] = self
   end 
   private:register 


   #
   # Searches for the zone that best matches the specified file or directory.
   # Returns the zone or the specified value if no match is found.

   def Zone.find( absolutePath, zone = nil )

      # First, strip off any filename attached to the path

      before = ""
      until File.directory?( absolutePath ) or before == absolutePath 
         before = absolutePath
         absolutePath = Dir.normalize_path(File.dirname( absolutePath ))
      end


      # Then, search for the most specific matching zone, by iteratively
      # stripping off sub-directory names from the path until a match is
      # found or we run out of path..

      before = ""
      while zone.nil? and absolutePath != before
         before = absolutePath
         if @@zones.member?(absolutePath) then
            zone = @@zones[absolutePath]
         else
            absolutePath = Dir.normalize_path(File.dirname(absolutePath))
         end
      end

      return zone

   end


   #
   # Cycles through all registered zones, passing [absolute, zone]

   def Zone.each_zone()
      @@zones.each_pair do |absolute, zone|
         yield( absolute, zone )
      end
   end




 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   def raise_targetError( target, details = "target not found", fatal = true )
      raise Tapestry::Error( "target error", \
         { "details", details                \
         , "target",  target                 \
         , "zone",    self.home              }, fatal )
   end


   def raise_instructionsFileError( filename, token = nil, details = "unable to open instructions file" )
      error = Tapestry::Error( "load error",           \
         { "details",           details                  \
         , "instructions-file", filename                 \
         , "zone",              self.home                \
         , "token",             token                    }, true )

      error.keyorder = ["instructions-file", "zone"]

      raise error
   end


 #-----------------------------------------------------------------------------
 # NOTIFICATION FROM GRAPH

   #
   # Received when one of our nodes has added a source.  We use the notification
   # to update our builtin aliases.

   def notifyAddSource( node, sources, targets, action )
      location = node.logical

      @aliases["@all-targets"][location] = true
      @aliases["@end-targets"][location] = true if targets == 0

      targetsBy = "@targets-by-" + action
      @aliases[targetsBy] = {} unless @aliases.member?(targetsBy)
      @aliases[targetsBy][location] = true

   end


   #
   # Received when one of our nodes has added a target.  We use the notification
   # to update our builtin aliases.

   def notifyAddTarget( node, sources, targets, action )
      @aliases["@end-targets"].delete(node.logical)

      sourcesBy = "@sources-by-" + action
      @aliases[sourcesBy] = {} unless @aliases.member?(sourcesBy)
      @aliases[sourcesBy][location] = true
   end



   #
   # Received when the ProductionEngine receives a new source. 

   def notifyAddRawSource( absolute )
      @aliases["@defined-sources"][absolute] = true
   end

end  # Zone



end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__

   puts "test from System instead"

end


