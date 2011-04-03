#!/usr/bin/ruby
#
# Functors that return constants:
#    (newline)
#    (space)
#    (tab)
#    (nil)
#    (empty)
#    (true)
#    (false)
#
# See USAGE below for details
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

ARITY_newline = 0..0
USAGE_newline = [ "(newline)", "", "Returns the newline character(s)." ]

ARITY_space = 0..0
USAGE_space =   [ "(space)"  , "", "Returns the space character."      ]

ARITY_tab = 0..0
USAGE_tab =     [ "(tab)"    , "", "Returns the tab character."        ]

ARITY_nil = 0..0
USAGE_nil =     [ "(nil)"    , "", "Returns the empty string."         ]

ARITY_empty = 0..0
USAGE_empty =   [ "(empty)"  , "", "Returns the empty vector."         ]

ARITY_true = 0..0
USAGE_true =    [ "(true)"   , "", "Returns true."                     ]

ARITY_false = 0..0
USAGE_false =   [ "(false)"  , "", "Returns false."                    ]




class Constants < Tapestry::Build::Interpreter::Function 

   @@instance = Constants.new()

   def Constants.getInstance()
      return @@instance
   end

   @@constants = { "newline" => "\n"  , "space"   => " "     \
                 , "tab"     => "\t"  , "nil"     => ""      \
                 , "true"    => "true", "false"   => "false" \
                 , "empty"   => []                           }
   @@constants.default = ""

   def dispatch( callDescriptor, localScope, interpreter, function, arity )
      return @@constants[function]
   end

end  # Constants

Function.addBuiltin( "newline", Constants.getInstance(), ARITY_newline, USAGE_newline )
Function.addBuiltin( "space"  , Constants.getInstance(), ARITY_space  , USAGE_space   )
Function.addBuiltin( "tab"    , Constants.getInstance(), ARITY_tab    , USAGE_tab     )
Function.addBuiltin( "nil"    , Constants.getInstance(), ARITY_nil    , USAGE_nil     )
Function.addBuiltin( "empty"  , Constants.getInstance(), ARITY_empty  , USAGE_empty   )
Function.addBuiltin( "true"   , Constants.getInstance(), ARITY_true   , USAGE_true    )
Function.addBuiltin( "false"  , Constants.getInstance(), ARITY_false  , USAGE_false   )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





