//
//  ModuleManager.m
//
//  Created by Andrew Benson on 2008-09-21.
//

#import "ModuleManager.h"
#import "Utilities.h"

@implementation ModuleManager

-(BOOL)verifyConfig
{
	int i;
	BOOL haveBasedir = NO; /* basedir should *always* be at index 0 */
	aliveIndex = tcpIndex = udpIndex = 0;	/* this makes lookups later on quicker */
	
	if([[moduleInfo objectAtIndex:0] objectForKey: @"modulesdir"] != nil) {
		haveBasedir = YES;
	} else {
		return NO;
	}
	
	for(i=1; i<[moduleInfo count]; i++) {
		if([[[moduleInfo objectAtIndex: i] objectForKey: @"class"] isEqual: @"alive"]) {
			if(aliveIndex > 0) {
				return NO;
			} else {
				aliveIndex = i;
			}
		} else if([[[moduleInfo objectAtIndex: i] objectForKey: @"class"] isEqual: @"tcp"]) {
			if(tcpIndex > 0) {
				return NO;
			} else {
				tcpIndex = i;
			}
		} else if([[[moduleInfo objectAtIndex: i] objectForKey: @"class"] isEqual: @"udp"]) {
			if(udpIndex > 0) {
				return NO;
			} else {
				udpIndex = i;
			}
		}
 	}
	return haveBasedir && aliveIndex && tcpIndex && udpIndex;
}

-initWithConfig: aConfig
{
	verified = NO;
	moduleInfo = [aConfig copy];
	verified = [self verifyConfig];
	return [super init];
}

-(uint)moduleCount
{
	return [moduleInfo count];
}

-baseDir
{
	return [[moduleInfo objectAtIndex:0] objectForKey: @"modulesdir"];
}

-alivePath
{
	return [NSString stringWithFormat: @"%@/%@", [self baseDir], [[moduleInfo objectAtIndex:aliveIndex] objectForKey: @"command"]];
}

-tcpPath
{
	return [NSString stringWithFormat: @"%@/%@", [self baseDir], [[moduleInfo objectAtIndex:tcpIndex] objectForKey: @"command"]];
}

-udpPath
{
	return [NSString stringWithFormat: @"%@/%@", [self baseDir], [[moduleInfo objectAtIndex:udpIndex] objectForKey: @"command"]];
}

-portsForProtocol: aProtocol
{
	int i;
	id module, list;
	list = [NSMutableArray array];
	for(i=1; i<[moduleInfo count]; i++) {
		if([[[moduleInfo objectAtIndex: i] objectForKey: @"class"] isEqual: @"module"]) {
			module = [moduleInfo objectAtIndex: i];
			if([[module objectForKey: @"protocol"] isEqual: aProtocol]) {
				[list addObject: [module objectForKey: @"port"]];
			}
		}
	}
	[list unique];
	return list;
}

-modulesForProtocol: aProtocol andPort: port withAddress: address
{
	int i;
	id list;
	list = [NSMutableArray array];
	for(i=1; i<[moduleInfo count]; i++) {
		if([[[moduleInfo objectAtIndex: i] objectForKey: @"class"] isEqual: @"module"]) {
			if([[[moduleInfo objectAtIndex: i] objectForKey: @"protocol"] isEqual: aProtocol] && 
					[[[moduleInfo objectAtIndex: i] objectForKey: @"port"] isEqual: port]) {
				id path = [NSMutableString stringWithFormat: @"%@/%@", [self baseDir], [[moduleInfo objectAtIndex: i] objectForKey: @"command"]];
				
				[path replaceOccurrencesOfString: @"$(protocol)"
					withString: [[moduleInfo objectAtIndex: i] objectForKey: @"protocol"]
					options: NSLiteralSearch
					range: NSMakeRange(0, [path length])];
					
				[path replaceOccurrencesOfString: @"$(port)"
					withString: [[moduleInfo objectAtIndex: i] objectForKey: @"port"]
					options: NSLiteralSearch
					range: NSMakeRange(0, [path length])];
					
				[path replaceOccurrencesOfString: @"$(address)"
					withString: address
					options: NSLiteralSearch
					range: NSMakeRange(0, [path length])];
				
				[list addObject: path];
			}
		}
	}
	return list;
}

-modulesForTcp: port withAddress: address 
{
	return [self modulesForProtocol: @"tcp" andPort: port withAddress: address];
}

-modulesForUdp: port withAddress: address
{
	return [self modulesForProtocol: @"udp" andPort: port withAddress: address];
}

-tcpPorts
{
	return [self portsForProtocol: @"tcp"];
}

-udpPorts
{
	return [self portsForProtocol: @"udp"];
}

-(BOOL)verified
{
	return verified;
}

@end
