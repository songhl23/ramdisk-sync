//
//  TargetItem.m
//  RamdiskSync
//
//  Created by vgod on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TargetItem.h"


@implementation TargetItem

+(TargetItem*)initWithPath: (NSString *)aPath{
	TargetItem *obj;
	if( obj = [TargetItem dictionary] ){
		[obj setObject:[aPath copy] forKey:@"path"];
		[obj setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
		NSLog(@"Set object: %@", [obj objectForKey:@"path"]);
//		enabled = [NSNumber numberWithBool:YES];
		//size = 0;
	}
	return obj;
}

-(void)dealloc {
//	[path release];
//	[enabled release];
	[super dealloc];
}

-(NSString *)getPath{
	NSLog(@"getPath");
	return (NSString *)[self objectForKey:@"path"];
//	return path;
}

-(NSNumber *)isEnabled{
	return (NSNumber *)[self objectForKey:@"enabled"];

		 //	return enabled;
}

-(void)setEnabled:(NSNumber *)num{
	[self setObject:[num copy] forKey:@"enabled"];

	//	enabled = [num copy];
}

@end
