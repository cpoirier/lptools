#!/usr/bin/ruby
#
# Language extensions for Ruby.
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


#
# These two functions mirror those from BASIC.

def asc( string )
   return string[0]
end


def chr( code )
   return code.chr
end


#
# Assertion functionality, for reducing bugs in the code.

class AssertionFailure < ScriptError
end

def assert( condition, message, exceptionClass = AssertionFailure )
   unless condition
      exception = exceptionClass.new( message )
      raise exception
   end
end

#
# Verifies that object is of the specified type.  If type is an error,
# verifies that object is one of the specified types.  Unless allowNil,
# object cannot be nil.

def type_check( object, type, allowNil = false )

   typeMessage = ""
   error = true

   if object.nil? then
      error = false if allowNil

   elsif type.kind_of?( Array ) then

      type.each do |t|
         if object.kind_of?(t) then
            error = false
            break
         end
      end

      if error then
         names = type.map {|t| t.name}
         typeMessage = "expected one of [ " + names.join( ", " ) + " ]"
      end

   else
      if object.kind_of?(type)
         error = false
      else
         typeMessage = "expected " + type.name
      end

   end

   if error then
      actual = object.class.name
      message = "wrong argument type " + actual + " (" + typeMessage + ")"
      raise TypeError.new( message )
   end

end



#
# Adds some methods to String.

class String

   def begins( with )
      return (slice(0, with.length) == with)
   end

   def ends( with )
      length = with.length
      return (length > 0 ? (slice(-length..-1) == with) : true )
   end

   #
   # If self starts with string, returns the rest of self.  Otherwise
   # returns nil.

   def after( string )
      after = nil
      if begins(string) then
         after = slice(string.length..-1)
      end
      return after
   end

   def first( length = 1 )
      return self[0..length-1]
   end

   def last( length = 1 )
      return self[(-length)..-1]
   end

   def rest( from = 1 )
      return self[from..-1]
   end


   alias contains? include?

end  # String



#
# Adds some methods to Array

class Array

   #
   # Returns an array containing those elements of this array
   # for which the supplied block returns true.

   def select() 
      selected = []
      self.each do |element|
         result = yield( element )
         break if result.nil?
         selected.append( element ) if result
      end
      return selected
   end

   

   #
   # Inserts an element at the specified location.

   def insert!( at, element )
      self[at, 0] = element
   end


   #
   # Inserts the given element into a priority sorted array.
   # Each element in the array must have a priority() method
   # that returns an integer.  Highest priority elements are
   # at the front of the list.  If fifo is true, new elements
   # are inserted after all elements of the same priority.  If
   # false, new elements are inserted before any elements of 
   # the same priority.

   def priority_insert!( element, fifo = true )

      at       = length
      priority = element.priority

      if fifo then
         each_index do |index|
            if self[index].priority < priority then
               at = index
               break
            end
         end

      else
         each_index do |index|
            if self[index].priority <= priority then
               at = index
               break
            end
         end

      end

      insert!( at, element )

   end


   def rest( from = 1 )
      rest = slice( from, self.length - from )
      rest = [] if rest.nil?
      return rest
   end

   def first( count = 1 )

      first = nil
      if count == 1 then
         first = slice( 0, 1 )

      else
         first = slice( 0, count )
         first = [] if rest.nil?

      end

      return first
   end


   #
   # I never liked the perl names for these routines.  They are even 
   # worse in Ruby...

   alias append  push
   alias prepend unshift

   alias remove_head shift
   alias remove_tail pop

end



#
# Adds some methods to Dir

class Dir

   #
   # File and Dir don't seem to have very good platform independent 
   # path manipuation code, and File.expand_path() isn't (IMHO) 
   # particularly consistent in the way trailing slashes are handled.
   # These routines return the directory path with a trailing slash.
   # If you pass nil for relativeTo, path is not expanded first.

   def Dir.normalize_path( path, relativeTo=Dir.pwd() )

      rubyWay = (relativeTo.nil? ? path : File.expand_path(path, relativeTo))

      withSlash = rubyWay
      withSlash += File::Separator unless withSlash.ends(File::Separator) 

      return withSlash

   end

end  # Dir


#
# Adds some methods to File

class File


   #
   # An analogue to Dir.normalize_path(), added above, this version
   # checks if the path is to a directory or a file, and returns the
   # appropriate path string.  Directories will always have a trailing
   # slash.  If you pass nil for relativeTo, path is not expanded.

   def File.normalize_path( path, relativeTo=Dir.pwd() )

      normalized = (relativeTo.nil? ? path : File.expand_path(path, relativeTo))

      if File.directory?( normalized ) then
         normalized = Dir.normalize_path( normalized, nil )
      end

      return normalized

   end


   #
   # An analogue to File.expand_path(), returns a relative path, if
   # path is inside relativeTo, or within maxBack directories above it.

   @@upOneDirectoryAfter  = File::Separator + ".."
   @@upOneDirectoryBefore = ".." + File::Separator

   def File.contract_path( path, relativeTo=Dir.pwd(), maxBack = 3 )

      relativeTo = Dir.normalize_path( relativeTo )
      normalized = File.normalize_path( path, relativeTo )

      levelsBack = 0
      0.upto(maxBack) do |level|

         current = File.expand_path( relativeTo + (@@upOneDirectoryAfter * level) )
         current = File.normalize_path( current, nil )

         if normalized.begins(current) then
            normalized = normalized[current.length..-1]
            levelsBack = level
         end
      end

      return (@@upOneDirectoryBefore * levelsBack) + normalized

   end


   #
   # Returns true if the path is absolute.  
   # WARNING: This routine will need to be fixed for Windows and other
   #          non-unix platforms.

   def File.absolute?( path )
      raise NotImplementedError( "no windows support" ) if RUBY_PLATFORM.contains?("win")
      return path.begins(File::Separator)
   end

end  # File



#
# Adds some methods to Time

class Time

   @@epoch = Time.at(0)
   def Time.epoch
      return @@epoch
   end

end  # Time


#
# Extends Regexp to allow wildcard expressions to be compiled into
# regular expressions.  Each wildcard character is considered a 
# group, and the expression is required to match the whole text.
# The search text is expected to be a file path!
#
# Wildcard special characters:
#  *   matches any character
#  ?   matches one character
#  .   matches only itself
#  **/ at the beginning of the text or following a slash, matches 0 or more directories

class Wildcard 

   @compiled   = nil     # The compiled Wildcard expression
   @uncompiled = nil     # The raw wildcard text from which this Wildcard is compiled

   @mapped     = false   # Set true once the source expression has been mapped (see map() below)
   @map        = []      # A list of the wildcard patterns in the source expression


   #
   # The first clause of these two patterns matches escaped wildcards,
   # which are generally ignored.  The second clause matches unescaped
   # wildcards or other special characters.

   @@pattern    = /((?:^|[^\\])(?:\\\\)*[\\][*?])|((?:(?:^|\/)\*\*\/)|(?:[*?]))/ 
   @@compiler   = /((?:^|[^\\])(?:\\\\)*[\\][*?.])|((?:(?:^|\/)\*\*\/)|(?:[*?.]))/ 

   @@expansions = { ".",    "\\."                \
                          , "*",    "([^/]*)"            \
                          , "?",    "([^/])"             \
                          , "**/",  "\\A(/?(?:[^/]*/)*)" \
                          , "/**/", "(/(?:[^/]*/)*)"     }


   #
   # A synonym for Wildcard.new()

   def Wildcard.compile( expression )
      return Wildcard.new(expression)
   end


   #
   # The pattern will work intuitively on path texts.  
   # Currently handles only UNIX style paths.

   def initialize( expression )

      type_check( expression, String )

      @uncompiled = expression
      @mapped     = false
      @map        = []

      if @uncompiled.nil? then
         @uncompiled = expression 
         raise TypeError.new("@uncompiled refused to accept assignment again") if @uncompiled.nil?
      end

      compiled = @uncompiled.gsub(@@compiler) do |match|
         if $1.nil? then  
            @@expansions[match]
         else
            match
         end
      end

      @compiled = Regexp.compile(compiled + "\\Z")

   end



 #-----------------------------------------------------------------------------
 # REGEXP OPERATIONS

   def ===( string )
      return @compiled === string
   end

   def =~( string )
      return @compiled =~ string
   end

   def casefold?()
      return false
   end

   def match( string )
      return @compiled.match(string)
   end

   def source()
      return @uncompiled
   end

   def intermediate()
      return @compiled.source
   end



 #-----------------------------------------------------------------------------
 # ADDITIONAL OPERATIONS

   #
   # Splices the matching text from one wildcard search into another wildcard
   # expression.  Into and text must be Strings.  Returns nil if the text
   # doesn't match this Wildcard.

   def splice( into, text )

      type_check( into, String )
      type_check( text, String )

      result = nil
      m = @compiled.match( text )

      unless m.nil?

         #
         # Construct lists of result for each wildcard type

         common = []
         matches = { "*", [], "?", [], "**/", common, "/**/", common }

         map()
         @map.each_index do |index|
            type = @map[index]
            matches[type].push( m[index+1] )
         end
         

         #
         # And construct the result string

         result = m.pre_match + into + m.post_match 

         result.gsub!( @@pattern ) do |match|
            if $1.nil? then
               if match.begins("/") and not matches[match].empty? and not matches[match][0].begins("/") then
                  "/" + matches[match].shift()
               else
                  matches[match].shift()
               end
            else
               match
            end
         end

      end

      return result

   end



   #
   # Returns the number of wildcard characters found in the string.

   def Wildcard.count( string )

      count = 0

      if string.is_a?(String) then
         matches = string.scan(@@pattern)
         matches.each do |pair|
            if pair[0].nil? then
               count += 1
            end
         end
      end

      return count
   end


   #
   # Returns true if the string holds directory delimiters.

   def Wildcard.directory?( string )
      return true if string =~ /\//
   end


 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private

   #
   # Makes a list of the wildcard characters in the source expression.

   def map()
      unless @mapped
         @mapped = true
         @map    = []

         matches = @uncompiled.scan(@@pattern)
         matches.each do |pair|
            if pair[0].nil? then
               @map.push( pair[1] )
            end
         end
      end
   end


end  # Wildcard



#
# Test the code, if invoked directly.

if $0 == __FILE__ then
 begin

   while true

      puts()
      puts()
      puts()
      puts( "tests: " )
      puts( "   a - wildcard expression" )
      puts( "   b - wildcard splice    " )
      puts( "   c - contract path      " )
      puts()
      print( "> " )
      test = STDIN.gets()
      exit if test.nil?
      test.chomp!
   
      case test
   
       when "a"
         while true
            puts()
            puts()
            puts()
            puts( "-----------------------------------------------------------------" )
            puts( " TESTING WILDCARDS COMPILATION AND MATCHING                      " )
            puts( )

            begin
               print( "enter a wildcard expression: " )
      
               wildcard = STDIN.gets()
               exit if wildcard.nil?
               wildcard.chomp!
         
               regex = Wildcard.compile(wildcard)
               puts( regex.source + " => " + regex.intermediate )

            rescue Interrupt
               break
            end
            
            while true
               puts()
               print( "> " )

               begin
                  text = STDIN.gets()
                  exit if text.nil?
                  text.chomp!

               rescue Interrupt
                  break
               end
      
               m = regex.match( text )
               if m.nil? then
                  puts( " ===> no match" )
               else
                  puts( " ===> matches" )
                  puts( " ===> [-1] = " + m.pre_match )
                  0.upto(m.length-1) do |index|
                     puts( " ===> [" + index.to_s.rjust(2) + "] = " + m[index].to_s )
                  end
               end
            end
         end
      
   
       when "b"
         while true
            puts( "-----------------------------------------------------------------" )
            puts( " TESTING WILDCARD SPLICING                                       " )
            puts( )
   
            begin
               print( "enter a source wildcard expression: " )
               source = STDIN.gets()
               exit if source.nil?
               source.chomp!
               wildcard = Wildcard.compile( source )
         
               print( "enter a target wildcard expression: " )
               target = STDIN.gets()
               exit if target.nil?
               target.chomp!
   
            rescue Interrupt
               break
            end
      
            while true
               puts()
               print( "> " )
   
               begin
                  text = STDIN.gets()
                  exit if text.nil?
                  text.chomp!
   
               rescue Interrupt
                  break
               end
      
               result = wildcard.splice( target, text )
               puts( " ===> " + result.to_s )
            end
         end
   
   
       when "c"
         puts( "-----------------------------------------------------------------" )
         puts( " TESTING PATH CONTRACTION                                        " )
         puts( )
   
         while true
            puts()
            print( "> " )

            begin
               path = STDIN.gets()
               exit if path.nil?
               path.chomp!

            rescue Interrupt
               break
            end
   
            result = File.contract_path( path )
            puts( " ===> " + result.to_s )
         end
   
   
       else
         puts( "unknown test: " + test )
   
      end   # case

   end   # while true
   
 rescue Interrupt
   puts( "quitting..." )
 end

end


