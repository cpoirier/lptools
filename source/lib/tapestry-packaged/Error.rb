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


module Tapestry

#
# A hash-like class that can be used as an exception.  message() produces
# a nice summary of the tags.

class Error < Exception

   @fatal     = false       # If true, this exception should not be buffered.
   @rc        = 10          # The suggested return code for the system

   @pairs     = nil         # Holds the name/value pairs that describe the exception

   @keyorder  = nil         # Allows user control of the key sort order
   attr_accessor :keyorder

   @keyignore = nil         # Allows user control of the which keys are output
   attr_accessor :keyignore


   def fatal=( fatal )
      @fatal = (true && fatal)
   end

   def fatal?()
      return @fatal 
   end


   def rc=( rc )
      @rc = 0 + rc
   end

   def rc()
      return @rc 
   end



   #
   # Initializes the exception data from a hash of name/value pairs.
   # message() returns the pairs in sorted name order, unless keyorder is
   # set to an array of order key names. 

   def initialize( pairs, fatal = false )
      self.fatal = fatal
      self.rc    = 10

      @pairs = Hash.new()
      @pairs.update( pairs ) unless pairs.nil?

      @keyorder  = []
      @keyignore = []
   end


   #
   # Allows additions to the exception data.  Old values are overwritten.

   def add( pairs )
      @pairs.update( pairs )
   end



   #
   # Returns an array of keys in random order.

   def keys()
      return (@keyignore.nil? ? @pairs.keys : @pairs.keys - @keyignore)
   end


   #
   # Returns an array of keys in alphabetical order.  If [[keyorder]] is
   # set, those keys will appear first, followed by any remaining keys in
   # alphabetical order.  Members from [[keyorder]] will not appear if the
   # have not been set.  Use fill() if necessary.

   def sorted_keys()
      alphakeys = keys().sort()

      sorted = (@keyorder.nil? ? alphakeys : @keyorder + (alphakeys - @keyorder))
      sorted.delete_if do |key|
         @pairs[key].nil?
      end

      return sorted
   end



   #
   # Sets the named keys to the specified value.

   def fill( keys, value, unlessAlreadySet=true )
      keys.each do |key|
         set( key, value ) unless unlessAlreadySet and member?(key)
      end
   end



   #
   # Runs a block for each pair in the data.

   def each_pair()
      @pairs.each_pair do |key, value|
         break if yield(key, value).nil?
      end
   end



   #
   # Gets the value for a particular key.

   def get( key )
      return @pairs[key]
   end



   #
   # Sets a value for a particular key.

   def set( key, value )
      return @pairs[key] = value
   end


   #
   # Removes a key.

   def delete( key )
      return @pairs.delete(key)
   end



   #
   # Returns true if the named key already exists

   def member?( key )
      return @pairs.member?( key )
   end



   #
   # Uses sorted_keys() to assemble a nicely formatted representation of the
   # data in the exception.

   def message()
      message    = ""

      sortedkeys = sorted_keys()
      longestkey = 0 
      sortedkeys.each do |key|
         if key.length > longestkey then
            longestkey = key.length
         end
      end

      sortedkeys.each do |key|
         if @pairs[key].is_a?(Array) then
            value = @pairs[key].join( "\n" + (" " * longestkey) + "  " )
         else
            value = @pairs[key].to_s
         end

         message << key.ljust(longestkey) + ": " + value + "\n"
      end

      return message
   end




   def to_s()
      return 'Tapestry::Error exception ' + (self.fatal? ? "(fatal) " : "" ) + 'containing ' + @pairs.size.to_s + ' tags'
   end

end  # Error


#
# Provides a convenient way to create a Error object.  Simply pass it a 
# hash of initial values.  If [[error]] is a Error object, data will be 
# added to it and the same object returned.  Otherwise, [[error]] is set
# into a new Error under the name "error class".

def Tapestry.Error( error, hash = nil, fatal = true )

   type_check( hash, Hash, true )

   unless error.kind_of?(Tapestry::Error)
      type  = error
      error = Tapestry::Error.new( nil )
      error.set( "error class", type )
   end

   error.add( hash ) unless hash.nil?
   error.fatal = fatal

   return error

end


end  # Tapestry



#
# Test the class as an exception

if $0 == __FILE__ then

   begin
      begin
         raise Tapestry::Error( "syntax error", {"line"=>"10"} )

      rescue Tapestry::Error
         raise Tapestry::Error( $!, {"file"=>"some.file", "z"=>1, "a"=>2, "b"=>3} )
      end

   rescue Tapestry::Error
      $!.keyorder = ["error class", "file", "line"]
      puts($!.message())
      puts()
      raise
   end

end

