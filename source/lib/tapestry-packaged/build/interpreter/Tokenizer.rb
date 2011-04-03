#!/usr/bin/ruby
#
# This tokenizer processes a simple LISP-like series of tokens in parentheses.
# The tokenizer returns an (nested) array of strings.
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


require "tapestry-unpackaged/language-extensions.rb"
require "tapestry-packaged/SimpleStringStream.rb"

module Tapestry
module Build
module Interpreter

#
# This module is added to all Strings and Arrays produced by the tokenizer.
# It provides additional features useful for linking the data back to the
# input, making it easier to produce informative error messages.

module Token

   @file     = ""
   @line     = 0
   @position = 0

   attr_reader :file, :line, :position

   def Token.associate( object, file, line, position )
      object.extend( Tapestry::Build::Interpreter::Token )
      object.associate( file, line, position )
      return object
   end

   def associate( file, line, position )
      @file     = file
      @line     = line
      @position = position
   end


end 



#
# The tokenizer.  Reads a stream of input and builds a tree of Tokens.  The 
# input stream is a set of parenthesis-enclosed tokens, similar to a LISP 
# program.  The entire program is treated as in enclosed by a set of 
# parentheses.  Syntax errors will be reported with a line number where the 
# error is discovered.

class Tokenizer 

   NL         = asc("\n")   # 0x0A
   TAB        = asc("\t")   # 0x0B
   CR         = asc("\r")   # 0x0D
   SP         = asc(" ")    # 0x20
   OPENPAREN  = asc("(")    # 0x28
   CLOSEPAREN = asc(")")    # 0x29
   QUOTE      = asc("\"")   # 0x22
   BACKSLASH  = asc("\\")   # 0x5C
   WHITESPACE = [ NL, TAB, CR, SP ]
   PARENS     = [ OPENPAREN, CLOSEPAREN ]

   @line     = 0 
   @position = 0

   def initialize()
   end


   # 
   # Process a series of lines and returns a Token that represents
   # it.  [[stream]] must support [[each_byte()]]. 

   def process( stream, file = nil, top = true )

      #
      # String.each_byte() does not consume input, making recursion impossible.
      # SimpleStringStream wraps a string to provide a consuming each_byte().

      if stream.is_a?(String) then
         stream = Tapestry::SimpleStringStream.new(stream)
      end


      #
      # We keep track of the lines ourselves.

      if top then 
         @line     = 1
         @position = 0
      end



      tokens   = createListToken( file, @line, @position )
      current  = ""
      instring = false
      inquote  = false
      inescape = false
      inset    = true

      tokenStart = 0

      stream.each_byte() do |code|
         @position += 1

         if instring then
            if WHITESPACE.member?( code ) or PARENS.member?(code) then
               tokens.append( createStringToken(current, file, @line, tokenStart) )
               current = ""
               instring = false

            else
               current << chr(code)

            end

            # On completion of string, fall through to process terminator
         end

         if inquote then
            if not inescape and code == QUOTE then
               tokens.append( createStringToken(current, file, @line, tokenStart) )
               current = ""
               inquote = false

            elsif not inescape and code == BACKSLASH then
               inescape = true

            else
               current << chr(code)
               inescape = false

            end

            # On completion of quote, we eat the terminator and don't fall through

         elsif not instring then
            if code == NL then
               @line     += 1
               @position  = 0

            elsif code == CLOSEPAREN then
               inset = false
               break

            elsif code == OPENPAREN then
               tokens.append( process(stream, file, false) )

            elsif WHITESPACE.member?(code) then
               # do nothing

            elsif code == QUOTE then
               inquote = true
               tokenStart = @position

            else
               instring = true
               tokenStart = @position
               current << chr(code)

            end
         end

         true
      end

      if top then
         stream.each_byte() do |code|
            if not WHITESPACE.member?( code ) then
               raise Tapestry::Error( "syntax error", \
                  { "details" => "unexpected input after apparent end of program" \
                  , "line"    => @line                                            } )

            elsif code == NL then
               @line += 1
               @position = 0
            end
         end
      else
         if inset then
            raise Tapestry::Error( "syntax error", \
               { "details" => "expected closing parenthesis" \
               , "line"    => @line                          } )
         end
      end

      return tokens
   end


   #
   # Creates tokens for use in the tokenizer

   def createListToken( file, line, position )
      return Token.associate( [], file, line, position )
   end

   def createStringToken( string, file, line, position )
      return Token.associate( string, file, line, position )
   end


end  # Tokenizer
end  # Interpreter
end  # Build
end  # Tapestry






#
# Test the Tokenizer, if invoked directly.

if $0 == __FILE__

   tokenizer = Tapestry::Build::Interpreter::Tokenizer.new()

   if ARGV.empty? then
      string ='(test a b (c d e (f g "h(i)\"j")))' 
      puts( "parsing: " + string )
      token = tokenizer.process( string )
      puts( "result: " + token.to_s() )
   else
      ARGV.each do |testfilename|
         File.open(testfilename) do |testfile|
            token = tokenizer.process( testfile )
            puts( token )
         end
      end
   end

end


