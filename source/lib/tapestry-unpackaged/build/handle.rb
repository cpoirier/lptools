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

require 'tapestry-unpackaged/build/report.rb'

def handle( error, flags )

   if error.kind_of?(SystemExit) then
      raise

   elsif error.kind_of?(Tapestry::ErrorSet) then
      errors = error

      BuildSystem.skip(2, STDERR)
      BuildSystem.puts( "errors occurred during processing:", 0, STDERR )
      BuildSystem.skip(1, STDERR)
      errors.each do |error|
         report( error, flags.member?("debug") )
      end
   
      return errors.rc
   
   
   elsif error.kind_of?(Tapestry::Error) then
      BuildSystem.skip(2, STDERR)
      BuildSystem.puts( "an error occurred during processing:", 0, STDERR )
      BuildSystem.skip(1, STDERR)
      report( error, flags.member?("debug") )
   
      return error.rc
   
   
   elsif error.kind_of?(Interrupt) then
      STDERR.puts()
      STDERR.puts()
      STDERR.puts( ">>> ...build cancelled." )
   
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

   
   
            
