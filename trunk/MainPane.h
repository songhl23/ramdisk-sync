#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <CoreFoundation/CoreFoundation.h>
//#import "TargetItem.h"

@interface MainPane : NSPreferencePane {
    IBOutlet id targetView;
    IBOutlet id txt_ramdiskPath;
    IBOutlet id txt_ramdiskSize;
    IBOutlet id txt_ramdiskFreeSize;
    IBOutlet id lvl_ramdiskFreeSize;
    IBOutlet id chk_isHidden;
    IBOutlet id chk_isCopyDir;
    IBOutlet id chk_autoMount;
	IBOutlet id btn_mountEject;
	IBOutlet id win_about;
	
	NSString *ramdiskName;
	NSString *ramdiskPath;
	NSInteger ramdiskSize;
	NSNumber *isHidden;
	NSNumber *isCopyDir;
	NSNumber *autoMount;
	NSMutableArray *syncItems;
	
	CFStringRef appID;
	NSString *pathToMkRamdisk;
	NSString *pathToObserver;
}
- (IBAction)setAutoMount:(id)sender;
- (IBAction)addTarget:(id)sender;
- (IBAction)delTarget:(id)sender;
- (IBAction)changeRDVol:(id)sender;
- (IBAction)createRamdisk:(id)sender;
- (IBAction)showHelpWindow:(id)sender;
- (IBAction)closeHelpWindow:(id)sender;

- (void)sheetDidEnd:(NSWindow *)sheet 
		 returnCode:(int)returnCode 
		contextInfo:(void *)contextInfo; 

- (BOOL)startObserver;
- (void)mainViewDidLoad;
- (void)setupDefaultSyncItems;
- (void)savePreferences;
- (void)addSyncItem: (NSString*)filename;
- (void)setRamdiskPath:(NSString *)path;
- (void)setRamdiskSize:(NSInteger)size;
- (NSNumber*) getRamdiskFreeSize;
- (NSInteger) getRamdiskFreePercent;
- (BOOL)isMounted;
- (void)updateMountState: (BOOL)mounted;

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView 
			objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(int)rowIndex;

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex;

- (NSNumber *)getFileSize:(NSString *)filepath;

@end
