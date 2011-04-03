#!/usr/bin/ruby
#
# Functor for:
#    (echo    [<any-expression>...])
#    (print    <any-expression>)
#    (system   <literal-expression:command> [<literal-expression:param>...])
#    (pipe-in  <literal-expression:command> [<literal-expression:param>...])
#    (pipe-out <literal-expression:command> [<literal-expression:param>...] <any-expression:lines>)
#    (read     <literal-expression:file name>)
#    (write    <literal-expression:file name> <any-expression:lines>)
#    (delete   <literal-expression:file name>)
#    (touch    <literal-expression:file name>)
#    (exists?  <literal-expression:file name>)
#
# See USAGE below for details.
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

ARITY_echo = 0..MAXIMUM_ARITY
USAGE_echo = <<END_USAGE.split("\n")
(echo [<any-expression>...])

Prints a series of values to the standard output.  Vectors
are flattened for printing.  Output tokens are separated by
spaces and terminated by a newline.

Returns the number of tokens output.
END_USAGE




ARITY_print = 1..1
USAGE_print = <<END_USAGE.split("\n")
(print <any-expression>)

Prints a scalar or vector to the standard output.  Vectors
are flattened for printing.  Output scalars are separated by
the value of (option print-separator) and terminated by the
value of (option print-terminator).

Returns the number of tokens output.

Example
   (set $list (q(a b c (d e (f g) h) i)))
   (option print-separator  (space))
   (option print-terminator (newline))
   (print $list)

      outputs: a b c d e f g h i
END_USAGE




ARITY_system = 1..MAXIMUM_ARITY
USAGE_system = <<END_USAGE.split("\n")
(system 
   <any-expression:command> 
   [<any-expression:param>...]
)

Assembles a valid command string (ie. appropriately quoted 
and spaced) from the supplied vector and scalar expressions.
The command string is then passed to the system for 
execution.  Returns true iff the command succeeded.
END_USAGE




ARITY_pipe_in = 1..MAXIMUM_ARITY
USAGE_pipe_in = <<END_USAGE.split("\n")
(pipe-in
   <any-expression:command> 
   [<any-expression:param>...]
)

Assembles a valid command string (ie. appropriately quoted
and spaced) from the vector and scalar expressions.  
The command string is then passed to the system for 
execution, and the lines of its output are returned as a 
vector.
END_USAGE




ARITY_read = 1..1
USAGE_read = <<END_USAGE.split("\n")
(read <literal-expression:file name>)

Opens the specified file for reading and returns its lines
as a vector.  
END_USAGE




ARITY_delete = 1..1
USAGE_delete = <<END_USAGE.split("\n")
(delete <literal-expression:file name>)

Deletes the specified file.  Returns false if there was a
problem.
END_USAGE




ARITY_touch = 1..1
USAGE_touch = <<END_USAGE.split("\n")
(touch <literal-expression:file name>)

Updates the file's modified date, creating the file if it
doesn't exist.  Returns false if there was a problem.
END_USAGE




ARITY_exists_ = 1..1
USAGE_exists_ = <<END_USAGE.split("\n")
(exists? <literal-expression:file name>)

Returns true if the named file exists, false otherwise.
END_USAGE




ARITY_pipe_out = 1..MAXIMUM_ARITY
USAGE_pipe_out = <<END_USAGE.split("\n")
(pipe-out
   <any-expression:command> 
   [<any-expression:param>...]
   <any-expression:lines>
)

Assembles a valid command string (ie. appropriately quoted
and spaced) from the vector and scalar expressions.  
The command string is then passed to the system for 
execution, and lines is written to the pipe, as a series of
lines.
END_USAGE




ARITY_write = 2..3
USAGE_write = <<END_USAGE.split("\n")
(write 
   <literal-expression:file name> 
   <any-expression:lines> 
   [<any expression:truncate>]
)

Opens the specified file for writing and writes out the 
supplied data as one or more lines.  

If truncate is supplied and evaluates to true, the file will
be truncated on open.  Otherwise, the output will be 
appended to the file.

Returns the number of lines written.
END_USAGE




class IO < Tapestry::Build::Interpreter::Function 

   @@instance = IO.new()

   def IO.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      result = ""
      case function

       when "echo", "system", "pipe-in", "pipe-out"
         limit = ( function == "pipe-out" ? arity-1 : arity )

         tokens = []
         (1..limit).each do |index|
            tokens.concat( processToVector( callDescriptor, index, localScope, interpreter ))
         end

         case function
          when "echo"
            result = doPrint( tokens, " ", "\n", interpreter )

          when "system"
            command = assembleCommand( tokens )
            result  = doSystem( command, interpreter )

          when "pipe-in"
            command = "| " + assembleCommand( tokens )
            result  = doStreamInput( command, interpreter )

          when "pipe-out"
            command = "| " + assembleCommand( tokens )
            lines   = processToVector( callDescriptor, arity, localScope, interpreter )
            result  = doStreamOutput( command, lines, false, interpreter )

         end


       when "print"
         tokens = processToVector( callDescriptor, 1, localScope, interpreter )
         tokens = ["false"] if tokens == []    # We want the empty vector to display something...
         result = doPrint( tokens, interpreter.options["print-separator"], interpreter.options["print-terminator"], interpreter )


       when "read"
         filename = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
         result   = doStreamInput( filename, interpreter )


       when "write", "touch"
         filename = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )

         lines    = []
         truncate = false
         if function == "write" then
            lines    = processToVector( callDescriptor, 2, localScope, interpreter )
            truncate = ( arity == 3 ? processToBoolean( callDescriptor, 3, localScope, interpreter ) : false )
         end
         
         result = doStreamOutput( filename, lines, truncate, interpreter )


       when "delete"
         filename = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
         begin
            File.delete(filename)
            result = interpreter.scalarize(true)
         rescue
            result = interpreter.scalarize(false)
         end


       when "exists?"
         filename = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
         result = interpreter.scalarize(File.exists?(filename))


      end

      return result

   end


   #
   # Prints a vector of tokens to standard output.

   def doPrint( tokens, join, terminator, interpreter )
      print( tokens.join(join) + terminator )
      return interpreter.scalarize(tokens)
   end


   #
   # Passes a command to system() and returns the results as a boolean.

   def doSystem( command, interpreter )
      System.puts( command ) if System.verbosity > 2 
      return interpreter.scalarize( system(command) )
   end


   #
   # Opens a stream and returns its contents as an array of lines.
   
   def doStreamInput( name, interpreter )
      System.puts( "reading from " + name ) if System.verbosity > 2

      results = []
      begin
         open( name, "r" ) do |file|
            results = file.readlines()
         end
      rescue
         raise Tapestry::Error( "runtime error",    \
            { "details" => "unable to open stream" \
            , "name"    => name                    } )
      end

      results.each do |line|
         line.chomp!
      end

      return results

   end


   #
   # Opens a stream and writes an array to it as a series of lines.

   def doStreamOutput( name, lines, truncate, interpreter )

      mode = (truncate ? "w" : "a")
      written = 0
      begin

         open( name, mode ) do |file|
            lines.each do |line|
               file.puts(line)
               written += 1
            end
         end

         raise if written < lines.length 
      rescue 
         raise Tapestry::Error( "runtime error",    \
            { "details" => "unable to open stream" \
            , "name"    => name                    } )
      end

      return interpreter.scalarize(written)

   end


   #
   # Assembles a command string from a series of tokens, quoting
   # as necessary.

   @@needsQuotingIfPattern = /[\s"]/
   @@quotePattern = /["]/

   def assembleCommand( tokens )

      command = ""
      tokens.each do |piece|
         string = piece.to_s
         if string =~ @@needsQuotingIfPattern then
            string = string.gsub(@@quotePattern, "\\\"")
            string = '"' + string + '"'
         end

         command << string + " "
      end
      command.chop!

      return command

   end

end  # IO

Function.addBuiltin( "echo"    , IO.getInstance(), ARITY_echo    , USAGE_echo     )
Function.addBuiltin( "print"   , IO.getInstance(), ARITY_print   , USAGE_print    )
Function.addBuiltin( "system"  , IO.getInstance(), ARITY_system  , USAGE_system   )
Function.addBuiltin( "pipe-in" , IO.getInstance(), ARITY_pipe_in , USAGE_pipe_in  )
Function.addBuiltin( "pipe-out", IO.getInstance(), ARITY_pipe_out, USAGE_pipe_out )
Function.addBuiltin( "read"    , IO.getInstance(), ARITY_read    , USAGE_read     )
Function.addBuiltin( "write"   , IO.getInstance(), ARITY_write   , USAGE_write    )
Function.addBuiltin( "touch"   , IO.getInstance(), ARITY_touch   , USAGE_touch    )
Function.addBuiltin( "exists?" , IO.getInstance(), ARITY_exists_ , USAGE_exists_  )
Function.addBuiltin( "delete"  , IO.getInstance(), ARITY_delete  , USAGE_delete   )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





