#!/usr/bin/ruby
#
# The System acts as the main controller for the build system.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002, 2003.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-unpackaged/language-extensions.rb'
require 'tapestry-packaged/Error.rb'
require 'tapestry-packaged/ErrorSet.rb'
require 'tapestry-packaged/build/Graph.rb'
require 'tapestry-packaged/build/Zone.rb'

require 'singleton'


module Tapestry
module Build


class System

 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   @@tolerance = 10       # The number of non-fatal errors which will be buffered before terminating the run

   def System.tolerance()
      return @@tolerance
   end

   def System.tolerance=( tolerance )
      @@tolerance = 0 + tolerance
   end



 #-----------------------------------------------------------------------------
 # OUTPUT AND SUCH

   @@verbosity = 1        # Controls how much output the system generates.  0 is none, 1 is default, 2 is lots
   @@marker    = ">>> "   # Prepended to system output.


   def System.verbosity()
      return @@verbosity
   end

   def System.verbosity=( verbosity )
      @@verbosity = 0 + verbosity
   end

   def System.marker()
      return @@marker
   end

   def System.skip( count = 1, stream = STDOUT )
      1.upto(count) do 
         stream.puts()
      end
   end

   def System.puts( message, indent = 0, stream = STDOUT )
      stream.puts( @@marker + (" " * indent) + message )
   end



 #-----------------------------------------------------------------------------
 # BASIC OPERATIONS

   @@locked = false    # Set true by lockdown(), which is run after the system has finished productions

   def System.locked?()
      return @@locked
   end


   @@root = nil        # The first zone created, and the one used as default for the system

   def System.root()
      return @@root
   end


   @@loadOnly = false  # If true, does not start the build engine

   def System.loadOnly?()
      return @@loadOnly
   end

   def System.loadOnly=( boolean )
      @@loadOnly = true && boolean
   end



   @@startDirectory = nil  # The directory in which the build system was started

   def System.relativeStart( absolute )
      return File.contract_path( absolute, @@startDirectory )
   end



   


   def System.run( targets = [], file = "Buildfile", home = Dir.pwd(), targetsDir = home )

      count = 0

      @@startDirectory = Dir.pwd()

      System.puts( "loading zones" ) if self.verbosity > 0
      @@root = Zone.new( file, home, targetsDir )

      unless self.forHelpOnly? or self.loadOnly?
         System.puts( "starting build" ) if self.verbosity > 0
         lockdown()

         if targets.length == 0 then
            if @@root.alias?("all") then
               targets = ["all"]
            else
               targets = ["@end-targets"]
            end
         end

         count = @@root.build( targets )
      end

      return count

   end



 #-----------------------------------------------------------------------------
 # FUNCTOR HELP SUPPORT

   @@forHelpOnly = false  # If true, the system is run only for the purpose of loading functions.

   def System.forHelpOnly?()
      return @@forHelpOnly
   end


   @@functors = nil   # If run for functor help, prepareHelp() sets it to the available functors

   def System.functors()
      return @@functors
   end


   #
   # Sets up the system for the production of functor help.  I dislike the
   # way this has turned out, but it will have to do, for now...

   def System.prepareHelp( userCodeFile = "" )

      @@forHelpOnly  = true
      self.verbosity = 0

      if !userCodeFile.nil? and userCodeFile != "" then
         System.run( [], userCodeFile )
         @@functors = @@root.interpreter.functors.to_h
      else
         @@functors = Tapestry::Build::Interpreter::Function.getBuiltins()
      end

   end



 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private

   #
   # Called after all Zones have been loaded and run.  Prepares the system for
   # the build phase.

   def System.lockdown()

      @@locked = true

      Graph.lockdown()
      Graph.untouch("analyzer")

   end


end  # System


end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__

   def space()
      puts()
   end

   def header()
      puts( "------------------------------------------------------------------" )
   end

   def message( message )
      space()
      header()
      puts( message                                                              )
   end


   def report( error, askBacktrace = true )

      if error.kind_of?(Tapestry::Error) then
         error.keyorder = ["error class", "details"] + error.keyorder + ["file", "line", "position"]
         error.keyignore = [ "token" ]

         token = error.get("token")
         unless token.nil?
            begin
               error.set( "file"    , token.file     )
               error.set( "line"    , token.line     )
               error.set( "position", token.position )
            rescue NameError
            end
         end
      end

      message( "An error occurred during processing." )
      puts(               )
      puts( error.message )
      puts(               )

      backtrace = !askBacktrace

      if askBacktrace then
         header()
         print( "display backtrace? " )
         line = STDIN.gets()
         line.chomp!
         backtrace = true if line.begins("y") or line.begins("Y")
      end

      if backtrace then
         header() unless askBacktrace
         puts( error.backtrace )
      end

   end




   begin
#      puts Tapestry::Build::PRODUCT + " " + Tapestry::Build::VERSION
      puts

      system = Tapestry::Build::System

      data = ARGV
      BUILDFILE = data.remove_head()
      count = system.run( data, BUILDFILE )

      puts()
      puts()
      puts()
      puts( ">>> built " + count.to_s + " target(s)" )

      if false then
         space()
         header()
         puts( "Raw Sources:" )
         puts( "   " + system.root.resolveAlias("@raw-sources").join( "\n   ") )

         space()
         header()
         puts( "All Targets:" )
         puts( "   " + system.root.resolveAlias("@all-targets").join( "\n   ") )
   
         space()
         header()
         puts( "End Targets:" )
         puts( "   " + system.root.resolveAlias("@end-targets").join( "\n   ") )
      end



   rescue Tapestry::ErrorSet => set
      set.each do |error|
         report( error )
      end

   rescue Tapestry::Error => error
      report( error )

   rescue Exception => error
      report( error, false )
   end

end


