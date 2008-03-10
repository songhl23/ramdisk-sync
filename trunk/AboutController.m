#import "AboutController.h"

@implementation AboutController

- (id)init
{
   NSLog(@"About init");
	[my_window setIsVisible:YES];
	return self;
}

- (void)windowDidLoad
{ 
    NSLog(@"About Nib file is loaded"); 
} 

@end
