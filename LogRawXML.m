//
//  LogRawXML.m
//  NSA
//
//  Created by Andrew Benson on 10/30/08.
//

#import "LogRawXML.h"


@implementation LogRawXML

-initWithPath: aPath
{
	if([self setPath: aPath] == nil) return nil;
	return [super init];
}

-setPath: aPath
{
	path = aPath;
	[aPath retain];
	file = fopen([aPath UTF8String], "w");
	if(file == NULL) { return nil; }
	return self;
}

-path
{
	return path;
}

-(void)writeXML: anElement
{
	fprintf(file, "%s\n", [anElement UTF8String]);
}

-(void)close
{
	fclose(file);
	[path release];
}

@end
