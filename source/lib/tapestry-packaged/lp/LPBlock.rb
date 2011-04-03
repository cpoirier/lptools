#!/usr/bin/ruby
#
# The representation of a single lp block.  
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

module Tapestry
module LP


# 
# This class represents a single lp file in memory.

class LPBlock


 #-----------------------------------------------------------------------------
 # INSTANTIATION

   #
   # Creates an LPBlock with no name

   def LPBlock.create( lpfile )
      return LPBlock.new( lpfile )
   end


   #
   # Creates an LPBlock from descriptor text

   def LPBlock.createFromSpec( lpfile, directive, line )
      data = Patterns.processBlockDirective( directive, line )
      return LPBlock.new( lpfile, data.fetch("name", ""), data.fetch("language", ""), data.member?("root") )
   end



 #-----------------------------------------------------------------------------
 # ITERATORS

   #
   # Calls your code for each line in the block.

   def each_line()
      @lines.each do |linenumber|
         yield( @lpfile.lines[linenumber] )
      end
   end



 #-----------------------------------------------------------------------------
 # ACCESSORS AND INFORMATION ROUTINES

   #
   # Returns the LPFile do which this block belongs

   attr_reader :lpfile


   #
   # Returns the name of this block

   attr_reader :name


   #
   # Returns the language of this block

   attr_reader :language


   #
   # Returns the hash of properties for this block

   attr_reader :properties


   #
   # Returns true iff the block has no lines

   def empty?()
      return @lines.empty?
   end


   #
   # Returns false iff the block has at least one line that isn't
   # just whitespace.

   def collapsible?()

      collapsible = true

      each_line() do |line|
         if !Common.isWhitespace(line) then
            collapsible = false
            break
         end
      end

      return collapsible

   end


   #
   # Returns true iff this is a code block.
  
   def code?()
      return (not @name.empty? and not @language.empty?)
   end


   #
   # Returns true iff this block is marked as a root.

   def root?()
      return @properties.member?( "root" )
   end


   #
   # Returns the text of the first line, or nil

   def getFirstLine()

      line = nil
      unless @lines.empty?
         line = @lpfile.lines[@lines[0]]
      end
      return line

   end


   #
   # Returns the text of the block as an array of lines

   def lines()

      lines = []
      each_line() do |line|
         lines.append( line )
      end
      return lines

   end




 #-----------------------------------------------------------------------------
 # CORE ACTIONS

   #
   # Compiles the block by expanding any embedded block references.  into must
   # have an << operator.  Referenced data will be transcluded in place of the
   # reference marker.  If a referenced block contains multiple lines, each
   # line will be bracketed by the data surrounding the reference.  If the 
   # bracketing text isn't whitespace, line directives will be suppressed.

   def compile( into, macros = nil, linedirectives = true, recursionsLeft = 20, leftIndent = "", rightIndent="", suppressLineDirectives = false )

      if recursionsLeft == 0 then
         LPBlock.raise_compilationError( "excessive recursion detected", getFirstLine() )
      end
      recursionsLeft -= 1


      previous = nil
      each_line() do |line|

         processed = line.clone

         #
         # Replace macros, if requested.

         unless macros.nil?
            processed.gsub!(Patterns.macroPattern) do |match|
               macros[$1].to_s
            end
         end


         #
         # Replace cross reference patterns with the appropriate text (label or name).
         # We do this first because the reference pattern will match cross 
         # references as well.

         while processed =~ Patterns.xReferencePattern
            m = $~

            directive = m[1]
            processed.transfer(directive)

            data = Patterns.processReferenceDirective( directive, line )
            processed = processed.slice( 0, match.begin(0) ) + data["label"].to_s + processed.slice(match.end(0), processed.length)
         end


         #
         # Next expand compilable references.  
         
         if processed =~ Patterns.referencePattern then
            m         = $~
            directive = $1
            before    = $`
            after     = $'


            data = Patterns.processReferenceDirective( directive, line )

            blockname = data["name"]
            if blockname.nil? then
               LPBlock.raise_compilationError( "a block reference must specify a block name", line )
            end 


            #
            # We now get the LPFile in which the requested block lives.  If no
            # file is specified, we use our own LPFile.

            lpfile   = @lpfile
            filename = data["file"]

            unless filename.nil? or filename == "" 
               begin
                  lpfile = LPFile.produce( @lpfile.offset(filename) )
               rescue Tapestry::Error => error
                  error.set( "token", line )
                  raise error
               end
            end


            #
            # Finally, we recurse to the referenced block.

            block = lpfile.coalesced( blockname )

            if block.nil? then
               LPBlock.raise_compilationError( "unable to find referenced block", line )
            end

            childSupressLineDirectives = false
            if suppressLineDirectives or not Patterns.isWhitespace( before ) or not Patterns.isWhitespace( after ) then
               childSuppressLineDirectives = true
            end

            block.compile( into, macros, linedirectives, recursionsLeft, leftIndent + before, after + rightIndent, childSuppressLineDirectives )

            previous = nil if linedirectives



         else

            #
            # If the line wasn't itself compilable, simply output it, possibly with
            # a line directive

            if linedirectives and not suppressLineDirectives then
               outputLineDirective( into, processed, previous )
               previous = processed
            end

            into << leftIndent + processed + rightIndent + "\n"
         end

      end

   end


   #
   # Outputs the block with lp tokens replaced by spaces.  Can optionally add
   # line directives.

   def strip( into, linedirectives = false )

      previous = nil
      each_line() do |unprocessed|

         line = unprocessed.clone

         line = line.gsub( Patterns.xReferencePattern ) do |match|
            " " * match.length
         end

         line = line.gsub( Patterns.referencePattern ) do |match|
            " " * match.length 
         end

         if linedirectives then
            outputLineDirective( into, unprocessed, previous )
            previous = unprocessed
         end

         into << line + "\n"

      end

   end



 #-----------------------------------------------------------------------------
 # INITIALIZATION AND SUCH


   @lpfile     = nil    # The LPFile which holds this block
   @name       = nil    # This block's name, or ""
   @language   = nil    # This block's language, or ""

   @lines      = []     # The line numbers in this block, in order
   @properties = {}     # A set of name/value pairs for this block


   def initialize( lpfile, name = "", language = "", root = false )

      @lpfile     = lpfile 
      @name       = name
      @language   = language

      @lines      = []
      @properties = {}

      @properties["root"] = "yes" if root

   end


   #
   # Adds a linenumber to the blocks set of lines.  If you pass an LPBlock,
   # all its lines are added, as are its properties.

   def append( linenumber )
      if linenumber.kind_of?(LPBlock) then
         block = linenumber

         if @language != block.language then
            LPBlock.raise_continuationError( self, block )
         end

         @lines.concat( block.instance_eval { @lines } )
         @properties.update( block.properties )

      else
         @lines.append( linenumber )
      end
   end



 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   def LPBlock.raise_compilationError( details, token )
       data = { "details", details, "token", token }
       raise Tapestry::Error( "compilation error", data )
   end


   def LPBlock.raise_continuationError( first, second )
      data  = { "details",           "continuation block uses different language" \
              , "expected-language", first.language                               \
              , "found-language",    second.language                              \
              , "start-token",       first                                        \
              , "token",             second                                       }
      error = Tapestry::Error( "sanity error", data )
      error.keyorder = ["expected-language", "found-language"]
      raise error
   end




 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private

   #
   # Outputs a line directive, in required.  Pass Tokens for current and
   # previous.

   def outputLineDirective( into, current, previous )

      if current.file.nil? then
         puts "it is nil!!!"
         puts current.length.to_s + ": " + current.to_s
         puts current.line.to_s
         puts current.file.to_s
         exit 20
      end

      if previous.nil? or previous.file != current.file or current.line != (previous.line + 1) then
         into << Patterns.makeLineDirective(current.line, current.file) + "\n"
      end

   end


end  # LPFile


end  # LP
end  # Tapestry



