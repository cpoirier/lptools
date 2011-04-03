#!/usr/bin/ruby
#
# Provides location management for the zones.
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

require 'ftools'

module Tapestry
module Build


#
# build arranges its work in zones.  Each zone is treated as an independent
# unit, and processing within the zone is handled as if the build executable
# was running inside the zone's root directory.  This class provides global
# management of the current directory, to save everyone else from having
# to do it...

class LocationManager

   INVOCATIONHOME = Dir.pwd()

   def LocationManager.getInvocationHomeDirectory( )
      return INVOCATIONHOME
   end

   def getInvocationHomeDirectory()
      return LocationManager.getInvocationHomeDirectory()
   end


   @home         = nil  # The Zone's home directory
   @current      = nil  # The Zone's current directory
   @targets      = nil  # The Zone's target directory

   attr_reader :home, :current, :targets

   #
   # Setters for @home, @targets, and @current that normalize the path.

   def home=( path )
      @home = Dir.normalize_path( path, self.current )
   end

   def current=( path )
      @current = Dir.normalize_path( path, self.current )
   end

   def targets=( path )
      @targets = Dir.normalize_path( path, self.current )
   end


   def initialize( homeDirectory = pwd(), targetDirectory = homeDirectory )

      @current = Dir.normalize_path( homeDirectory )

      self.home    = homeDirectory
      self.targets = targetDirectory

   end



 #-----------------------------------------------------------------------------
 # CONVERSION ZONE RELATIVE TO ABSOLUTE PATHS

   def offsetHome( path )
      return File.normalize_path( path, self.home )
   end

   def offsetTargets( path )
      return File.normalize_path( path, self.targets )
   end

   def offsetCurrent( path )
      return File.normalize_path( path, self.current )
   end



 #-----------------------------------------------------------------------------
 # CONVERSION ABSOLUTE PATHS TO ZONE RELATIVE


   #
   # Return paths relative to the specified directory, if it branches no more
   # than 3 directory levels above.  Return absolute paths otherwise.

   def relativeHome( path )
      return File.contract_path( path, self.home )
   end

   def relativeTargets( path )
      return File.contract_path( path, self.targets )
   end

   def relativeCurrent( path )
      return File.contract_path( path, self.current )
   end


 #-----------------------------------------------------------------------------
 # DIRECTORY CHANGING WITH TRACKING


   def chdirHome( offset="" )
      chdir( offsetHome(offset) )
   end


   def chdirTargets( offset="" )
      chdir( offsetTargets(offset), true )
   end


   def chdirCurrent( offset="" )
      chdir( offsetCurrent(offset) )
   end





 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private


   #
   # Returns Dir.pwd() 

   def pwd()
      return Dir.pwd()
   end


   #
   # Dir.chdir, with File.mkpath on error

   def chdir( path, make = false )

      retried = false
      begin
         Dir.chdir( path )
         self.current = pwd()

      rescue SystemCallError
         if make then
            if not retried then
               File.mkpath( path )
               retried = true
               retry
            else
               raise_directoryError( "unable to create directory", path ) 
            end

         else
            raise_directoryError( "unable to change directory", path )

         end
      end

   end



 #-----------------------------------------------------------------------------
 # ERROR HANDLING

   def raise_systemError( details, path )
      LocationManager.raise_directoryError( details, path )
   end

   def LocationManager.raise_directoryError( details, path )
      raise Tapestry::Error( "directory error", { "details", details, "path", path } )
   end


end  # LocationManager


end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__

   puts( Tapestry::Build::LocationManager.getInvocationHomeDirectory() )

end


