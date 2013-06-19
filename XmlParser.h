//
//  XmlParse.h
//
//  Created by Andrew Benson on 2008-05-21.
//

#import <Foundation/Foundation.h>

@interface XmlParser : NSObject
{
	NSMutableDictionary *elements;
	NSString *rootElement;
}

-initWithString: aString;

-dictionary;

-(NSString*)rootName;
-(NSString*)dataForElement: elementName;

@end


