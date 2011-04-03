#!/usr/bin/ruby
#
# Output provides I/O routines and services for the lp system.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002, 2003.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-unpackaged/language-extensions.rb'


class Output

   @@verbosity = 1        # Controls how much output the system generates.  0 is none, 1 is default, 2 is lots
   @@marker    = ">>> "   # Prepended to system output.


   def Output.verbosity()
      return @@verbosity
   end

   def Output.verbosity=( verbosity )
      @@verbosity = 0 + verbosity
   end

   def Output.marker()
      return @@marker
   end

   def Output.skip( count = 1, stream = STDOUT )
      1.upto(count) do 
         stream.puts()
      end
   end

   def Output.puts( message, indent = 0, stream = STDOUT )
      stream.puts( @@marker + (" " * indent) + message )
   end


end  # Output

