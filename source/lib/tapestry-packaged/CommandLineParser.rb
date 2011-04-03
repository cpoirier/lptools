#!/usr/bin/ruby
#
# A Ruby class to encapsulate command line parsing.  It's simple
# stupid, and I can't understand why there isn't one in the 
# standard libary...
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
class CommandLineParser

   #
   # A hash of flags, split on any embedded "=", without the -- or -

   attr_reader :flags
   attr_reader :files


   # 
   # Parses a command line flag, saving the data in @flags.

   def parseFlag( arg )
      flagdata = arg.split("=", 2)
      if flagdata.length == 1 then
         @flags[flagdata[0]] = ""
      else
         @flags[flagdata[0]] = flagdata[1]
      end 
   end


   #
   # Processes the command line, filling in the flags and files
   # members.  You are left to verify the flags and such.

   def initialize( flagDefault=nil, args=ARGV )
      @files = Array::new()
      @flags = Hash::new( flagDefault )

      doneFlags = false 
      args.each do |arg|
         if !doneFlags then
            if arg == "--" then
               doneFlags = true
            elsif arg.slice(0,2) == "--" then
               parseFlag( arg.slice(2, arg.length-2) )
            elsif arg.slice(0,1) == "-" then
               parseFlag( arg.slice(1, arg.length-1) )
            else
               doneFlags = true
               @files << arg
            end
         else
            @files << arg
         end 
      end
   end


end  # class CommandLineParser
end  # class Tapestry



#
# Test the class.

if $0 == __FILE__
   parsed = Tapestry::CommandLineParser.new( )

   if parsed.flags.empty? then
      puts( "No flags." )
   else
      puts( "Flags:" )
      parsed.flags.keys.each do |key|
         puts( "   " + key + " = " + parsed.flags[key] )
      end
   end

   puts( "" )
   if parsed.files.empty? then
      puts( "No files." )
   else
      puts( "Files:" )
      parsed.files.each do |file|
         puts( "   " + file )
      end
   end

end
