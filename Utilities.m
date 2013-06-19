//
//  Utilities.m
//
//  Created by Andrew Benson on 2008-05-21.
//

#import <Foundation/Foundation.h>

#import "Utilities.h"

#import <stdarg.h>

void LogIt (NSString *format, ...)
{
    va_list args;
    va_start (args, format);
    NSString *string;
    string = [[NSString alloc] initWithFormat: format  arguments: args];
    va_end (args);
    printf ("%s\n", [string cStringUsingEncoding: NSASCIIStringEncoding]);
    [string release];
}

@implementation NSMutableArray (Shuffle)

-shuffle
{
	int i, len = [self count], r1, r2;
	for(i=0; i<len; i++) {
		r1 = random() % len;
		r2 = random() % len;
		[self exchangeObjectAtIndex: r1 withObjectAtIndex: r2];
	}
	return self;
}

@end

@implementation NSMutableArray (Unique) 

-unique
{
	int i, loc;
	id object;
	for(i=0; i<[self count]; i++) {
		object = [self objectAtIndex: i];
		while((loc = [self indexOfObject: object]) != NSNotFound) {
			[self removeObjectAtIndex: loc];
		}
		[self insertObject: object atIndex: 0];
	}
	return self;
}

@end

@implementation NSFileHandle (Select)

-(BOOL)hasDataAvailable
{
	int fd = -1;
	fd_set fds;
	struct timeval tv = {0, 0};
	fd = [self fileDescriptor];
	FD_ZERO(&fds);
	FD_SET(fd, &fds);
	if(select(fd+1, &fds, NULL, NULL, &tv) < 0) {
		return NO;
	}

	if(FD_ISSET(fd, &fds)) {
		return YES;
	} else {
		return NO;
	}
	return YES;
}

@end

@implementation NSMutableString (Chop)

-chop
{
	int i;
	for(i=0; i<[self length]; i++) {
		if(isspace([self characterAtIndex: i])) {
			[self deleteCharactersInRange: NSMakeRange(i, i+1)];
		}
	}
	return self;
}

@end
