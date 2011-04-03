#!/usr/bin/ruby
#
# Functor for:
#    (wildcard <scalar-expression:text> 
#              <scalar-expression:pattern> 
#              [<scalar-expression:substitution>])
#
#    (wildcard-splice <scalar-expression:text> 
#                     <scalar-expression:source-pattern> 
#                     <scalar-expression:target-pattern>)
#
#    (wildcard-glob <scalar-expression:file-pattern>)
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



ARITY_wildcard = 2..3
USAGE_wildcard = <<END_USAGE.split("\n")
(wildcard <scalar-expression:text> <scalar-expression:pattern>)

Compiles pattern as a wildcard expression: **/ matches any 
number of directories, * matches any series of characters 
(except /) and ? matches any one character (except /).
Returns true if there is a match of the pattern in the text.

If pattern contains a directory reference, both the pattern 
and the text are made absolute with respect to the zone's
home directory.

Example
   (wildcard source.c *.c)
      - returns true

   (wildcard source.c *.o)
      - returns false

   with a zone home of /home/user/src/ and a $source of
   /home/user/x.c:
      (wildcard $source ../*.c)
         - returns true

      (wildcard $source ./*.c)
         - returns false

      (wildcard $source *.c)
         - returns true


------------------------------------------------------------
(wildcard 
   <scalar-expression:text> 
   <scalar-expression:pattern> 
   <scalar-expression:substitution>
)

Compiles pattern as a wildcard expression: **/ matches any 
number of directories, * matches any series of characters 
(except /) and ? matches any one character (except /).  

If text matches pattern, substitution is evaluated and 
returned.  Any path information not matched by pattern is
retained in the result.  During substitution, $1..$n are set 
to the text corresponding to each wildcard in the pattern.

If text does not match pattern, nil is returned.

If pattern contains a directory reference, both pattern and
text are made absolute with respect to the zone's home 
directory.  The result is reduced back to a relative path,
if possible, before being returned.


Example
   (wildcard source.c *.c ${1}.o)
      - returns source.o

   (wildcard /src/source.c *.c ${1}.o)
      - returns /src/source.o

   (wildcard /src/source.c /**/*.c ${2}.o)
      - returns source.o

   with a zone home of /home/user/src/ and a $source of
   /home/user/x.c:
      (wildcard $source ../*.c target/{$1}.o)
         - returns target/x.o

      (wildcard $source ./*.c ${1}.o)
         - returns nil

      (wildcard $source *.c ${1}.o)
         - returns ../x.o

END_USAGE


ARITY_wildcard_splice = 3..3
USAGE_wildcard_splice = <<END_USAGE.split("\n")
(wildcard-splice 
   <scalar-expression:text>
   <scalar-expression:source-pattern>
   <scalar-expression:target-pattern>
)

Compiles pattern as a wildcard expression: **/ matches any 
number of directories, * matches any series of characters 
(except /) and ? matches any one character (except /).  

Then, if text matches source-pattern, target-pattern is 
returned with its wildcards replaced by the respective 
source matches.

Returns nil if the text did not match.

If source-pattern contains a directory reference, both it 
and text are made absolute with respect to the zone's home
directory.  The result is reduced back to a relative path,
if possible, before being returned.


Example
   (wildcard-splice src/test-1.c src/*-*.c target/*.o)
      - returns target/test.o

   (wildcard-splice test.c *.a *.o)
      - returns nil

   with a zone home of /home/user/src/ and a $source of
   /home/user/x.c:
      (wildcard $source ../*.c target/*.o)
         - returns target/x.o

      (wildcard $source ./*.c *.o)
         - returns nil

      (wildcard $source *.c *.o)
         - returns ../x.o


END_USAGE



ARITY_wildcard_glob = 1..1
USAGE_wildcard_glob = <<END_USAGE.split("\n")
(wildcard-glob <scalar-expression:file-pattern>)

Compiles file-pattern as a wildcard expression and applies
it against the file system, relative the current directory
as necessary.  Returns a list of matching files.

**/ matches any number of directories, * matches any series 
of characters (except /) and ? matches any one character 
(except /).  

END_USAGE



  
class Wildcards < Tapestry::Build::Interpreter::Function

   @@instance = Wildcards.new()

   def Wildcards.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      result = ""

      case function
       when "wildcard-glob"
         pattern = processParameter( callDescriptor, 1, "scalar-expression", localScope, interpreter )
         result = Dir[pattern]


       else
         text    = processParameter( callDescriptor, 1, "scalar-expression", localScope, interpreter )
         pattern = processParameter( callDescriptor, 2, "scalar-expression", localScope, interpreter )


         #
         # If the wildcard contains a file separator, then we must resolve both the
         # pattern and the text against the zone home directory, in order to produce
         # intuitive results.  Later, we'll have to un-offset any results.
   
         offset   = false
         compiled = nil
         zone     = interpreter.zone
   
         if pattern.contains?(File::Separator) then
            offset   = true
            text     = zone.offsetHome( text )
            compiled = Wildcard.compile( zone.offsetHome(pattern) )
   
         else
            compiled = Wildcard.compile( pattern )
   
         end
      
      
         case function
          when "wildcard"
            m = compiled.match( text )
      
            if arity == 2 then
               result = interpreter.scalarize( !m.nil? )
   
            else
               if m.nil?
                  result = ""
   
               else
                  fillMatchVariables( m, localScope )
                  result = m.pre_match \
                         + processParameter( callDescriptor, 3, "literal-expression", localScope, interpreter ) \
                         + m.post_match
               end
   
               result = zone.relativeHome( result ) if offset
            end
   
          when "wildcard-splice"
            target = processParameter( callDescriptor, 3, "scalar-expression", localScope, interpreter )
            result = interpreter.scalarize( compiled.splice( target, text ) )
            result = zone.relativeHome( result ) if offset
   
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

end  # Wildcards

Function.addBuiltin( "wildcard"       , Wildcards.getInstance(), ARITY_wildcard       , USAGE_wildcard        )
Function.addBuiltin( "wildcard-splice", Wildcards.getInstance(), ARITY_wildcard_splice, USAGE_wildcard_splice )
Function.addBuiltin( "wildcard-glob",   Wildcards.getInstance(), ARITY_wildcard_glob  , USAGE_wildcard_glob   )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





