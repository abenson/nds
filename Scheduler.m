//
//  Scheduler.m
//
//  Created by Andrew Benson on 2008-05-3.
//

#import <Foundation/Foundation.h>

#import "Utilities.h"
#import "Scheduler.h"

@implementation Scheduler

-init
{
	// We plan for a class B network.
	// Our dictionary is keyed on hosts. This gives us "buckets", one bucket
	// per host. This helps with scheduling, as it makes it easier to look up
	// a host, and to keep a host from being hit too many times in a row.
	groups = [[NSMutableDictionary alloc] initWithCapacity: 65536];
	
	// We keep a count of modules in the array for quickly deciding how many
	// we have scheduled. 
	counts = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt: 0], @"Module",
		[NSNumber numberWithUnsignedInt: 0], @"TCP",
		[NSNumber numberWithUnsignedInt: 0], @"UDP",
		[NSNumber numberWithUnsignedInt: 0], @"Alive",
		nil
	];
	
	return [super init];
}

-setHostInterval: (NSTimeInterval) interval
{
	hostInterval = interval;
	return self;
}

-taskCounts
{
	return counts;
}

-seedAlives: anArray
{
	id enumerator, task, host, group;
	unsigned int count = 0;
	enumerator = [anArray objectEnumerator];
	while((host = [enumerator nextObject])) {
		if([host isEqual:@""]) { 
			continue; // This is a hack in case we get empty strings (it happens...)
		} 
		task = [NSDictionary dictionaryWithObjectsAndKeys: 
			@"Alive", @"Type", 
			host, @"Address",
			nil];
		group = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSMutableArray arrayWithObject: task], @"Tasks",
			[NSDate dateWithTimeIntervalSince1970:0.0], @"Touched",
			nil];
		count++;
		// This may seem redundant ... we set the address in the task, and are setting
		// it here. This is for convenience. 
		[groups setObject: group forKey: host];
	}
	[counts setObject: [NSNumber numberWithUnsignedInt: count] forKey: @"Alive"];
	return self;
}

// Add a task, update its count.
-addTask: aTask
{
	unsigned int count;
	[aTask retain];
	[[[groups objectForKey: [aTask objectForKey: @"Address"]]  objectForKey: @"Tasks"] addObject: aTask];
	count = [[counts objectForKey: [aTask objectForKey: @"Type"]] unsignedIntValue];
	// Update the count.
	[counts setObject: [NSNumber numberWithUnsignedInt: count + 1] forKey: [aTask objectForKey: @"Type"]];
	[aTask release];
	return self;
}

-(uint32_t)hostCount
{
	return [groups count];
}

-shuffleTasksForHost: aHost
{
	// -shuffle is a little diddy I wrote just for this.
	[[[groups objectForKey: aHost] objectForKey: @"Tasks"] shuffle];
	return self;
}

-nextTaskOfType: aType
{
	id group, groupEnum, taskEnum, task = nil;
	unsigned int count;

	// We're going to need to update the count, so we can grab it now.
	count = [[counts objectForKey: aType] unsignedIntValue];

	// If there are no objects of this type, we return nil. 
	if(count == 0) {
		return nil;
	}

	groupEnum = [groups keyEnumerator];
	while(group = [groups objectForKey: [groupEnum nextObject]]) {
		
		// If we're not past that time threshold, we need to just skip that host. 
		if(([[group objectForKey: @"Touched"] timeIntervalSinceNow] * -1) < hostInterval) {
			continue;
		}
		
		// Check all of the tasks for one that matches the type we want. 
		taskEnum = [[group objectForKey: @"Tasks"] objectEnumerator];
		while(task = [taskEnum nextObject]) {
			if([[task objectForKey:@"Type"] isEqual: aType]) {
				[[task retain] autorelease];
				[[group objectForKey: @"Tasks"] removeObject: task];
				[group setObject: [NSDate date] forKey: @"Touched"];
				break;
			}
		}
		
		// If we didn't find a task, try again.
		if(task == nil) {
			continue;
		}

		// Update the count.
		[counts setObject: [NSNumber numberWithUnsignedInt: count - 1] forKey: aType];
				
		return task;
	}
	
	return nil;
}

// This checks all of the counts for the queues.
-(BOOL)hasJobs
{
	id count, enumer;
	enumer = [counts keyEnumerator];
	while(count = [enumer nextObject]) {
		if([[counts objectForKey: count] unsignedIntValue] > 0) {
			return YES;
		}
	}
	return NO;
}

@end
