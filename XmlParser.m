//
//  XmlParse.m
//
//  Created by Andrew Benson on 2008-05-21.
//

#import <Foundation/Foundation.h>
#import "XmlParser.h"
#import "Utilities.h"

@implementation XmlParser

-(void)dealloc
{
	[elements release];
	[rootElement release];
	[super dealloc];
}

-dictionary
{
	return elements;
}

-(NSMutableDictionary*) parseString: aString
{
	id tags, tag, data, elem, dict;
	[aString retain];
	tags = [[aString componentsSeparatedByString: @"><"] objectEnumerator];
	[aString release];
	dict = [[[NSMutableDictionary alloc] init] autorelease];
	rootElement = [[[[tags nextObject] componentsSeparatedByString: @"<"] objectAtIndex: 1] retain];
	while((tag = [tags nextObject])) {
		if([tag characterAtIndex: 0] == '/') break;
		data = [tag componentsSeparatedByString:@">"];
		[data retain];
		elem = [data objectAtIndex: 0];
		[dict setObject: [[[data objectAtIndex: 1] componentsSeparatedByString: @"<"] objectAtIndex: 0] forKey: elem];
		[data release];
	}
	return dict;
}

-initWithString: aString
{
	elements = [[self parseString: aString] retain];
	return [super init];
}

-(NSString*)rootName
{
	return rootElement;
}

-(NSString*)dataForElement: elementName
{
	return [elements objectForKey: elementName];
}

@end
