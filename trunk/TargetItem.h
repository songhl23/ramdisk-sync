//
//  TargetItem.h
//  RamdiskSync
//
//  Created by vgod on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TargetItem : NSMutableDictionary {
//	NSString *path;
//	NSNumber *enabled;
	
//	BOOL enabled;
//	int size;
}
+(TargetItem *)initWithPath: (NSString *)aPath;

-(NSString *)getPath;

-(NSNumber *)isEnabled;
-(void)setEnabled:(NSNumber *)num;

@end
