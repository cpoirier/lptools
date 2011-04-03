#!/usr/bin/ruby
#
# Functor for defining build productions.
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

ARITY_def_production = 4..6
USAGE_def_production = <<END_USAGE.split("\n")
                        PRODUCTIONS

   The build system applies actions to convert source files
into target outputs.  Productions tell the build system
what targets are to be produced from each source, and which
action will be used to do it.

   Productions are calculated during the initial run of the
zone's Buildfile, in response to source definitions (see
def-source, def-sources).  Each defined source is added to 
a queue of work for the production engine.  The production 
engine processes the queue in FIFO order, applying 
production rules to each file.  Identified relationships are
added to the build graph.  New targets are added to the 
queue for further processing.  Control returns to the 
Buildfile only when the queue is empty.

   Each production rule has a name and a priority.  At most
one rule of a given name will be applied to each file.  The
production engine looks for a matching rule in each series,
searching from highest priority to lowest.  The first
matching rule is run.  Note that, if there are several rules
in a given series with the same priority, they are searched
in the reverse of the order in which they were defined.
Series are run in no particular order, unless you specify 
one with (set-production-ordering).

   Each production rule associates the resulting production
with an action (see def-action), which actually builds the
target from its source(s).  If no action name is specified,
the action name will be the same as the production name.  
Note that productions determine only one-to-one source-to-
target relationships.  Actions, however, can be configured
to produce a single target from several sources.  Note also 
that, for any given source-target pair, only the first 
identified action is used.

   The target produced by a production rule is stripped of 
its path information and added instead to the zone's 
directory.  Later, when the target is actually to be built, 
the build system adjusts the target's path to respect the 
zone's actual target directory.

   Finally, each production rule can include a piece of 
supplemental code, which is called for each source-target
pair added as a result of the rule.  This supplemental code
can, for instance, be used to add components and/or set 
attributes on the production source or target.


------------------------------------------------------------
(def-production 
   <literal:name>
   <integer:priority>
   <wildcard:source-pattern>   
   <wildcard:target-pattern> 
   [any:supplement]
   [literal-expression:action]
) 

This form is used for simple productions.  Both source and 
target are described by a wildcard expression, and the 
production engine will produce one target name for each
matching source name by comparing the absolute source 
path to source-pattern and, if it matches, splicing the 
matched data into the target expression (see 
wildcard-splice).  The target will then be stripped of any
path information and placed in the zone directory.

Note that, if you include a relative directory in your 
source pattern, it will be interpreted relative to the zone
home.  If you include a directory in your target pattern,
it will be removed before the target is added to the build 
graph.


Available variables during supplement
  $source      = absolute path to source
  $source-file = bare filename of source
  $target      = absolute logical path to target
  $target-file = bare filename of target

Examples
   simple c compilation using action "cc":
      (def-production cc 0 *.c *.o)

   simple lp documentation using action "lpdoc":
      (def-production lpdoc 0 *.lp *.lp.xml)

   target rename for an imported file
      (def-production cc 10 ../*.c outer-*.o)


------------------------------------------------------------
(def-production 
   <literal:name>
   <integer:priority>
   <wildcard:source> 
   <function-call:target-code>   
   [any:supplement]
   [literal-expression:action]
)

This form is used for more complicated productions.  The
source expression can be filename or a wildcard expression,
and target-code will be evaluated for each matching source.  

Note that, if you include a relative directory in your 
source pattern, it will be interpreted relative to the zone
home.  If you include a directory in your target pattern,
it will be removed before the target is added to the build 
graph.


Available variables during production
  $source      = absolute path to source
  $source-file = bare filename of source

Available variables during supplement
  $source      = absolute path to source
  $source-file = bare filename of source
  $target      = absolute logical path to target
  $target-file = bare filename of target

Examples
   hardcoded lp roots:
      (def-production lpcc 100 source.lp (q(a.c b.c c.h)))

   calculated lp roots:
      (def-production lpcc 0 *.lp 
                         (pipe-in (q(lproots $sourcefile))))


------------------------------------------------------------
(def-production 
   <literal:name>
   <integer:priority>
   <function-call:applies-code>
   <function-call:target-code>   
   [any:supplement]
   [literal-expression:action]
)

The previous (def-production) forms rely on the production
engine to determine which rules match each file in the work
queue.  This form allows you to supply your own code to be
evaluated directly during the evaluation.  If applies-code
returns true, the production will be run.

As above, target-code is evaluated for each source.  Any
directory included in the resulting target will be removed.


Available variables during production
  $source      = absolute path to source
  $source-file = bare filename of source

Available variables during supplement
  $source      = absolute path to source
  $source-file = bare filename of source
  $target      = absolute logical path to target
  $target-file = bare filename of target

Example
   compiles c sources (except examples) using action "cc":
      (def-production cc 10 
         (and (wildcard $sourcefile *.c) 
              (not (wildcard $sourcefile *example*)
         )
         (wildcard $sourcefile *.c ${1}.o)
      )
END_USAGE

ARITY_set_production_ordering = 1..1
USAGE_set_production_ordering = <<END_USAGE.split("\n")
(set-production-ordering <vector:names>)

Sets the ordering in which productions should be run.  Any
productions not named will be run in random order after.
END_USAGE



      
class Productions < Tapestry::Build::Interpreter::Function 

   @@instance = Productions.new()
   def Productions.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""

      case function
       when "def-production"

         name     = processParameter( callDescriptor, 1, "literal", localScope, interpreter )
         priority = processToInteger( callDescriptor, 2, localScope, interpreter )
   
         action = name
         if arity >= 6 then
            action = processParameter( callDescriptor, 6, "literal-expression", localScope, interpreter )
         end
   
         supplement = nil
         if arity >= 5 then
            supplement = processParameter( callDescriptor, 5, "any", localScope, interpreter )
         end
   
   
         dynamicTarget = true
         target = processParameter( callDescriptor, 4, "any", localScope, interpreter )
   
   
         #
         # Three forms are supported:
         #    wildcard source + wildcard target
         #    wildcard source + dynamic target
         #    dynamic source + dynamic target
   
         dynamicSource = false
         source = processParameter( callDescriptor, 3, "literal", localScope, interpreter, true )
         if source then
   
            #
            # If the target is a literal, it is treated as a static target.  The static
            # target can be plain text, or a wildcard with <= the same number of 
            # wildcards as the source.  A function call target is dynamic.
   
            if interpreter.isLiteral(target) then
               dynamicTarget = false
               error = nil
   
               targetWildcards = Wildcard.count(target)
               sourceWildcards = Wildcard.count(source)
   
               if targetWildcards > sourceWildcards then
                  error = "target wildcard must have <= the number of wildcards in the source"
                  raise createParameterError( function, 4, error, getUsage(function), callDescriptor[4] )
               end
      
            end
   
   
         else
            dynamicSource = true
            source = processParameter( callDescriptor, 3, "function-call", localScope, interpreter )
         end
   
   
         #
         # Add the new production rule to the zone.
   
         zone = interpreter.zone
         zone.registerProduction( name, priority, dynamicSource, source, dynamicTarget, target, action, supplement )



       when "set-production-ordering"
         ordering = processToVector( callDescriptor, 1, localScope, interpreter )
         interpreter.zone.producer.setOrdering( ordering )
         results = ""

      end
   
      return results
   
   end


end  # Productions

Function.addBuiltin( "def-production"         , Productions.getInstance(), ARITY_def_production         , USAGE_def_production          )
Function.addBuiltin( "set-production-ordering", Productions.getInstance(), ARITY_set_production_ordering, USAGE_set_production_ordering )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





