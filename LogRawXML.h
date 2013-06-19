//
//  LogRawXML.h
//  NSA
//
//  Created by Andrew Benson on 10/30/08.
//

#import <Cocoa/Cocoa.h>

@interface LogRawXML : NSObject {
	FILE *file;
	id path;
}

-initWithPath: aPath;

-path;
-setPath: aPath;

-(void)writeXML: anElement;

-(void)close;

@end
