#import "MainPane.h"
#import <stdlib.h>
#import <unistd.h>


@implementation MainPane
- (id)initWithBundle:(NSBundle *)bundle
{
    if ( ( self = [super initWithBundle:bundle] ) != nil ) {
        appID = CFSTR("tw.vgod.RamdiskSync");
		pathToMkRamdisk = [[bundle pathForAuxiliaryExecutable:@"mkramdisk.sh"] copy];
		pathToObserver = [[bundle pathForAuxiliaryExecutable: @"MountObserver.app"] copy];
		NSLog(@"init bundle: %@", pathToObserver);
    }
	NSLog(@"bundle: %@", [NSBundle bundleForClass:[self class]]);
    return self;
}

- (void)dealloc {
	[ramdiskName release];
	[syncItems release];
	[super dealloc];
}

- (void)mainViewDidLoad {
	CFPropertyListRef value = CFPreferencesCopyAppValue( CFSTR("ramdiskName"),  appID );
	if( value )
		[self setRamdiskPath:(NSString *)value];
	else
		[self setRamdiskPath:@"Ramdisk"];
	value = CFPreferencesCopyAppValue( CFSTR("ramdiskSize"),  appID );
	if( value ){
		NSInteger val;
		CFNumberGetValue(value, kCFNumberNSIntegerType, &val);
		[self setRamdiskSize:val];
	}
	else
		[self setRamdiskSize:128 ];
	value = CFPreferencesCopyAppValue( CFSTR("isHidden"),  appID );
	if( value ){
		isHidden = [(NSNumber *)value copy];
		[chk_isHidden setState:[isHidden integerValue]];
	}
	value = CFPreferencesCopyAppValue( CFSTR("isCopyDir"),  appID );
	if( value )
		isCopyDir = [(NSNumber *)value copy];
	else
		isCopyDir = [NSNumber numberWithBool:YES];
	[chk_isCopyDir setState:[isCopyDir integerValue]];
	value = CFPreferencesCopyAppValue( CFSTR("autoMount"),  appID );
	if( value ){
		autoMount = [(NSNumber *)value copy];
		[chk_autoMount setState:[autoMount integerValue]];
	}
	value = CFPreferencesCopyAppValue( CFSTR("syncItems"),  appID );
	if( value && CFGetTypeID(value) == CFArrayGetTypeID() ){
		syncItems = [[NSMutableArray alloc] init];
		[syncItems setArray:(NSMutableArray *)value];
	}
	else{
		//syncItems = [[NSMutableArray alloc] initWithObjects: @"A", @"B", nil];	
		syncItems = [[NSMutableArray alloc] init];
		[self setupDefaultSyncItems];

	}
	[self startObserver];
	[self updateMountState: [self isMounted]];
}

- (void)setupDefaultSyncItems{
	NSString *home = NSHomeDirectory();
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *defaultPaths[] = { 
//		@"/tmp",  // root only
		[home stringByAppendingPathComponent:@"Library/Caches/com.apple.Safari"], 
		[home stringByAppendingPathComponent:@"Library/Caches/Firefox"],
		nil
	};
	int i;
//	for(NSString* path in defaultPaths){
	for(i=0;defaultPaths[i] != nil;i++){
		if([fm fileExistsAtPath: defaultPaths[i]])
			[self addSyncItem: defaultPaths[i]];
	}
	 
}

- (BOOL)startObserver {
	[self savePreferences];
	//TODO: hide the observer
	FSRef fref;
	if(	FSPathMakeRef ((const UInt8 *)[pathToObserver fileSystemRepresentation], &fref, NULL) == noErr ){
		LSApplicationParameters app;
		app.application = &fref;
		app.version = 0;
		app.flags = kLSLaunchDontSwitch | kLSLaunchAsync | kLSLaunchAndHide;
		app.asyncLaunchRefCon = NULL;
		app.argv = NULL;
		app.environment = NULL;
		app.initialEvent = NULL;
		OSStatus ret = LSOpenApplication(&app, NULL);
		return ret == 0;
	}
	return NO;
}

- (void)savePreferences
{
	CFPreferencesSetAppValue( CFSTR("ramdiskName"), ramdiskName, appID );
	CFNumberRef tmp_size = CFNumberCreate(NULL, kCFNumberNSIntegerType, &ramdiskSize);
	CFPreferencesSetAppValue( CFSTR("ramdiskSize"), tmp_size, appID );
	CFRelease(tmp_size);
	CFPreferencesSetAppValue( CFSTR("isHidden"), isHidden, appID );
	CFPreferencesSetAppValue( CFSTR("isCopyDir"), isCopyDir, appID );
	CFPreferencesSetAppValue( CFSTR("autoMount"), autoMount, appID );
	
	CFPreferencesSetAppValue( CFSTR("syncItems"), syncItems, appID );
	
	CFPreferencesAppSynchronize( appID );
	
	NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
	[center postNotificationName:@"PreferencesChanged" object:nil];

	NSLog(@"Preferences Changed");
}

- (void)didUnselect
{
	[self savePreferences];
}

- (NSNumber *)getFileSize:(NSString *)filepath{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *fileAttributes = [fileManager fileAttributesAtPath:filepath traverseLink:YES];
	if( fileAttributes != nil ){
		NSNumber *fileSize;
		if (fileSize = [fileAttributes objectForKey:NSFileSize])
		   return fileSize;
	}
	return nil;
}

- (IBAction)setAutoMount:(id)sender{
	CFArrayRef prefCFArrayRef = CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"), CFSTR("loginwindow"));
	CFMutableArrayRef tCFMutableArrayRef = CFArrayCreateMutableCopy(NULL, 0, prefCFArrayRef);	
	NSString *keys[] = {@"Path", @"Hide"};
	void *values[] = {(void*)pathToObserver, (void*)kCFBooleanTrue};
	CFDictionaryRef autoLaunchItem = CFDictionaryCreate(NULL, (void*)keys, (void*)values, 2, NULL, NULL);	
	if( [sender state] == NSOnState ){
		CFArrayAppendValue(tCFMutableArrayRef, autoLaunchItem);
		autoMount = [NSNumber numberWithBool:YES];
	}
	else{
		CFIndex i = 0, count = CFArrayGetCount(tCFMutableArrayRef);
		while(i<count){
			CFDictionaryRef item = (CFDictionaryRef)CFArrayGetValueAtIndex(tCFMutableArrayRef, i);
			const void *val = CFDictionaryGetValue(item, @"Path");
			if( val && [pathToObserver isEqual:(NSString *)val] ){
				CFArrayRemoveValueAtIndex(tCFMutableArrayRef, i);
				count--;
			}
			else
				i++;
		}
		autoMount = [NSNumber numberWithBool:NO];	
	}
	CFPreferencesSetAppValue(CFSTR("AutoLaunchedApplicationDictionary"), tCFMutableArrayRef, CFSTR("loginwindow"));
	prefCFArrayRef = CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"), CFSTR("loginwindow"));
	CFPreferencesAppSynchronize(CFSTR("loginwindow"));
}

- (void)sheetDidEnd:(NSWindow *)sheet 
		 returnCode:(int)returnCode 
		contextInfo:(void *)contextInfo{

}

- (IBAction)closeHelpWindow:(id)sender{
    [NSApp endSheet:win_about];
}

- (IBAction)showHelpWindow:(id)sender{
/*
    [NSApp beginSheet:win_about
	   modalForWindow:sender
	   modalDelegate:self 
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:nil];
*/
}

- (IBAction)addTarget:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	if( [openPanel runModalForTypes:nil] == NSOKButton ){
		NSString *filename = [openPanel filename];
		[self addSyncItem:filename];
		[targetView reloadData];
	}	
}

- (void)addSyncItem: (NSString*)filename {
	NSMutableDictionary *item = [NSMutableDictionary dictionary];
	[item setObject:filename forKey:@"path"];
	[item setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
	//		[item setObject:[self getFileSize:filename] forKey:@"size"];
	[item setObject: @"-" forKey:@"size"];
	//TODO: open a new thread to calculate dir size
	//TODO: restart observer, or update SyncItems in plist
	[syncItems addObject: item];	
}

- (IBAction)delTarget:(id)sender {
	int idx = [targetView selectedRow];
	[syncItems removeObjectAtIndex:idx];
	[targetView reloadData];
}

- (IBAction)changeRDVol:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	if( [openPanel runModalForTypes:nil] == NSOKButton ){
		[self setRamdiskPath: [openPanel filename]];
	}
}

- (NSNumber*) getRamdiskFreeSize{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDictionary *fsAttributes = [fileManager fileSystemAttributesAtPath:ramdiskPath];
	NSLog(@"freespace: %@", [(NSNumber*)[fsAttributes objectForKey:NSFileSystemFreeSize] stringValue]);
	return (NSNumber*)[fsAttributes objectForKey:NSFileSystemFreeSize];
}

- (NSInteger) getRamdiskFreePercent{
	NSInteger free = (NSInteger)([[self getRamdiskFreeSize] floatValue]/1048576.0/ramdiskSize*100);
	NSLog(@"free percent: %d", free);
	return free;
}

- (BOOL)isMounted{
	NSArray *mountedPaths = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	BOOL mounted =  [mountedPaths containsObject:ramdiskPath];
	NSLog(@"Mounted: %d", mounted);
	return mounted;
}

#define THIS_BUNDLE [NSBundle bundleForClass:[self class]]
#define EJECT_STRING NSLocalizedStringFromTableInBundle(@"Eject",nil,THIS_BUNDLE,"Eject button")
#define CREATE_STRING NSLocalizedStringFromTableInBundle(@"Create",nil,THIS_BUNDLE,"Create button")

- (void)updateMountState: (BOOL)mounted {
	if( mounted ){
		[btn_mountEject setTitle: EJECT_STRING];
		[btn_mountEject setState: NSOnState];
		[txt_ramdiskPath setEnabled:NO];
		float freesize = [[self getRamdiskFreeSize] floatValue];
		[txt_ramdiskFreeSize setStringValue: [NSString stringWithFormat:@"%.1f/%d MB", freesize/1048576, ramdiskSize]];
		[lvl_ramdiskFreeSize setIntegerValue:[self getRamdiskFreePercent]];
	}
	else{
		[btn_mountEject setTitle: CREATE_STRING];
		[btn_mountEject setState: NSOffState];
		[txt_ramdiskPath setEnabled:YES];
		[txt_ramdiskFreeSize setStringValue: @"-"];
		[lvl_ramdiskFreeSize setIntegerValue:0];
	}
}

- (IBAction)createRamdisk:(id)sender{
	//TODO: async mount/eject
	if( ![self isMounted] ){
		[self setRamdiskPath: ramdiskName];
		[self savePreferences];
		NSString *ns_cmd = [pathToMkRamdisk stringByAppendingFormat:@" %d \"%@\"", ramdiskSize,ramdiskName];
		if([isHidden integerValue])
			ns_cmd = [ns_cmd stringByAppendingString:@" hide"];
		NSLog(@"create ramdisk by: %@", ns_cmd);
		const char * cmd = [ns_cmd UTF8String]; 
		int ret = system(cmd);
		NSLog(@"Run mkramdisk.sh: %d", ret);		
		if(!ret){
			[self updateMountState: YES];
		}
		else{
			NSRunAlertPanel(@"Error", @"Creating ramdisk failed", @"OK", nil, nil);
			[sender setState:NSOffState];
		}
	}
	else{
		BOOL success = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:ramdiskPath];
		NSLog(@"eject ramdisk: %d", success);		
		if(success){
			[self updateMountState: NO];
		}
		else{
			NSRunAlertPanel(@"Error", @"Ejecting ramdisk failed", @"OK", nil, nil);
			[sender setState:NSOnState];
		}
	}
}

- (void)setRamdiskPath:(NSString *)path {
	ramdiskName = [path copy];
	ramdiskPath = [[NSString alloc] initWithFormat: @"/Volumes/%@", ramdiskName];
	[txt_ramdiskPath setStringValue:ramdiskName];
}

- (void)setRamdiskSize:(NSInteger)size {
	ramdiskSize = size;
	[txt_ramdiskSize setIntegerValue:size];
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView 
{
	return [syncItems count];
} 

- (id)tableView:(NSTableView *)aTableView 
			objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex 
{ 
    NSString *identifier = [aTableColumn identifier];
	NSMutableDictionary *item = [syncItems objectAtIndex:rowIndex];
	if ([identifier isEqualToString:@"use"]) {
		return [item objectForKey:@"enabled"];
	} else if([identifier isEqualToString:@"path"]) {
		return [item objectForKey:@"path"];
	} 
	else if([identifier isEqualToString:@"size"]) {
		return [item objectForKey:@"size"];
	}
    return nil; 
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex 
{ 
    NSString *identifier = [aTableColumn identifier]; 
	NSMutableDictionary *item = [syncItems objectAtIndex:rowIndex];
	if ([identifier isEqualToString:@"use"]) {
		[item setObject:[anObject copy] forKey:@"enabled"];
	} 
	else{
//		[item setPath:anObject];
//		[syncItems replaceObjectAtIndex:rowIndex withObject: anObject];
	}
} 

@end
