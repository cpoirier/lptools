#!/usr/bin/ruby
#
# Functor for defining build analyzers.
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

ARITY_def_analyzer = 3..3
USAGE_def_analyzer = <<END_USAGE.split("\n")
                         ANALYZERS

   The build system applies actions to convert source files
into target outputs.  When a target is to be built, the 
system searches back along the build graph from the target
to find the raw sources.  It then works forward toward the
target, determining which actions (see def-action) need to 
be performed to produce final target.

   At each step along the build path, before any decisions
are made about the freshness of the target, applicable 
analyzers are run on the source (if they haven't been 
already) to determine files it references.  These references
are then included in the decision making process about the 
freshness of the step's target, and may also expand the 
scope of the build (if the references are themselves built 
from sources).

   An example of a such a reference is a header file 
included in a c source file.  When checking the freshness
of the object file produced from the c source file, an 
updated header file can make the object stale, even if the
primary dependency, the c source file, doesn't.

   As usual, each zone is independent and has its own set of
analyzers, held unique on name (if your Buildfile defines 
two analyzers with the same name, only the first is kept).
For any particular file, the system will run any particular
analyzer at most once.  For files within a particular zone,
therefore, it is trivial to determine which analyzers will
be run.  However, for files that do not exist within a zone,
the situation is a little more complicated: the system will 
run the analyzers applicable to the zone in which the 
reference was identified.  If a second zone independently 
identifies the same "external" file, its applicable analyzers
will be run, subject to the unique name rule discussed above.
The result is that these external files might end up with 
more and different references than your zone was expecting.  
If this is a problem, supply zones for those extra 
directories, and make the behaviour explicit.

   As noted in (def-production), the build system handles 
relocating output to a target directory, if requested.  
For raw sources and other unbuildable files, analyzers are 
run in the source directory.  For targets and intermediaries,
analyzers are run in the target directory.


------------------------------------------------------------
(def-analyzer 
   <literal-expression:name>
   <wildcard:source> 
   <function-call:target-code>   
)

With this form, source is used as a wildcard expression, and
the analyzer's target-code will be run for any matching 
source file.  If the source wildcard contains a directory 
delimiter, it will be resolved relative the zone home, and
compared against the absolute logical path to the source 
file.

Remember that all matching analyzers are run, so be
careful when making very general analyers rules.


Available variables during
  $source-logical  = absolute logical path to source
  $source          = path to source, relative if possible
  $source-file     = bare filename of source

Examples
   header scan of a c source file using "headerscan" program
      (def-analyzer c-header-scan *.c
                          (pipe-in (q(headerscan $source))))

   header scan of h source files using "headerscan"
      (def-analyzer c-header-scan *.h
                          (pipe-in (q(headerscan $source))))


------------------------------------------------------------
(def-analyzer
   <literal-expression:name>
   <function-call:applies-code>
   <function-call:target-code>
)

The previous (def-analyzer) form relies on the build engine 
to determine which rules match each file in the work queue.
This form allows you to supply your own code to be evaluated
directly.  If applies-code returns true, the analyzer will
be run.  

As mentioned above, analyzers are run after the build system
begins sending output to the target directory.  For raw
sources and unbuildable intermediate files, applicable 
analyzers will be run in the zone home directory.  For 
targets and intermediaries, applicable analyzers will be run
in the zone target directory.  

In order to allow you to ignore target directories in your
calculations and wildcards, $source-logical contains the
absolute logical path to the file your will be/are analyzing,
while $source will contain the actual path to the file, 
relative to the current directory, if possible, or an 
absolute path otherwise.


Available variables
  $source-logical  = absolute logical path to the source 
  $source          = path to source, relative if possible
  $source-file     = bare filename of source

Examples
   header scan of particular c files using "headerscan"
      (def-analyzer special-analyzer 
         (and      (wildcard $source-logical    ../*.c)
              (not (wildcard $source-logical *example*))
         )
         (pipe-in headerscan $source)
      )


END_USAGE




      
class Analyzers < Tapestry::Build::Interpreter::Function 

   @@instance = Analyzers.new()
   def Analyzers.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""

      name   = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      target = processParameter( callDescriptor, 3, "any"               , localScope, interpreter )

      dynamicSource = false
      source = processParameter( callDescriptor, 2, "literal", localScope, interpreter, true )
      unless source 
         dynamicSource = true
         source = processParameter( callDescriptor, 2, "function-call", localScope, interpreter )
      end


      #
      # Add the new production rule to the zone.

      zone = interpreter.zone
      zone.registerAnalyzer( name, dynamicSource, source, target )

      return results

   end


end  # Analyzers

Function.addBuiltin( "def-analyzer", Analyzers.getInstance(), ARITY_def_analyzer, USAGE_def_analyzer )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





