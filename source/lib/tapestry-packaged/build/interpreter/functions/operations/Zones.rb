#!/usr/bin/ruby
#
# Functor for defining zones.
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

ARITY_def_zone = 2..3
USAGE_def_zone = <<END_USAGE.split("\n")
(def-zone
   <literal-expression:zone-directory>
   <literal-expression:target-directory>
   [<literal-expression:buildfile>]
)

Informs the system of another zone it should load.  

If zone-directory is relative, it is resolved relative to 
this zone's home.  If target-directory is relative, it is
resolved relative to this zone's target directory.

If buildfile is not supplied, it defaults to Buildfile.
If the buildfile path is relative, it is resolved relative
to the new zone's home directory.

Control passes to the new zone's buildfile immediately, and
this zone does not regain control until it is finished.

Note that each Zone is independent with respect to code 
and system objects.  Only the build graph is shared.
END_USAGE



      
class Zones < Tapestry::Build::Interpreter::Function 

   @@instance = Zones.new()
   def Zones.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      zone = interpreter.zone

      homeDir   = processToScalar( callDescriptor, 1, localScope, interpreter )
      targetDir = processToScalar( callDescriptor, 2, localScope, interpreter )

      homeDir   = Dir.normalize_path( zone.offsetHome(homeDir) )
      targetDir = Dir.normalize_path( zone.offsetTargets(targetDir) )

      buildfile = "Buildfile"
      if arity == 3 then
         buildfile = processToScalar( callDescriptor, 3, localScope, interpreter )
      end

      result = false
      currentDir = Dir.pwd()
      unless Zone.find( homeDir + "." )
         Zone.new( buildfile, homeDir, targetDir, zone )
         result = true
      end
      Dir.chdir(currentDir)

      return interpreter.scalarize( result )

   end

end  # Zones

Function.addBuiltin( "def-zone", Zones.getInstance(), ARITY_def_zone, USAGE_def_zone )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





