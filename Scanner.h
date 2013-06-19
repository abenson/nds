//
//  Scanner.h
//
//  Created by Andrew Benson on 2008-04-21.
//

#import <Foundation/Foundation.h>

#import "Scheduler.h"

@interface Scanner : NSObject
{
	id scheduler;
	id scannerConf, moduleConf;

	// These are the actual NSTasks that we use to run the modules.
	id alives, tcps, udps, exploits;
	
	int inAlives, inTcps, inUdps, inExploits;
	
	// This is to keep track of which module we need to talk to next.
	// It's mostly so we can loop around and talk to each module once
	// before we talk to it again.
	int currentAlive, currentTcp, currentUdp;

	// NSArray of objets implementing <OutputModule>.
	// We send updates to them for key events.
	id outputModules;	
	id logXml;
	
	// Speed hack to avoid building the list of tasks to scan multiple times.
	id cachedUdpTasks, cachedTcpTasks;
	
	// Internal scan state information. These are combined to form -shouldBeRunning.
	BOOL isRunning, isPaused;
}

// Fairly straight-forward.
-initWithScannerConfig: scanConfig andModuleConfig: moduleConfig;

// A list of IP addresses as strings.
-loadIPList: anArray;


// An object implementing <OutputModule>, expecting to receive status
// updates as the scanner deems necessary. 
// We easily handle multiple output objects. So effectively, you could have
// one for database, one for displaying to the screen, and one to log raw 
// data to a file. Or whatever you want. It's your choice.
-addOutputModule: aModule;
-setLog: aPath;

// This is mostly a hack for tools that have their own run loop. This won't be
// necessary for AppKit based scanners, as their runloop will always be firing.
// For the rest, we need a way of saying, HEY WAIT, I still need to run.
-(BOOL)shouldBeRunning;

// This will be for tweaking scanners at runtime. Ideally, we'll have a way to 
// slow down the scan, or speed it up. 
-setAliveScanners: (int)scanners;
-setTcpScanners: (int)count;
-setUdpScanners: (int)count;

// Returns the maximum number of jobs possible.
-(uint32_t)maxJobs;

// Control messages for the scanner. They're mostly self-explanatory. 
-beginScan;
-stopScan;
-pauseScan;
-resumeScan;

@end
