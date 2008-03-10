#
#  rb_main.rb
#  MountObserverRuby
#
#  Created by vgod on 2/8/08.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
include OSX

PID_FILE = "/var/tmp/#{ENV['USER']}-mountObserver.pid"

def rb_main_init
  path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles.each do |path|
    require( File.basename(path) )
  end
end

def ensure_single_process
	if File.exists?(PID_FILE) then
		line = File.open(PID_FILE).gets.chomp
		result = `ps ax| grep ^#{line} | grep MountObserver`
		return $? != 0
	end
	true
end

if $0 == __FILE__ then
  if ensure_single_process then
	f_pid = File.open(PID_FILE,"w")
	f_pid.print Process.pid
	f_pid.close
	rb_main_init
	OSX.NSApplicationMain(0, nil)
  end
end
