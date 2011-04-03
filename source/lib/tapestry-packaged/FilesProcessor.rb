#!/usr/bin/ruby
#
# Defines a Ruby class that handles processing files recursively 
# from some directory.  
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
# Given an initial list of files and some basic information, 
# handles invoking functionality over a set of files and
# directories.  If directory recursion is requested, there
# are two modes of operation: 
#   - filename generation with relative paths
#   - actual stepping of execution into each subdirectory

module Tapestry
class FilesProcessor


   #
   # Initializes the processor for processing.
   #
   # validFilePattern
   #   All files to be processed must match this pattern.
   #
   # processDirectories
   #   If set, processing will recurse into any directories on 
   #   the initial file list.  Files in recursed directories 
   #   will be selected using @validFilePattern.
   #
   # physicallyRecurse
   #   If set, and directory recursion is in use, the system
   #   will actually change to each new directory and process
   #   the files locally.  @onDirectoryEntry and @onDirectoryExit
   #   will be called each time this happens, in addition to the
   #   usual call on start/finish.  If clear, recursion will
   #   be done while staying in the initial directory.
   #
   # onFile -- {|filename| ... }
   #   The action to take for each file in the list.
   # 
   # onDirectoryEntry -- {|path| ... }
   #   Called whenever the system changes into a subdirectory.  
   #   It is also called when the processor is first started.
   #   The path is relative to the starting directory
   #
   # onDirectoryExit -- {|path| ... }
   #   Called whenever the system changes out of a subdirectory.
   #   It is also called when the processor finished.
   #   The path is relative to the starting directory
   #
   # onUnrecognized -- {|filename| ... }
   #   Called whenever a file in the process list does not match
   #   the valid filename pattern.
   #
   # onMissing -- {|filename| ... }
   #   Called whenever a file in the process list does not exist.

   def initialize( validFilePattern=/.*/, 
                   processDirectories=false, 
                   physicallyRecurse=false, 
                   onFile=proc {|filename| puts "Processing: " + filename}, 
                   onDirectoryEntry=proc {|path| puts "Entering " + path}, 
                   onDirectoryExit=proc {|path| puts "Leaving " + path}, 
                   onUnrecognized=proc {|filename| puts "?: " + filename}, 
                   onMissing=proc {|filename| puts "missing: " + filename })

      @validFilePattern   = validFilePattern
      @processDirectories = processDirectories
      @physicallyRecurse  = physicallyRecurse

      @onFile             = onFile
      @onDirectoryEntry   = onDirectoryEntry
      @onDirectoryExit    = onDirectoryExit
      @onUnrecognized     = onUnrecognized
      @onMissing          = onMissing
   end

   attr_writer :processDirectories, :physicallyRecurse


   #
   # Process a list of files.  We clone the list because we
   # might need to change it...

   def processFiles( filepaths, pathRelativeStart="./" )
      filepaths = filepaths.clone()

      @onDirectoryEntry.call( pathRelativeStart ) unless @onDirectoryEntry.nil?

      filepaths.each do |filepath|
         basename = File.basename( filepath )

         if not File.exists?( filepath ) then
            @onMissing.call( filepath ) unless @onMissing.nil?
         elsif File.directory?( filepath ) then
            if @processDirectories then
               newpath = filepath + "/"

               unless @physicallyRecurse 
                  filepaths.concat( processDirectory( newpath, true ) )
               else
                  current = Dir.pwd
                  Dir.chdir( newpath )
                  processFiles( processDirectory( "./", false ), pathRelativeStart + newpath )
                  Dir.chdir( current )
               end
            end

         elsif File.file?( filepath ) and basename =~ @validFilePattern then
            @onFile.call( filepath )
         else
            @onUnrecognized.call( filepath ) unless @onUnrecognized.nil?
         end
      end

      @onDirectoryExit.call( pathRelativeStart ) unless @onDirectoryExit.nil?
   end

 private

   #
   # Given a directory, returns the list directories and
   # valid file names.
   
   def processDirectory( directory, prependDirectory )
      dir = Dir.open( directory )
      filepaths = dir.select do |filepath|
         use = false

         if File.directory?( directory + filepath ) then
            use = (filepath != "." and filepath != "..")
         else
            use = (filepath =~ @validFilePattern)
         end
  
         use
      end

      if prependDirectory then
         filepaths = filepaths.map do |filepath|
            directory + filepath
         end
      end 
   
      return filepaths
   end

end  # FilesProcessor
end  # Tapestry



#
# Test the class.

if $0 == __FILE__ then
  
   if ARGV.length > 0 then
      puts( "PROCESSING WITH NO RECURSION:" )
      processor = Tapestry::FilesProcessor.new()
      processor.processFiles( ARGV )

      puts( "" )
      puts( "PROCESSING WITH LOGICAL RECURSION:" )
      processor.processDirectories = true
      processor.processFiles( ARGV )

      puts( "" )
      puts( "PROCESSING WITH PHYSICAL RECURSION:" )
      processor.physicallyRecurse = true
      processor.processFiles( ARGV )

   else
      puts( "Please specify files and/or directories to handle." )
  
   end
end    


