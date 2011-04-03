#!/usr/bin/ruby
#
# A support class used to help convert lp files into XML documentation.
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

require 'tapestry-packaged/Error.rb'
require 'tapestry-packaged/lp/Patterns.rb'
require 'tapestry-packaged/lp/LPFile.rb'
require 'tapestry-packaged/lp/LPBlock.rb'


module Tapestry
module LP
class DocumentorXML

   def initialize( stylesheet="", type="text/xsl" )
      DocumentorXML.initTags()

      @stylesheet = stylesheet
      @styletype  = type

      @tags = @@xmlDocumentTags
   end

   #
   # Uses << to write the fully assembled (X|SG)ML documentation
   # into into.  See LP::LPBlock.document for full details.

   def document( lpfile, into, delimitParagraphs=true, markupTextBlocks=false, convertXMLInCodeBlocks=false )

      roots = lpfile.roots


      #
      # Output the XML header stuff

      into << '<?xml version="1.0"?>' + "\n"
      into << '<?xml-stylesheet href="' + @stylesheet + '" type="' + @styletype + '"?>' + "\n"   if @stylesheet != ""


      #
      # Start the doc and include all the file properties.

      into << makeOpenTag( @tags["document"], lpfile.properties ) + "\n"


      #
      # Compile all the markups.  The anti search ensures that matches inside
      # reference tags and xml attribute values are ignored, which is a 
      # good plan.  Matches inside identifiers are acceptable, though...

      info    = Hash.new();
      markups = Array.new();

      lpfile.markups.each_value do |markup|
         quoted = Regexp.quote(markup["text"])
         next if quoted.empty?

         search     = Regexp.compile( "(\\A|[^\\w])(" + quoted + ")([^\\w]|\\Z)" )
         antisearch = Regexp.compile( "(\\{\\{.*?" + quoted + ".*?\\}\\})|(\".*?" + quoted + ".*?\")" )

         info.clear
         info["file"] = markup["file"]
         info["name"] = markup["name"]
         info["xref"] = "yes" 

         replace = makeOpenTag( @tags["reference"], info ) + markup["text"] + makeCloseTag( @tags["reference"] )

         markups.append( [ search, markup["text"].length, replace, antisearch, markup.member?("name") ] )
      end


      #
      # Output the blocks
  
      blockinfo = Hash.new()
      lpfile.each_block do |block|

         #
         # Determine the type of block to generate, and set up the properties.

         blockinfo.clear
         blockinfo.update(block.properties)
         blockinfo.delete("name")
         blockinfo.delete("language")

         outputBlockTag = false
         outputBlockTag = true if markupTextBlocks
         unless block.name.empty?
            outputBlockTag = true
            blockinfo["name"]     = block.name
            blockinfo["language"] = block.language unless block.language.empty?
         end

         
         #
         # Open the block tag, if necessary

         if outputBlockTag
            into << makeOpenTag( @tags["block"], blockinfo ) + "\n"
         end


         #
         # Place <lp:p> tags around each paragraph, if requested.
         # Replace block references and identifiers with XML tags, and
         # assembles the entire block into one string, for further 
         # processing.  Unfortunately, this is going to generate lots
         # of garbage.  If it's a serious problem, we can revisit it later.

         blocktext = ""
         label     = ""
         info      = Hash.new()

         if delimitParagraphs and not block.code? then
            allowParagraphing = true
         else
            allowParagraphing = false
         end

         considerParagraphing = true
         inParagraph = false

         block.each_line do |unprocessed|

            line = unprocessed.clone


            #
            # Insert <lp:p> tags around identifiable, untagged paragraphs.         
            # Paragraphs are separated by a blank line.  If a paragraph 
            # starts with a tag, it will be skipped.  

            if allowParagraphing then 
               if Patterns.isWhitespace(line) then
                  considerParagraphing = true
                  if inParagraph then
                     line = makeCloseTag( @tags["paragraph"] ) + line
                     inParagraph = false
                  end
               elsif considerParagraphing then
                  if line =~ @@initialTagSearchPattern then
                     considerParagraphing = false
                  else
                     line = makeOpenTag( @tags["paragraph"], nil ) + line
                     inParagraph = true
                     considerParagraphing = false
                  end
               end
            end


            #
            # Handle the markup directives first.  As discussed in lphelp, if two
            # searches match at the same location, the longer is taken.  If one match
            # starts within the text of another, the second is ignored.  

            matches = Hash.new()


            #
            # First, find the matches, taking the longer of any concurrent matches.
            # matches will be keyed on start index, and hold an array of match length,
            # replacement text, and a flag that indicates if the match should be 
            # replaced with markup.  We skip any matches that fall within an 
            # antisearch match.

            markups.each do |markup|
               search     = markup[0]
               antisearch = markup[3]

               unsearched = line.gsub( antisearch ) do |match|
                  " " * match.length
               end

               match = search.match( unsearched )
               until match.nil? or unsearched.empty?
                  start = match.begin(2)

                  unless matches.member?(start) and matches[start][0] > markup[1] then
                     matches[start] = [ markup[1], markup[2], markup[4] ]
                  end

                  unsearched = match.pre_match + match[1] + (" " * match[2].length) + match[3] + match.post_match
                  match = search.match( unsearched )
               end
            end


            #
            # Now that we have all the matches, step through the matches in order from
            # left to right.  Overlapped matches will simply be ignored.  Actual text
            # is only replaced if the match data indicates that it should be.  This is
            # were @no-markup is implemented.

            position  = 0    # The position in the original text
            expansion = 0    # The number of extra characters inserted into the original text

            matches.keys.sort.each do |start|
               next if start < position
               data = matches[start]

               if data[2] then
                  line = line.slice(0, start+expansion) + data[1] + line.slice(start+expansion+data[0], line.length )
               end

               position   = start + data[0]
               expansion += (data[1].length - data[0])
            end



            
            #
            # Replace the {{{cross-reference}}} with tags.

            while line =~ Patterns.xReferencePattern
               match = $~

               info.clear
               info["xref"] = "yes"

               Patterns.processReferenceDirective( match[1], unprocessed, info )

               label = info["label"]
               info.delete("label")


               line = line.slice(0, match.begin(0)) + 
                      makeOpenTag( @tags["reference"], info ) +
                      (block.code? ? "" : makeOpenTag( @tags["identifier"], nil )) +
                      label + 
                      (block.code? ? "" : makeCloseTag( @tags["identifier"] )) +
                      makeCloseTag( @tags["reference"] ) + 
                      line.slice(match.end(0), line.length)
            end 


            
            #
            # Replace the {{reference}} markers with tags.
    
            while line =~ Patterns.referencePattern
               match = $~

               info.clear
               Patterns.processReferenceDirective( match[1], unprocessed, info )

               label = info["label"]
               info.delete("label")

               line = line.slice(0, match.begin(0)) + 
                      makeOpenTag( @tags["reference"], info ) +
                      label + 
                      makeCloseTag( @tags["reference"] ) + 
                      line.slice(match.end(0), line.length)
            end 


            #
            # Replace the [[identifer]] markers with tags.


            while line =~ Patterns.identifierPattern
               match = $~

               line = line.slice(0, match.begin(0)) +
                      makeOpenTag( @tags["identifier"], nil ) +
                      $1 +
                      makeCloseTag( @tags["identifier"] ) +
                      line.slice(match.end(0), line.length)
            end


            blocktext += line + "\n"
         end

   
         if inParagraph then
            blocktext += makeCloseTag( @tags["paragraph"] ) + "\n"
         end


         #
         # Convert special characters into entities.  We do this
         # by finding each special character and determining if
         # it is being used for XML.  If not, we convert it to
         # an entity. 

         conversionPattern = @@specialCharactersSearchPattern
         if convertXMLInCodeBlocks and block.code? then
            conversionPattern = @@specialCharactersSearchAllowLPOnlyPattern
         end

         while blocktext =~ conversionPattern
            match = $~

            into << blocktext.slice(0, match.begin(0))

            if $5.nil? then

               #
               # The match is an XML structure, and we'll just output it.

               into << match[0]
 
            else
              
               #
               # The match is not an XML structure, and we'll convert it.

               case $5
                when "<"
                  into << "&lt;"
                when ">"
                  into << "&gt;"
                when "&"
                  into << "&amp;"
                end

            end

            blocktext = blocktext.slice( match.end(0), blocktext.length )
         end

         into << blocktext


         #
         # Close the block tag, if ncessary 

         if outputBlockTag then
            into << makeCloseTag( @tags["block"] ) + "\n"
         end 
      end      


      #
      # We're done.

      into << makeCloseTag( @tags["document"] ) + "\n"
   end


 private 

   #
   # Used to classify each XML special character.  The first clause matches an XML open tag.
   # The second matches an XML close tag.  The third matches an XML entity.  The fourth
   # clauses matches an XML comment (not line spanning).  The fifth matches everything else,
   # which will need to be converted to entities.

   @@specialCharactersSearchPattern = 
       /(<[\w_:][\w\d\.\-_:]*(?:\s+[\w\d\.\-_:]+\=\"[^"\n]*\")*\s*[\/]?>)|(<\/[\w_:][\w\d\.\-_:]*>)|(\&[\w\d#][\w\d]*;)|(<!-- .*? -->)|([<>&])/

   @@specialCharactersSearchAllowLPOnlyPattern =
       /(<lp:[\w_][\w\d\.\-_]*(?:\s+[\w\d\.\-_:]+\=\"[^"\n]*\")*\s*[\/]?>)|(<\/lp:[\w_][\w\d\.\-_]*>)|(\&lp:[\w\d#][\w\d]*;)|(<!-- .*? -->)|([<>&])/

   @@initialTagSearchPattern        = 
       /\A((<[\w_:][\w\d\.\-_:]*(?:\s+[\w\d\.\-_:]+\=\"[^"\n]*\")*\s*[\/]?>)|(<\/[\w_:][\w\d\.\-_:]*>))/

   @@openTagStartingLine =
       /\A<([\w_:][\w\d\.\-_:]*)(?:\s+[\w\d\.\-_:]+\=\"[^"\n]*\")*\s*>/

   @@closeTag =
       /\A<\/([\w_:][\w\d\.\-_:]*)>/

       
   @@xmlDocumentTags = Hash.new()

   @@ampPattern  = /\&/
   @@gtPattern   = />/
   @@ltPattern   = /</
   @@quotPattern = /"/

   @@ampEntity   = "&amp;"
   @@gtEntity    = "&gt;"
   @@ltEntity    = "&lt;"
   @@quotEntity  = "&quot;"

   def makeOpenTag( name, parameters )
      tag = '<' + name

      parameters.keys.each do |name|
         value = parameters[name].to_s().clone()

         value.gsub!( @@ampPattern,  @@ampEntity  )
         value.gsub!( @@gtPattern,   @@gtEntity   )
         value.gsub!( @@ltPattern,   @@ltEntity   )
         value.gsub!( @@quotPattern, @@quotEntity )

         tag += ' ' + name + '="' + value + '"'
      end unless parameters.nil?
 
      return tag + '>'
   end

   def makeCloseTag( name )
      tag = '</'

      nameBefore = name.index(' ')
      if nameBefore then
         tag += name.slice(0, nameBefore )
      else
         tag += name
      end

      return tag + '>'
   end
      

   #
   # This isn't exactly thread safe, and I'm really hoping there 
   # is a better way to initialized class data, but for now, this
   # will have to do.  It's called from initialize()

   @@classinit = false
   def DocumentorXML.initTags()
      if not @@classinit then
         @@classinit = true
         @@xmlDocumentTags["document"     ] = 'lp:doc xmlns:lp="http://tapestry-os.org/tools/lp/doc"'
         @@xmlDocumentTags["block"        ] = 'lp:block'
         @@xmlDocumentTags["identifier"   ] = 'lp:identifier'
         @@xmlDocumentTags["reference"    ] = 'lp:ref'
         @@xmlDocumentTags["paragraph"    ] = 'lp:p'
      end
   end


end  # DocumentorXML
end  # LP
end  # Tapestry



#
# Test the class.

if $0 == __FILE__
   doc = Tapestry::LP::DocumentorXML.new( "styling.xsl" )
   domain = Tapestry::LP::LPDomain.new()

   if ARGV.empty? then
      puts( "No files loaded." )
   else
      puts( "Loading #{ARGV[0]}:" )
      domain.load( ARGV[0] ) 
      puts( "Documenting #{ARGV[0]}:" )
      puts( "-" * 80 )
   
      doc.document( domain.files[ARGV[0]], STDOUT ) 
   end
end


