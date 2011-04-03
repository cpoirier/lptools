#!/usr/bin/ruby
#
# Provides a flexible exception for communicating detailed error messages.
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

require 'tapestry-packaged/Error.rb'

module Tapestry

#
# A set of Error exceptions, for when you want to allow a certain amount of
# failure before bailing out.  

class ErrorSet < Exception

   @fatal   = false   # If set, the exception should not be buffered
   @rc      = 10      # The suggested return code for the software

   @set     = []      # An array of Errors
   @maximum = 0       # Once @set reaches this size, the Set will raise itself...

   def initialize( maximum = nil )
      @set     = []
      @maximum = maximum.to_i

      self.fatal = false
      self.rc    = 10
   end

   def fatal=( fatal )
      @fatal = (true && fatal)
   end

   def fatal?()
      return @fatal
   end

   def rc=( rc )
      @rc = (0 + rc)
   end

   def rc()
      return @rc
   end


   #
   # Adds a Error object to the Set.  Raises self if the set has 
   # reached its maximum.

   def add( error )

      type_check( error, Tapestry::Error )

      @set.append( error )
      self.fatal = true if error.fatal?
      self.rc = error.rc if error.rc > self.rc

      raise self if cause?

   end


   #
   # Merges in the data from another ErrorSet.  Raises self if the set
   # has reached its maximum.

   def merge( set )

      type_check( set, Tapestry::ErrorSet )

      if set.id != self.id then
         set.each do |error|
            @set.append( error )
            self.fatal = true if error.fatal?
            self.rc = error.rc if error.rc > self.rc
         end
      end

      raise self if cause?

   end


   #
   # Returns true if the Set is empty.

   def empty?()
      return @set.empty?
   end


   #
   # Returns true if the Set has reached its maximum.

   def full?()
      return @set.length >= @maximum
   end


   #
   # Returns true if the Set is full? or fatal?

   def cause?
      return (full? or fatal?)
   end


   #
   # Loops through each Error object.

   def each()
      @set.each do |error|
         yield( error )
      end
   end


   #
   # Constucts a single message from all the errors.

   def message()

      message = ""
      each() do |error|
         message += error.message
         message += "\n\n\n"
      end

      return message
   end

   def to_s()
      return 'Tapestry::ErrorSet exception containing ' + @set.size.to_s + ' Tapestry:Error exceptions'
   end

end  # ErrorSet

end  # Tapestry


#
# Provides a convenient way to create a ErrorSet object.  

def Tapestry.ErrorSet( maximum )
   return Tapestry::ErrorSet.new( maximum )
end


#
# Test the class if called directly

if $0 == __FILE__ then

end

