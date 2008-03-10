#
#  Preferences.rb
#  MountObserverRuby
#
#  Created by vgod on 2008/2/10.
#  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
#

require 'osx/foundation'

OSX.require_framework 'SystemConfiguration'
$VERBOSE = true

# Wrapper class to access SCPreferences API.
class Preferences
    def initialize(appid)
		# Unlike the CFPreferences API, SCPreferences requires the actual
		# plist filename, which always end in '.plist'.
		appid = "#{appid}.plist" unless appid =~ /\.plist$/
		
		@prefs = OSX::SCPreferencesCreate(nil, $0, appid)
		@keys = Preferences.to_native(OSX::SCPreferencesCopyKeyList(@prefs))
		@keys.push('PreferencesSignature')
		
		$stderr.print \
	    "SCPreferences (appid=#{appid}) keys: #{@keys.join(",")}\n" if $DEBUG
			
	end
		
	def each
		keys.each { | key |
			yield key, self[key]
		}
	end
		
	def signature
		sig = OSX::SCPreferencesGetSignature(@prefs)
		
		# Converting CFData to a string ends up with something that looks like
		# this: <0500000e 4a5e0f00 e8e24046 00000000 f8000000 00000000>
		# We strip the angle brackets and spaces to give a plain hex string.
		return sig.to_s.gsub(/[ <>]/, '')
	end
	
	def has_key?(key)
		return @keys.include?(key)
	end
	
	def [](key)
		case key
			when 'PreferencesSignature'
			return self.signature
			else
			val = OSX::SCPreferencesGetValue(@prefs, key)
			
			# Need to convert to a native Ruby type because we merge these
			# values with our default set, which are native types.
			return (Preferences.to_native(val) rescue nil)
		end
	end
	
	def []=(key, val)
		$stderr.print "#{$0}: setting #{key} to #{val} (#{val.class})\n" if $VERBOSE
		OSX::SCPreferencesSetValue(@prefs, key, val)
	end
		
	def commit
		OSX::SCPreferencesCommitChanges(@prefs)
	end
		
		# Load a preferences hash from a plist.
	def Preferences.load_plist(path)
		print "#{$0}: loading #{path}\n" if $VERBOSE
		data = OSX::NSData.dataWithContentsOfFile(path)
		return nil unless data
		
		plist, format, err = OSX::NSPropertyListSerialization.propertyListFromData_mutabilityOption_format_errorDescription(data,
																															OSX::NSPropertyListImmutable)
		
		if (plist == nil or !plist.kind_of? OSX::NSCFDictionary)
			return nil
		end
		
		return Preferences.to_native(plist)
	end
	
	# Convert a CFPropertyListRef to a native Ruby type.
	def Preferences.to_native(val)
		
		return nil if val == nil
		
		$stderr.print "converting (#{val.class})\n" if $DEBUG
		
		if val.kind_of? OSX::NSCFBoolean
			return (val == OSX::KCFBooleanTrue ? true : false)
		end
		
		if val.kind_of? OSX::NSCFString
			return val.to_s
		end
		
		if val.kind_of? OSX::NSCFNumber
			return val.to_i
		end
		
		if val.kind_of? OSX::NSCFArray
			array = []
			val.each { |element| array += [ Preferences.to_native(element) ] }
			
			return array
		end
		
		if val.kind_of? OSX::NSCFDictionary
			hash = {}
			val.allKeys().each { | key |
				# Note: we need to convert both the key and the data, 
				# otherwise we will end up indexed by OSX::NSCFString and
				# won't be able to index by Ruby Strings.
				new_key = Preferences.to_native(key)
				new_val = Preferences.to_native(val[key])
				hash[new_key] = new_val
			}
			return hash
		end
		
		# NOTE: We don't convert CFData or CFDate because we
		# don't need them for the preferences we have.
		
		$stderr.print \
		"#{$0}: preferences type #{val.class} is not supported\n"	if $VERBOSE
		return nil
	end
end
	