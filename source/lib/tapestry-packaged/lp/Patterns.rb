#!/usr/bin/ruby
#
# Common infrastructure used when manipulating lp files.
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


require 'tapestry-packaged/Error.rb'


#
# Provides tools used by the various lp components.

module Tapestry
module LP
class Patterns

 #-----------------------------------------------------------------------------
 # DIRECTIVE NAMES

   @@allDirectiveNames     = [ "", "set", "block", "markup", "no-markup", "cancel-markup", "inherit", "include", "transclude", "bookmark" ]
   @@includeDirectiveNames = [ "include", "transclude", "inherit" ]

   def Patterns.allDirectiveNames()
      return @@allDirectiveNames
   end

   def Patterns.includeDirectiveNames()
      return @@includeDirectiveNames
   end



 #-----------------------------------------------------------------------------
 # CORE REGULAR EXPRESSIONS


   #
   # Patterns patterns used for parsing lp files.

   @@directivePattern      = /\A\s*@-(.*)\Z/
   @@directiveTextPattern  = /\A(\S*)\s*(.*)\Z/
   @@referencePattern      = /\{\{(.*?)\}\}/
   @@equalsPattern         = /=/
   @@semicolonPattern      = /;/
   @@nameValuePairPattern  = /\A\s*([^\n=]+?)(?:\s*=\s*([^\n=]*?))?\s*\Z/
   @@allWhitespacePattern  = /\A\s*\Z/
   @@identifierPattern     = /\[\[(.+?)\]\]/
   @@xReferencePattern     = /\{\{\{(.*?)\}\}\}/
   @@fileExtensionPattern  = /\.lp\Z/
   @@macroPattern          = /\$\$(\w*)\$\$/

   def Patterns.directiveTextPattern()
      return @@directiveTextPattern
   end

   def Patterns.directivePattern()
      return @@directivePattern
   end

   def Patterns.equalsPattern()
      return @@equalsPattern
   end

   def Patterns.referencePattern()
      return @@referencePattern
   end

   def Patterns.xReferencePattern()
      return @@xReferencePattern
   end

   def Patterns.allWhitespacePattern()
      return @@allWhitespacePattern
   end

   def Patterns.identifierPattern()
      return @@identifierPattern
   end

   def Patterns.fileExtensionPattern()
      return @@fileExtensionPattern
   end

   def Patterns.macroPattern()
      return @@macroPattern
   end



 #-----------------------------------------------------------------------------
 # DIRECTIVE PARAMETER DEFINITIONS

   # 
   # Patterns directives parameter lists
   
   @@blockDirectiveParameters     = [ "root", "language", "name" ]
   @@referenceDirectiveParameters = [ "file", "name", "label" ]
   @@markupDirectiveParameters    = [ "file", "name", "text" ]
   @@includeDirectiveParameters   = [ "file", "name" ]
   @@inheritDirectiveParameters   = [ "file" ]
   @@noMarkupDirectiveParameters  = [ "text" ]


   def Patterns.blockDirectiveParameters()
      return @@blockDirectiveParameters
   end

   def Patterns.blockDirectiveParametersAlone()
      return 2
   end

   def Patterns.referenceDirectiveParameters()
      return @@referenceDirectiveParameters
   end

   def Patterns.referenceDirectiveParametersAlone()
      return 1
   end

   def Patterns.markupDirectiveParameters()
      return @@markupDirectiveParameters
   end

   def Patterns.markupDirectiveParametersAlone()
      return 1
   end

   def Patterns.includeDirectiveParameters()
      return @@includeDirectiveParameters
   end

   def Patterns.includeDirectiveParametersAlone()
      return 0
   end

   def Patterns.inheritDirectiveParameters()
      return @@inheritDirectiveParameters
   end

   def Patterns.inheritDirectiveParametersAlone()
      return 0
   end

   def Patterns.noMarkupDirectiveParameters()
      return @@noMarkupDirectiveParameters
   end

   def Patterns.noMarkupDirectiveParametersAlone()
      return 0
   end





 #-----------------------------------------------------------------------------
 # TESTS

   def Patterns.isWhitespace( text )
      return text =~ @@allWhitespacePattern
   end



 #-----------------------------------------------------------------------------
 # LANGUAGE SPECIFICS

   #
   # Tools for dealing with the comment marker for each language.

   @@commentMarkers = Hash.new()
   @@defaultCommentMarker = "//"

   def Patterns.getCommentMarker( language )
      result = @@defaultCommentMarker
 
      case language
       when "c", "c++" then
         result = "//"
       when "assembler", "asm" then
         result = "#"
      end

      result = @@commentMarkers[language] if @@commentMarkers.member?(language)
      return result
   end


   def Patterns.setDefaultCommentMarker( marker )
      @@defaultCommentMarker = marker
   end


   def Patterns.setCommentMarker( language, marker )
      @@commentMarkers[language] = marker
   end


   #
   # Tools for dealing with the file extension for each language.
 
   @@extensions = Hash.new()

   def Patterns.getExtension( language )
      result = ""
 
      case language
       when "c" then
         result = ".c" 
       when "c++" then
         result = ".cpp"
       when "assembler", "asm" then
         result = ".S"
      end
   end 

   def Patterns.setExtension( language, extension )
      if extension.nil? or extension.empty? then
         @@extensions[language] = ""
      elsif extension.slice(0,1) == "." then
         @@extensions[language] = extension
      else 
         @@extensions[language] = "." + extension
      end
   end



 #-----------------------------------------------------------------------------
 # LINE DIRECTIVES

   #
   # Generate a line directive with the specified info.
 
   def Patterns.makeLineDirective( linenumber, filepath )
      return "#line " + linenumber.to_s + ' "' + filepath + '"'
   end



 #-----------------------------------------------------------------------------
 # PARSING

   #
   # Given a name=value pair (=value is optional), parses the pair and inserts 
   # it into the supplied hash table.  Throws if the pattern has syntax errors 
   # (usually extra = signs).

   def Patterns.processNameValuePair( text, into, token )
      if text =~ @@nameValuePairPattern then
         into[$1] = $2.to_s
      else
         Patterns.raise_parameterError( "name=value pair syntax error", text, token )
      end
   end


   #
   # Parses a parameter list and stores the data in the supplied hash.  
   # Parameter lists are semi-colon (;) separated name=value pairs, in which 
   # the last supplied can omit the name=.  You supply the expected order of 
   # names, and the routine will enforce that order.  The routine also allows 
   # you to specify where in the list to start if no name is specified.
   #
   # See lphelp for a detailed discussion of parameter list handling.

   def Patterns.processParameters( text, token, into, names, indexForOnlyUnnamed=0 )
      if into.nil? then
         into = Hash.new()
      end

      pieces = text.split( @@semicolonPattern )

      current = -1
      unnamedUsed = false
      pieces.each do |piece|
         if unnamedUsed then
            Patterns.raise_parameterError( "unnamed data must be last item", text, token )
         end

         if piece =~ @@nameValuePairPattern then
            unless $2.nil? then
               name  = $1
               value = $2
            else
               name  = ""
               value = $1
               unnamedUsed = true
            end

            if current == -1 then
               if name == "" then
                  current = indexForOnlyUnnamed
               else
                  current = names.index(name)
                  if current.nil? then
                     Patterns.raise_parameterError( "unrecognized parameter", name, token )
                  end
               end
            end

            if current < names.length and current >= 0 and (name = "" or names[current] == name) then
               into[names[current]] = value
               current += 1
            else
               Patterns.raise_parameterError( "invalid parameter list", piece, token )
            end
         else
            Patterns.raise_parameterError( "invalid parameter list", piece, token )
         end
      end

      if not into.member?(names[indexForOnlyUnnamed]) then
         Patterns.raise_parameterError( "invalid parameter list: missing #{names[indexForOnlyUnnamed]}", token, token )
      end

      return into
   end


   def Patterns.processBlockDirective( text, token, into=nil )
      return Patterns.processParameters( text, token, into, Patterns.blockDirectiveParameters, Patterns.blockDirectiveParametersAlone )
   end


   def Patterns.processReferenceDirective( text, token, into=nil )
      reference = Patterns.processParameters( text, token, into, Patterns.referenceDirectiveParameters, Patterns.referenceDirectiveParametersAlone )
      if not reference.member?("label") then
         if reference["name"].to_s() == "" and reference["file"].to_s != "" then
            reference["label"] = reference["file"].to_s()
         else
            reference["label"] = reference["name"].to_s()
         end
      end
      return reference
   end

   def Patterns.processMarkupDirective( text, token, into=nil )
      markup = Patterns.processParameters( text, token, into, Patterns.markupDirectiveParameters, Patterns.markupDirectiveParametersAlone )
      if not markup.member?("text") then
         markup["text"] = markup["name"].to_s()
      end
      return markup
   end

   def Patterns.processNoMarkupDirective( text, token, into=nil )
      return Patterns.processParameters( text, token, into, Patterns.noMarkupDirectiveParameters, Patterns.noMarkupDirectiveParametersAlone )
   end

   def Patterns.processIncludeDirective( text, token, into=nil )
      return Patterns.processParameters( text, token, into, Patterns.includeDirectiveParameters, Patterns.includeDirectiveParametersAlone )
   end

   def Patterns.processInheritDirective( text, token, into=nil )
      return Patterns.processParameters( text, token, into, Patterns.inheritDirectiveParameters, Patterns.inheritDirectiveParametersAlone )
   end



   #
   # Attempts to process the specified line as a @- directive.  Returns
   # [directive, name, data], where directive is a boolean indicating 
   # if name and data are valid.

   def Patterns.parseNamedDirective( line )

      isDirective = false
      name = nil
      data = nil

      if line =~ Patterns.directivePattern then
         isDirective = true

         text = $1
         if text =~ Patterns.directiveTextPattern then
            name = $1.to_s
            data = $2.to_s
         end

      end

      return [ isDirective, name, data ]

   end



 #-----------------------------------------------------------------------------
 # DIRECTIVE ASSEMBLY

   def Patterns.assembleReferenceDirective( data )

      pieces = []
      @@referenceDirectiveParameters.each do |name|
         if data.member?(name) then
            pieces.append( name + "=" + data[name] )
         end
      end

      return "{{" + pieces.join("; ") + "}}"

   end

   def Patterns.assembleIncludeDirective( data, name="include" )
      return "@-#{name} file=" + data["file"]
   end

   def Patterns.assembleMarkupDirective( data )

      pieces = []
      @@markupDirectiveParameters.each do |name|
         if data.member?(name) then
            pieces.append( name + "=" + data[name] )
         end
      end

      return "@-markup " + pieces.join("; ")

   end




 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   def Patterns.raise_parameterError( details, text, token = nil, data = nil )
      error = Tapestry::Error( "parameter error", data )
      error.set( "details", details )
      error.set( "text",    text    )
      error.set( "token",   token   ) unless token.nil?
      error.keyorder = [ "text" ]
      raise error
   end


end  # Patterns
end  # LP
end  # Tapestry



