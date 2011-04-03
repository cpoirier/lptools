#!/usr/bin/ruby
#
# Functor for:
#    (regex    <scalar-expression:text> <scalar-expression:pattern> [<scalar-expression:substitution>])
#
# See USAGE below for details.
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


module Tapestry
module Build
module Interpreter
module Functions

ARITY_regex = 2..3
USAGE_regex = <<END_USAGE.split("\n")
(regex <scalar-expression:text> <scalar-expression:pattern>)

Compiles pattern as a Ruby regular expression and returns 
true if there is a match of the pattern in the text.


------------------------------------------------------------
(regex 
   <scalar-expression:text> 
   <scalar-expression:pattern> 
   <scalar-expression:substitution>
)

Compiles pattern as a regular expression and searches text.
For each match, the substitution clause is evaluated to 
produce replacement text.  For the substitution clause, $0
holds the currently matched text, and $1..$n are set to the
appropriate match group text.  

Returns the new value, with all substitutions made.

Example
   (regex "hello there" "[aeiou]" ${0}+${0})
      - returns "he+ello+o the+ere+e"

   (set $list (l (nil) X Y Z))
   (regex a1b2c3 "([a-zA-Z])([0-9])" 
      (do
         (set $replacement (at $list $2))
         (return ${1}${replacement}${1})
      )
   )
      - returns aXabYbcZc
END_USAGE



  
class PatternMatching < Tapestry::Build::Interpreter::Function

   @@instance = PatternMatching.new()

   def PatternMatching.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      result = ""

      text    = processParameter( callDescriptor, 1, "scalar-expression", localScope, interpreter )
      pattern = processParameter( callDescriptor, 2, "scalar-expression", localScope, interpreter )

      compiled = Regexp.compile(pattern)


      #
      # Process the regular expression

      if arity == 2 then
         result = interpreter.scalarize( (text =~ compiled ? true : false ) )

      else

         #
         # Evaluate the third parameter for each pattern match in the text

         result = text.gsub(compiled) do |match|
            m = $~
            fillMatchVariables( m, localScope )
            processParameter( callDescriptor, 3, "literal-expression", localScope, interpreter )
         end

      end

      return result

   end


   #
   # Loads a variable scope with the match variables

   def fillMatchVariables( matchData, localScope )
      (0..matchData.length).each do |index|
         localScope.set( index.to_s, matchData[index].to_s, false )
      end
   end

end  # PatternMatching

Function.addBuiltin( "regex"          , PatternMatching.getInstance(), ARITY_regex          , USAGE_regex           )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





