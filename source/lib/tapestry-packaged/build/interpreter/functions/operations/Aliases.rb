#!/usr/bin/ruby
#
# Functor for defining target aliases.
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

ARITY_def_alias = 2..2
USAGE_def_alias = <<END_USAGE.split("\n")
(def-alias <literal-expression:name> <any-expression:targets>)

Defines an alias, by which one or more actual targets can be
referred.
END_USAGE


ARITY_get_alias = 1..1
USAGE_get_alias = <<END_USAGE.split("\n")
(get-alias <literal-expression:name>)

Returns the value of an alias as a vector.  If the alias 
does not exist, (empty) is returned.
END_USAGE




      
class Aliases < Tapestry::Build::Interpreter::Function 

   @@instance = Aliases.new()
   def Aliases.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""
      zone    = interpreter.zone

      case function
       when "def-alias"
         results = defineAlias( zone, callDescriptor, localScope, interpreter, function, arity )

       when "get-alias"
         results = getAlias( zone, callDescriptor, localScope, interpreter, function, arity )

      end
      
      return results
   end

 private

   def defineAlias( zone, callDescriptor, localScope, interpreter, function, arity )

      name    = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      targets = processToVector( callDescriptor, 2, localScope, interpreter )

      zone.registerAlias( name, targets.flatten )

   end


   def getAlias( zone, callDescriptor, localScope, interpreter, function, arity )

      results = []

      name = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      aliasZone = Zone.find( zone.offsetHome(name), zone )

      if aliasZone.alias?(name) then
         results = aliasZone.resolveAlias(name)
      end

      return results
      
   end


end  # Aliases

Function.addBuiltin( "def-alias", Aliases.getInstance(), ARITY_def_alias, USAGE_def_alias )
Function.addBuiltin( "get-alias", Aliases.getInstance(), ARITY_get_alias, USAGE_get_alias )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





