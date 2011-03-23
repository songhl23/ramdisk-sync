#
#  ObserverController.rb
#  MountObserverRuby
#
#  Created by vgod on 2/8/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'FileUtils'
require 'Preferences'

$HOME = ENV['HOME']
$USER_PREFERENCES_PATH = "#{$HOME}/Library/Preferences"
$APP_ID = 'tw.vgod.RamdiskSync'
$LINK_LOG_FILE = '.lnPaths'

class ObserverController < NSWindowController
	attr_accessor :prefs, :volName, :copyContent
	
	def copyToRamdisk(src)
		NSLog("copy #{src} to ramdisk")
		cmd = "tar cf - #{src} | (cd #{self.volName}; tar xf -)"
		system cmd
	end
	
	def copyFromRamdisk(dst)
		cmd = "cd #{self.volName}; tar cf - .#{dst} | (cd /; tar xf -)"
		NSLog("copy back #{dst}: #{cmd}")
		system cmd
	end
	
	def onMountEvent(note)
		note_path = note.userInfo['NSDevicePath']
		NSLog("onMount: [#{note_path}] [#{self.volName}]")
		if note_path == self.volName
			lnPaths =  self.prefs['syncItems'].select{ |i| i['enabled'] }.map{ |i| i['path']}
			lnLogFile = File.open("#{self.volName}/#{$LINK_LOG_FILE}", "w") 
			lnPaths.each do |p|
				puts "Link #{p}"
				lnLogFile.puts "#{p}"
				p_in_ramdisk = "#{self.volName}#{p}"
				if self.copyContent
					copyToRamdisk p
				else
					FileUtils.mkdir_p p_in_ramdisk
				end
				FileUtils.mv p, "#{p}.orig"
				FileUtils.ln_s p_in_ramdisk, p
			end
			lnLogFile.close
		end
	end
	def onWillUnmountEvent(note)
		NSLog("onWillUnmount: #{note.userInfo['NSDevicePath']}")
		f = File.open("#{self.volName}/#{$LINK_LOG_FILE}")
		f.each do |path|
			path.chomp!
			if File.lstat(path).symlink? and File.exist?("#{path}.orig")
				FileUtils.rm path
				if self.copyContent
					copyFromRamdisk path
					FileUtils.rm_r "#{path}.orig"
				else
					FileUtils.mv "#{path}.orig", path
				end
			end
		end
		f.close
		NSLog("onWillUnmount done: #{note.userInfo['NSDevicePath']}")
	end

   def createRamdDisk
      bundle = NSBundle.mainBundle
      mkramdisk = bundle.pathForAuxiliaryExecutable "mkramdisk.sh"
      size = self.prefs['ramdiskSize']
      name = self.prefs['ramdiskName']
      cmd = "#{mkramdisk} #{size} #{name}"
      cmd += " hide" if self.prefs['isHidden']
      puts "Create ramdisk: #{cmd}"
      system cmd
   end

   def needAutoMount?
      mountedPaths = NSWorkspace.sharedWorkspace().mountedLocalVolumePaths
      mounted = mountedPaths.include? self.volName
      return self.prefs['autoMount'] && !mounted
   end

	def onPreferenceChanged(note)
		loadPreferences
	end
	
	def init
		if super_init
			if loadPreferences
				center = NSWorkspace.sharedWorkspace().notificationCenter()
				center.addObserver_selector_name_object(self, "onMountEvent:", 
								   NSWorkspaceDidMountNotification,
								   nil)
				center.addObserver_selector_name_object(self, "onWillUnmountEvent:", 
								   NSWorkspaceWillUnmountNotification,
								   nil)
				dn_center = NSDistributedNotificationCenter.defaultCenter()
				dn_center.addObserver_selector_name_object(self, "onPreferenceChanged:", "PreferencesChanged", nil)
				createRamdDisk if needAutoMount?
			end
			NSLog("MountObserver inited..")
		end
		self
	end
	
	def awakeFromNib
	end

	def loadPreferences
		self.prefs = Preferences.load_plist "#{$USER_PREFERENCES_PATH}/#{$APP_ID}.plist"
		if self.prefs and self.prefs.has_key? 'ramdiskName'
			self.volName = "/Volumes/#{self.prefs['ramdiskName']}"
			self.copyContent = self.prefs['isCopyDir']
			NSLog("Monitor on #{self.volName}")
			return true
		end
		return false
	end
end
