#!/usr/bin/ruby
#
# Functor for:
#    (target?       <literal-expression:node-path>)
#    (targets-by    <literal-expression:node-path> <literal-expression:action>)
#    (targets-of    <literal-expression:node-path>)
#    (sources-of    <literal-expression:node-path>)
#    (components-of <literal-expression:node-path>)
#    (add-component <literal-expression:node-path> <literal-expression:component-path>)
#    (attribute?    <literal-expression:node-path> <literal-expression:name>)
#    (set-attribute <literal-expression:node-path> <literal-expression:name> <any-expression:value>)
#    (get-attribute <literal-expression:node-path> <literal-expression:name>)
#    (build-target  <literal-expression:node-path>)
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


ARITY_target_ = 1..1
USAGE_target_ = <<END_USAGE.split("\n")
(target? <literal-expression:node-path>)

Returns true if the specified path is a build target.  

Relative paths are resolved relative the zone home.

Example
   (target? source.o)
END_USAGE





ARITY_targets_by = 2..2
USAGE_targets_by = <<END_USAGE.split("\n")
(targets-by 
   <literal-expression:node-path> 
   <literal-expression:action>
)

Returns a vector containing those targets of the specified
node that are built with the specified action.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_targets_of = 1..1
USAGE_targets_of = <<END_USAGE.split("\n")
(targets-of <literal-expression:node-path>)

Returns a vector containing all the targets of the specified
node.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_sources_of = 1..1
USAGE_sources_of = <<END_USAGE.split("\n")
(sources-of <literal-expression:node-path>)

Returns a vector containing all the sources of the specified
node.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_components_of = 1..1
USAGE_components_of = <<END_USAGE.split("\n")
(components-of <literal-expression:node-path>)

Returns a vector containing all the components of the 
specified node.  Note that a node's sources are a subset
of its components.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_add_component = 2..2
USAGE_add_component = <<END_USAGE.split("\n")
(add-component 
   <literal-expression:node-path> 
   <literal-expression:component-path>
)

Adds a component to the specified node.  This function is 
not valid once building has begun.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_attribute_ = 2..2
USAGE_attribute_ = <<END_USAGE.split("\n")
(attribute?    
   <literal-expression:node-path> 
   <literal-expression:name>
)

Returns true if the specified node has the named attribute.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_set_attribute = 3..3
USAGE_set_attribute = <<END_USAGE.split("\n")
(set-attribute 
   <literal-expression:node-path> 
   <literal-expression:name> 
   <any-expression:value>
)

Sets an attribute on the specified node.

Relative paths are resolved relative the zone home.
END_USAGE




ARITY_get_attribute = 2..2
USAGE_get_attribute = <<END_USAGE.split("\n")
(get-attribute 
   <literal-expression:node-path> 
   <literal-expression:name>
)

Gets an attribute from the specified node.

Relative paths are resolved relative the zone home.
END_USAGE



ARITY_build_target = 1..1
USAGE_build_target = <<END_USAGE.split("\n")
(build-target <literal-expression:node-path>)

WARNING: This function is not for casual use.  

In normal operations, all defined zones are loaded and
fully processed (including all productions calculated) 
before any targets are built.  This is how the system
is designed to operate.

However, in some cases, it may be desirable to use a target
before the build process starts (for instance, if a built
target is the source of production information).  This 
function enables this behaviour, by allowing you to instruct
the build engine to bring a particular target up to date
immediately.

Unfortunately, use of this function has its problems.  The
build system will only build a particular target once during
a run.  Therefore, depending on the state of the build engine 
when you invoke this function, you may cause unwanted side-
effects: targets might be marked built before all their
dependencies are identified; targets might fail to build 
because all their sources have yet to be identified; etc.

Therefore, it is best to avoid this function altogether.  If
you do use it, try to avoid building targets that in any way
depend on other targets.  For really complicated situations,
it might be best to split your build process into two passes,
each with its own Buildfile, and (system build) the second
pass from the first.  Of course, this approach has its own
problems...

Also, you cannot use this function to invoke macros or 
aliases.

Finally, if you use this function in the body of a 
production, you must be aware that production series are 
normally run in random order: if you produce two targets
from a source, the system doesn't make any promises about
which target it will identify first, and you cannot use
this function on an unidentified target.  Therefore, you 
must make sure that the productions that specify the node 
you are about to build have already been run.  You can use
(set-production-ordering) for this purpose.

END_USAGE




class Nodes < Tapestry::Build::Interpreter::Function

   @@instance = Nodes.new()

   def Nodes.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      result   = ""
      zone     = interpreter.zone

      nodeName = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      nodePath = zone.offsetHome( nodeName )
      node = Graph.produce( nodePath )

      

      case function
       when "target?"
         result = interpreter.scalarize( node.target? )

       when "targets-by"
         action = processParameter( callDescriptor, 2, "literal-expression", localScope, interpreter )
         result = interpreter.vectorize( node.extended? ? node.targetsBy(action) : [] )

       when "targets-of"
         result = interpreter.vectorize( node.extended? ? node.targets()    : [] )

       when "sources-of"
         result = interpreter.vectorize( node.extended? ? node.sources()    : [] )

       when "components-of"
         result = interpreter.vectorize( node.extended? ? node.components() : [] )

       when "add-component"
         componentName = processParameter( callDescriptor, 2, "literal-expression", localScope, interpreter )
         componentPath = zone.offsetHome( componentName )
         componentNode = Graph.produce( componentPath )

         result = interpreter.scalarize( Graph.component(nil, nil, componentNode, node) )


       when "attribute?", "set-attribute", "get-attribute"
         attribute = processParameter( callDescriptor, 2, "literal-expression", localScope, interpreter )

         case function
          when "attribute?"
             result = interpreter.scalarize( node.attribute?(attribute) )

          when "get-attribute"
             result = node.getAttribute( attribute )

          when "set-attribute"
             value = processParameter( callDescriptor, 3, "any-expression", localScope, interpreter )
             node.setAttribute( attribute, value )
         end


       when "build-target"
         node.zone( zone ).builder.build( node )
         result = ""

      end

      return result

   end

end  # Nodes

Function.addBuiltin( "target?"      , Nodes.getInstance(), ARITY_target_      , USAGE_target_       )
Function.addBuiltin( "targets-by"   , Nodes.getInstance(), ARITY_targets_by   , USAGE_targets_by    )
Function.addBuiltin( "targets-of"   , Nodes.getInstance(), ARITY_targets_of   , USAGE_targets_of    )
Function.addBuiltin( "sources-of"   , Nodes.getInstance(), ARITY_sources_of   , USAGE_sources_of    )
Function.addBuiltin( "components-of", Nodes.getInstance(), ARITY_components_of, USAGE_components_of )
Function.addBuiltin( "add-component", Nodes.getInstance(), ARITY_add_component, USAGE_add_component )
Function.addBuiltin( "attribute?"   , Nodes.getInstance(), ARITY_attribute_   , USAGE_attribute_    )
Function.addBuiltin( "set-attribute", Nodes.getInstance(), ARITY_set_attribute, USAGE_set_attribute )
Function.addBuiltin( "get-attribute", Nodes.getInstance(), ARITY_get_attribute, USAGE_get_attribute )
Function.addBuiltin( "build-target" , Nodes.getInstance(), ARITY_build_target , USAGE_build_target  )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





