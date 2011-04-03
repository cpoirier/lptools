#!/usr/bin/ruby
#
# A very basic wrapper around a String that behaves like a stream, in that
# it remembers how many characters have been read by each_byte().
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

require 'tapestry-unpackaged/language-extensions.rb'

module Tapestry

#
# String.each_byte() always starts from byte 0.  File.each_byte()
# actually consumes bytes each loop, allowing you to nest each_byte()
# calls and have intuitive results.  This class wraps a String to 
# provide the same facility.

class SimpleStringStream
   @string   = nil
   @position = 0

   def initialize( string )
      @string   = string
      @position = 0
   end

   def reset()
      @position = 0
   end

   def each_byte()
      while @position < @string.length do
         code = @string[@position]
         @position += 1

         break if yield(code).nil?
      end
   end
end

end # Tapestry



#
# Test the code, if invoked directly.

if $0 == __FILE__

   sss = Tapestry::SimpleStringStream.new( "hello" )

   def recurse( stream )
      stream.each_byte() do |code|
         puts( chr(code) )
         recurse( stream )
      end
   end

   recurse( sss )

end


