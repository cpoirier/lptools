#!/usr/bin/ruby
#
# Used by the command line interface to display Tapestry::Errors.
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
require 'tapestry-packaged/Error.rb'


#
# Used to display caught Tapestry::Errors.

def report( error, debugging = false )

   error.set( "", "" )
   error.keyorder  = ["error class", "details"] + error.keyorder + ["", "start-at-file", "start-at-line", "at-file", "at-line"]
   error.keyignore = [ "token", "start-token" ]

   token = error.get("token")
   unless token.nil?
      begin
         error.set( "at-file", token.file     )
         error.set( "at-line", token.line     )
         error.set( "in-text", token          )
      rescue NameError
      end
   end

   token = error.get("start-token")
   unless token.nil?
      begin
         error.set( "start-at-file"    , token.file     )
         error.set( "start-at-line"    , token.line     )
      rescue NameError
      end
   end

   STDERR.puts( error.message )

   if debugging then
      STDERR.puts(                 )
      STDERR.puts(                 )
      STDERR.puts( error.backtrace )
   end

end



