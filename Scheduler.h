//
//  Scheduler.h
//
//  Created by Andrew Benson on 2008-05-3.
//

#import <Foundation/Foundation.h>

@interface Scheduler : NSObject
{
	id groups;
	NSTimeInterval hostInterval;
	id counts;
}

// This is a two-fold operation. It tells the scanner what hosts we'll
// be scheduling for, and does some basic setup for them. We shouldn't
// add tasks for a host unless they've been properly setup with this
// method first.
-seedAlives: anArray;

// This tells the scanner to not a grab a host that's been touched in 
// less than interval seconds.
-setHostInterval: (NSTimeInterval)interval;

// Add a task.
-addTask: aTask;

// Fetch a task.
-nextTaskOfType: aType;

// Do we have jobs in the queue?
-(BOOL)hasJobs;

// This returns a count of the hosts being scanned.
-(uint32_t)hostCount;

// This returns a dictionary of the tasks in the queues.
-taskCounts;

// This will shuffle the tasks array for a given host.
-shuffleTasksForHost: aHost;

@end
