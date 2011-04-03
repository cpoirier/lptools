#!/usr/bin/ruby
#
# The representation of a single lp file.  Also, tools for managing the
# set of lp files in memory.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002-2003.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-unpackaged/language-extensions.rb'
require 'tapestry-packaged/Error.rb'
require 'tapestry-packaged/lp/Patterns.rb'
require 'tapestry-packaged/lp/LPBlock.rb'

module Tapestry
module LP


#
# This module is added to all lines read from an lp file.  It provides
# additional features useful for linking the data back to its input,
# making it easier to produce informative error messages.

module Token

   @file     = ""
   @line     = 0
   @lpfile   = nil

   attr_reader :file, :line, :lpfile

   def Token.associate( object, file="", line=-1, lpfile=nil )
      object.extend( Tapestry::LP::Token )
      object.associate( file, line, lpfile )
      return object
   end

   def associate( file, line, lpfile )
      @file   = file
      @line   = line
      @lpfile = lpfile
   end

   def transfer( object )
      Token.associate( object, @file, @line, @lpfile )
   end

end 





# 
# This class represents a single lp file in memory.

class LPFile

 #-----------------------------------------------------------------------------
 # ITERATORS

   #
   # Cycles through the lines, in document order.  Note that if processed?, the
   # lines may not be the same as those in the file...

   def each_line()

      first = true
      @lines.each do |line|
         if first then
            first = false
            next
         end

         yield( line )
      end

   end


   #
   # Cycles through the blocks in document order.  Meaningless before processed?

   def each_block()
      @blocks.each do |block|
         yield( block )
      end
   end


   #
   # Cycles through the block names in random order.  Meaningless before 
   # processed?

   def each_name()
      @named.keys.each do |name|
         yield( name )
      end
   end


   #
   # Cycles through each named block in random order.  Meaningless before 
   # processed?  

   def each_named()
      @named.values.each do |set|
         set.each do |block|
            yield( block )
         end
      end
   end


   #
   # Cycles through each coalesced block in random order.  Meaningless before
   # processed?

   def each_coalesced()
      @coalesced.values.each do |block|
         yield( block )
      end
   end



 #-----------------------------------------------------------------------------
 # ACCESSORS AND INFORMATION ROUTINES

   #
   # Returns the absolute path to this file

   attr_reader :absolute


   #
   # Returns a hash of name/value pairs for this file

   attr_reader :properties


   #
   # Returns an array of lines in this file.  

   attr_reader :lines


   #
   # Returns the hash of markups.

   attr_reader :markups


   #
   # Returns true iff the file has been processed.

   def processed?()
      return @processed
   end


   #
   # Returns an absolute path given a path relative this one.

   def offset( relative )
      return File.normalize_path( relative, File.dirname(@absolute) )
   end


   #
   # Returns a relative path given an absolute one

   def relative( absolute )
      return File.contract_path( absolute, File.dirname(@absolute), 20 )
   end


   #
   # Returns an array of the language names used in the file.  Meaningless
   # before processed?

   def languages()

      languages = {}

      each_coalesced() do |block|
         languages[block.language] = true unless block.language.to_s == ""
      end

      return languages.keys

   end


   #
   # Returns the coalesced block for the specified name.  Meaningless before
   # processed?

   def coalesced( name )
      return @coalesced[name]
   end


   #
   # Returns the names of all root blocks

   def roots()
      roots = []
      each_coalesced() do |block|
         roots.append( block.name ) if block.root?
      end
      return roots
   end



 #-----------------------------------------------------------------------------
 # REGISTRATION AND LOOKUP

   @@files = {}    # The set of LPFiles, keyed on absolute location

   def register( )
      @@files[@absolute] = self
   end

   def registered?()
      return @@files.member?(@absolute)
   end
  

   #
   # Gets the LPFile object for the specified path.  Use this instead of new()!
   # If process, makes sure the lpfile is process()ed.  

   def LPFile.produce( absolute, process = true )
  
      produced = nil
  
      if @@files.member?(absolute) then
         produced = @@files[absolute]
      else
         produced = LPFile.new( absolute )
      end
  
      LPFile.raise_locationError( "unable to find file", absolute ) if produced.nil?

      produced.process() if process 

      return produced
  
   end



 #-----------------------------------------------------------------------------
 # INITIALIZATION AND SUCH


   @absolute   = ""      # The absolute path to this lp file.
   @raw        = []      # The unprocessed lines of the file (without terminators, with Token)
                         # Index 0 is also an empty string so that line numbers work
   @lines      = []      # The processed lines of the file (without terminators, with Token)
                         # Index 0 is also an empty string so that line numbers work

   @processed  = false   # Set true once process() has been called.

   @blocks     = []      # A set of LPBlocks that cover the entire file
   @properties = {}      # A set of name/value pairs included in the text
   @markups    = {}      # A set of automated markups, keyed on search text

   @named      = {}      # An index of the blocks by name, name => array of block
   @coalesced  = {}      # An index of coalesced blocks by name


   #
   # Standard constructor stuff.  Only loads the lp file.  Call process() to
   # figure out what it means.

   def initialize( absolute )

      type_check( absolute, String )
      assert( File.absolute?(absolute), "file path not absolute" )

      @absolute = absolute
      assert( !registered?(), "attempt to reload an lp file" )
      register()

      begin
         @raw = File.readlines(absolute)
      rescue SystemCallError => error
         LPFile.raise_locationError( "unable to open file", absolute )
      end

      linenumber = 1
      @raw.each do |line|
         line.chomp!
         Token.associate( line, absolute, linenumber, self )
         linenumber += 1
      end

      @raw.prepend("")  

      @lines = @raw

      @processed  = false
      @blocks     = []
      @properties = {}
      @markups    = {}

      @named      = {}
      @coalesced  = {}

   end


   #
   # Processes the lines of the file, handling directives and organizing the
   # text into blocks.

   def process()
    begin

      return false if self.processed?
      @processed = true
      processed  = true

      @lines = @raw.clone


      #
      # The body of this loop can change the list it is iterating.  This
      # is okay, though, because the changes are always further into the
      # list than the current element, and each() does find the new data.
      # We increment linenumber at the top of each loop because it allows
      # us to use next to avoid extra nesting.

      linenumber = 0
      block      = nil
      properties = @properties

      #
      # We run this by index instead of with each() because we have to
      # modify @lines in place during iteration...  It is (@lines.length - 1)
      # because we need to skip the supplied line 0.

      while linenumber < (@lines.length - 1)

         linenumber += 1
         properties = block.properties unless block.nil?

         line = @lines[linenumber]


         #
         # If the line is a directive, we handle it here.  Otherwise, we
         # just append it to the current block.

         isDirective, name, data = Patterns.parseNamedDirective( line )

         unless isDirective
            if block.nil? then
               block = LPBlock.create( self )
               @blocks.append( block )
            end
            block.append( linenumber )

            next   # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
         end


         #
         # If we are still here, we have a directive parsed into name and data.

         next if name.begins("-")  # <<<<<<<<<<<<<<<<<<<

         case name
          when "" then
            block = LPBlock.create( self )
            @blocks.append( block )

          when "block" then
            block = LPBlock.createFromSpec( self, data, line )
            @blocks.append( block )


          when "set" then
            Patterns.processNameValuePair( data, properties, line )


          when "markup" then
            markup = Patterns.processMarkupDirective( data, line )
            @markups[markup["text"]] = markup

          when "no-markup" then
            markup = Patterns.processNoMarkupDirective( data, line )
            @markups[markup["text"]] = markup

          when "cancel-markup" then
            markup = Patterns.processNoMarkupDirective( data, line )
            @markups.delete( markup["text"] )


          when "bookmark" then
            block = LPBlock.createFromSpec( self, data, line )
            block.properties["bookmark"] = "yes"
            @blocks.append( block )

            block = LPBlock.create( self )
            @blocks.append( block )


          when "inherit" then
            inherit = Patterns.processInheritDirective( data, line )
            lpfile  = LPFile.produce( offset(inherit["file"].to_s) )

            lpfile.instance_eval{@markups}.each_pair do |name, info|
               markup = info.clone
               adjustFileParameter( markup, lpfile )
               @markups[name] = markup
            end

            properties.update( lpfile.properties )


          when "include" then
            include = Patterns.processIncludeDirective( data, line )

            if include.member?("name") then
               lpfile = LPFile.produce( offset(include["file"].to_s), true  )
               @lines[linenumber, 1] = lpfile.coalesced(include["name"].to_s).lines
            else
               lpfile = LPFile.produce( offset(include["file"].to_s), false )
               @lines[linenumber, 1] = lpfile.instance_eval{@raw.rest}
            end

            linenumber -= 1


          when "transclude" then
            transclude = Patterns.processIncludeDirective( data, line )
            lpfile     = LPFile.produce( offset(transclude["file"].to_s) )

            if transclude.member?("name") then
               @lines[linenumber, 1] = adjust( lpfile.coalesced(transclude["name"].to_s).lines, lpfile )
            else
               @lines[linenumber, 1] = adjust( lpfile.lines.rest, lpfile )
            end

            linenumber -= 1


          else
            LPFile.raise_parseError( "unrecognized directive", line )
            
         end

      end # while

      index()

      return true

    rescue Tapestry::Error => error
      error.set("token", line) unless error.member?("token")
      raise error
    end

   end # def process()



 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   def LPFile.raise_locationError( details, absolute )
       data  = { "details", details, "file", absolute }
       error = Tapestry::Error( "location error", data )
       error.keyorder = [ "file" ]
       raise error
   end

   def LPFile.raise_parseError( details, token )
      data = { "details", details, "token", token }
      raise Tapestry::Error( "parse error", data )
   end




 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private

   #
   # After process()ing the file, index() indexes the block list and also
   # generates a parallel list in which all blocks with a given name are
   # merged.

   def index()

      @blocks.each do |block|
         name = block.name

         @named[name] = [] unless @named.member?(name)
         @named[name].append( block )

         @coalesced[name] = LPBlock.new( self, name, block.language ) unless @coalesced.member?(name)
         @coalesced[name].append( block )
      end

   end


   #
   # Processes a series of lines, adjusting relative file paths as per
   # a transclusion from lpfile.

   def adjust( lines, lpfile )

      adjusted = lines.map do |line|

         processed = nil

         isDirective, name, data = Patterns.parseNamedDirective( line )
         if isDirective then

            #
            # For any of the directives that contain a relative file name,
            # adjust the path appropriately.  All other directives are left untouched.

            if Patterns.includeDirectiveNames().member?(name) then
               data = Patterns.processIncludeDirective( data, line )
               if adjustFileParameter( data, lpfile ) then
                  processed = Patterns.assembleIncludeDirective( data, name )
                  line.transfer(processed)
               end

            elsif name == "markup" then
               data = Patterns.processMarkupDirective( data, line )
               if adjustFileParameter( data, lpfile ) then
                  processed = Patterns.assembleMarkupDirective( data )
                  line.transfer(processed)
               end

            end

            processed = line.clone if processed.nil?


         else

            #
            # For an references that contain relative file names, adjust the 
            # path appropriately

            processed = line.gsub( Patterns.referencePattern ) do |match|
               m    = $~
               data = Patterns.processReferenceDirective( m[1], line )

               if adjustFileParameter( data, lpfile ) then
                  Patterns.assembleReferenceDirective( data )
               else 
                  match
               end
            end

            line.transfer(processed)
         end

         processed

      end

      return adjusted

   end


   #
   # Given a parameter set (in a hash), adjusts the "file" parameter 
   # appropriately for a transclusion from lpfile.  Returns true iff the
   # parameter was adjusted.

   def adjustFileParameter( data, lpfile )

      adjusted = false
      if data.member?("file") && !File.absolute?(data["file"]) then
         data["file"] = relative( lpfile.offset(data["file"]) )
         adjusted = true
      end
      return adjusted

   end

   
end  # LPFile


end  # LP
end  # Tapestry


