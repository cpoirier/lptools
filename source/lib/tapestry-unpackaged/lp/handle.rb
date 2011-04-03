#!/usr/bin/ruby
#
# Handles exceptions on behalf of the command line interface.  Returns the
# suggested rc.  You should handle LoadError yourself, for obvious reasons.
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

require 'tapestry-unpackaged/lp/report.rb'
require 'tapestry-unpackaged/lp/Output.rb'


def handle( error, flags )

   if error.kind_of?(SystemExit) then
      raise

   elsif error.kind_of?(Tapestry::Error) then
      Output.skip(2, STDERR)
      Output.puts( "an error occurred during processing:", 0, STDERR )
      Output.skip(1, STDERR)
      report( error, flags.member?("debug") )
   
      return error.rc
   
   
   elsif error.kind_of?(Interrupt) then
      STDERR.puts()
      STDERR.puts()
      STDERR.puts( ">>> ...#{File.basename($0)} cancelled." )
   
      return 1
   
   else
      STDERR.puts()
      STDERR.puts()
      STDERR.puts( ">>> caught a bug!" )
      STDERR.puts()
      STDERR.puts( error.class.name )
      STDERR.puts( error.message )
      STDERR.puts()
      STDERR.puts()
      STDERR.puts( error.backtrace[0..14] )
      STDERR.puts()
      STDERR.puts( ">>> backtrace skipping #{error.backtrace.length-15} entries" ) if error.backtrace.length > 15
   
      return 2
   end

end



if $0 == __FILE__ then
   puts "loaded"
end
   
