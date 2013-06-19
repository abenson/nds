//
//  Scanner.m
//
//  Created by Andrew Benson on 2008-04-21.
//

#import "XmlParser.h"
#import "Utilities.h"
#import "Scheduler.h"
#import "Scanner.h"
#import "ModuleManager.h"
#import "LogRawXML.h"

@implementation Scanner

-initWithScannerConfig: scanConfig andModuleConfig: moduleConfig
{
	scheduler = [[Scheduler alloc] init];
	
	scannerConf = [scanConfig retain];
	moduleConf = [[ModuleManager alloc] initWithConfig: moduleConfig];

	outputModules = [[NSMutableArray alloc] init];

	// We're going to keep a list of tasks here for quick reference. 
	id cachedUdpPorts, cachedTcpPorts;
	id portEnum, port;

	// Build the TCP Tasks.
	cachedTcpPorts = [[moduleConf tcpPorts] retain];
	cachedTcpTasks = [[NSMutableArray alloc] init];
	portEnum = [cachedTcpPorts objectEnumerator];
	while(port = [portEnum nextObject]) {
		[cachedTcpTasks addObject:
		 [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		  @"TCP", @"Type", 
		  port, @"Port",
		  nil]];
	}
	[cachedTcpPorts release];
	
	// Now do the same for the UDP tasks.
	cachedUdpPorts = [[moduleConf udpPorts] retain];
	cachedUdpTasks = [[NSMutableArray alloc] init];
	portEnum = [cachedUdpPorts objectEnumerator];
	while(port = [portEnum nextObject]) {
		[cachedUdpTasks addObject:
		 [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		  @"UDP", @"Type", 
		  port, @"Port",
		  nil]];
	}
	[cachedUdpPorts release];
	
	[scheduler setHostInterval: [[scannerConf objectForKey: @"HostInterval"] doubleValue]];
	
	inAlives = inTcps = inUdps = inExploits = 0;
	
	isRunning = NO;
	isPaused = NO;

	currentAlive = currentTcp = currentUdp = 0;
	alives = tcps = udps = nil;
	
	return [super init];
}

-setupScan
{
	// Go ahead and set the scanners.
	[self setAliveScanners: [[scannerConf objectForKey:@"AliveScanners"] intValue]];
	[self setTcpScanners: [[scannerConf objectForKey:@"TcpScanners"] intValue]];
	[self setUdpScanners: [[scannerConf objectForKey:@"UdpScanners"] intValue]];

	return self;
}

-(uint32_t)maxJobs
{
	return [scheduler hostCount] * ([cachedUdpTasks count] + [cachedTcpTasks count] + 1);
}

-(void)dealloc
{	
	[cachedTcpTasks release];
	[cachedUdpTasks release];
		
	[scheduler release];
	
	[scannerConf release];
	[moduleConf release];
	
	[outputModules release];

	[super dealloc];
}

-setLog: aPath
{
	logXml = [[LogRawXML alloc] initWithPath: aPath];
	return logXml;
}

-addOutputModule: aModule
{
	[outputModules addObject: aModule];
	return self;
}

// The heart of the scanners self-preservation. 
-(void)schedule
{
	if([self shouldBeRunning] == NO) {
		return;
	}
	[self performSelector: @selector(processTask) withObject: nil afterDelay: 0.0];
}

-setAliveScanners: (int)count
{
	int i;
	id task;
	
	// This is the easiest way I can think to handle this event during a scan.
	if(alives) {
		[self pauseScan]; // Pause the scanner.
		[alives release]; // Kill the tasks.
	}
	
	// Build the new programs, and start them.
	alives = [[NSMutableArray alloc] init];
	for(i=0; i < count; i++) {
		task = [[NSTask alloc] init];
		[task setLaunchPath: [moduleConf alivePath]];
		[task setStandardInput: [NSPipe pipe]];
		[task setStandardOutput: [NSPipe pipe]];
		[task launch];
		[alives addObject: task];
		[task release];
	}
	
	// Resume the scan!
	if(isRunning) {
		[self resumeScan];
	}
	
	return self;
}


// This follows the same format as the previous one. 
// Might look into replacing them and making one generic one.
-setUdpScanners: (int)count
{
	int i;
	id task;
	
	if(isRunning) {
		[self pauseScan];
		[alives release];
	}
		
	udps = [[NSMutableArray alloc] init];
	for(i=0; i < count; i++) {
		task = [[NSTask alloc] init];
		[task setLaunchPath: [moduleConf udpPath]];
		[task setStandardInput: [NSPipe pipe]];
		[task setStandardOutput: [NSPipe pipe]];
		[task launch];
		[udps addObject: task];
		[task release];
	}
	
	if(isRunning) {
		[self resumeScan];
	}
	
	return self;
}

// And this is why.
-setTcpScanners: (int)count
{
	int i;
	id task;
	
	if(isRunning) {
		[self pauseScan];
		[alives release];
	}
	
	tcps = [[NSMutableArray alloc] init];
	for(i=0; i < count; i++) {
		task = [[NSTask alloc] init];
		[task setLaunchPath: [moduleConf tcpPath]];
		[task setStandardInput: [NSPipe pipe]];
		[task setStandardOutput: [NSPipe pipe]];
		[task launch];
		[tcps addObject: task];
		[task release];
	}
	
	if(isRunning) {
		[self resumeScan];
	}

	return self;
}

// This family actually handle the writing to the queues.
-aliveScan: aHost
{
	inAlives++;
	// We get the standard input of the NSTask, and write raw data to it. 
	[[[[alives objectAtIndex: currentAlive] standardInput] fileHandleForWriting] writeData: 
		[[NSString stringWithFormat: @"%@\n", aHost] dataUsingEncoding:NSASCIIStringEncoding]];
	// We then advance to the next module, so they all get some love.
	if([alives count] <= ++currentAlive) {
		currentAlive = 0;
	}
	return self;
}

-udpScan: aHost port:(int)port
{
	inUdps++;
	[[[[udps objectAtIndex: currentUdp] standardInput] fileHandleForWriting] writeData: 
		[[NSString stringWithFormat: @"%@ %d\n", aHost, port] dataUsingEncoding:NSASCIIStringEncoding]];
	if([udps count] <= ++currentUdp) {
		currentUdp = 0;
	}
	return self;
}

-tcpScan: aHost port:(int)port
{
	inTcps++;
	[[[[tcps objectAtIndex: currentTcp] standardInput] fileHandleForWriting] writeData: 
		[[NSString stringWithFormat: @"%@ %d\n", aHost, port] dataUsingEncoding:NSASCIIStringEncoding]];
	if([tcps count] <= ++currentTcp) {
		currentTcp = 0;
	}
	return self;
}

// Fairly straight-forward.
-loadIPList: anArray
{
	[scheduler seedAlives: anArray];
	return self;
}

-handleAliveOutputs
{
	id enumer, alive, string;
	id address;
	id stringEnum, rawOutput;
	XmlParser *parser;
		
	// We want to verify ALL output. So we flip through each module, grab all of their input.
	// We then break it apart into multiple rows, since all output is newline terminated.
	// We can then parse it all.
	enumer = [alives objectEnumerator];
	while((alive = [enumer nextObject])) {
		if([[[alive standardOutput] fileHandleForReading] hasDataAvailable] == YES) {
			rawOutput =  [[[alive standardOutput] fileHandleForReading] availableData];
			stringEnum = [[[[NSString alloc] initWithData: rawOutput encoding: NSASCIIStringEncoding] 
				componentsSeparatedByString: @"\n"] objectEnumerator];
			while(string = [stringEnum nextObject]) {
				if([string isEqual: @""]) continue;
				inAlives--;
				// Right now we use my custom parser. When we get into real XML, we'll probably
				// take the (slower, faster) approach of using NSXMLParser. 
				parser = [[XmlParser alloc] initWithString: string];
				address = [[[parser dataForElement:@"IP"] retain] autorelease];
				
				// Pipe the output to ALL of the modules.
				[outputModules makeObjectsPerformSelector: @selector(handleAliveOutput:)
					withObject: [parser dictionary]];

				// This is separate, but we should keep a log of the output, if we can.
				[logXml writeXML: string];
				
				// If the result was that the IP was alive, we need to schedule more jobs.
				if([[parser dataForElement:@"STATUS"] isEqual: @"ALIVE"]) {
					id taskEnum, task;
					
					// Schedule all of the TCP tasks.
					taskEnum = [cachedTcpTasks objectEnumerator];
					while(task = [taskEnum nextObject]) {
						// This was the quickest way I could think of -- just need to change the address, 
						// make a copy, and then throw it in the queue.
						[task setObject: address forKey: @"Address"];
						[scheduler addTask: [task copy]];
					}

					// And then schedule all of the UDP tasks.
					taskEnum = [cachedUdpTasks objectEnumerator];
					while(task = [taskEnum nextObject]) {
						// Same thought process.
						[task setObject: address forKey: @"Address"];
						[scheduler addTask: [task copy]];
					}

					// I want to make sure that when I grab a task, it's not in the same order as another host.
					[scheduler shuffleTasksForHost: address];
				}
				[parser release];
			}
		}
	}
	
	return self;
}

// Same thought process as before.
-handleTcpOutputs
{
	id enumer, tcp, string, rawOutput, stringEnum;
	XmlParser *parser;
	enumer = [tcps objectEnumerator];
	while((tcp = [enumer nextObject])) {
		if([[[tcp standardOutput] fileHandleForReading] hasDataAvailable] == YES) {
			rawOutput = [[[tcp standardOutput] fileHandleForReading] availableData];
			stringEnum = [[[[NSString alloc] initWithData: rawOutput encoding: NSASCIIStringEncoding] componentsSeparatedByString: @"\n"] objectEnumerator];
			while(string = [stringEnum nextObject]) {
				if([string isEqual: @""]) {
					continue;
				}
				[logXml writeXML: string];
				inTcps--;
				parser = [[XmlParser alloc] initWithString: string];
				[outputModules makeObjectsPerformSelector: @selector(handleTcpOutput:)
					withObject: [parser dictionary]];
				[parser release];
			}
		}
	}
	return self;
}

// One more time!
-handleUdpOutputs
{
	id enumer, udp, string, rawOutput, stringEnum;
	XmlParser *parser;
	enumer = [udps objectEnumerator];
	while((udp = [enumer nextObject])) {
		if([[[udp standardOutput] fileHandleForReading] hasDataAvailable] == YES) {
			rawOutput = [[[udp standardOutput] fileHandleForReading] availableData];
			stringEnum = [[[[NSString alloc] initWithData: rawOutput encoding: NSASCIIStringEncoding] componentsSeparatedByString: @"\n"] objectEnumerator];
			while(string = [stringEnum nextObject]) {
				if([string isEqual: @""]) continue;
				[logXml writeXML: string];
				inUdps--;
				parser = [[XmlParser alloc] initWithString: string];
				[outputModules makeObjectsPerformSelector: @selector(handleUdpOutput:)
					withObject: [parser dictionary]];
				[parser release];
			}
		}
	}
	return self;
}

// Handle all of the previous ones. This is mostly for code prettification.
-handleOutputs
{
	[self handleAliveOutputs];
	[self handleTcpOutputs];
	[self handleUdpOutputs];
	return self;
}

-(BOOL)hasTasksBeingProcessed
{
	return (inAlives>0) || (inTcps>0) || (inUdps>0);
}

// This is the part that does everything. This gets executed a lot, but calls all of the other code.
-(void)processTask {
	id task;
	int i;

	// We want to handle outputs as soon as possible, get them out of the buffers of the modules.
	[self handleOutputs];

	// Now we check for more jobs from the scheduler. If we don't have more jobs, just bail now.
	if(![scheduler hasJobs] && ![self hasTasksBeingProcessed]) {
		[outputModules makeObjectsPerformSelector: @selector(scanFinished)];
		[logXml close];
		isRunning = NO;
		return;
	}
	
	// These next bits fill up the scanners we have. We throw a job for each one, if we can.
	for(i=0; i<[alives count]; i++) {
		if(task = [scheduler nextTaskOfType: @"Alive"]) {
			[self aliveScan: [task objectForKey: @"Address"]];
		} else {
			break;
		}
	}
	
	for(i=0; i<[tcps count]; i++) {
		if(task = [scheduler nextTaskOfType: @"TCP"]) {
			[self tcpScan: [task objectForKey: @"Address"] port: [[task objectForKey: @"Port"] intValue]];
		} else {
			break;
		}
	}
	
	for(i=0; i<[udps count]; i++) {
		if(task = [scheduler nextTaskOfType: @"UDP"]) {
			[self udpScan: [task objectForKey: @"Address"] port: [[task objectForKey: @"Port"] intValue]];
		} else {
			break;
		}
	}

	// We keep running, since we 1) have jobs in the queue 2) have jobs being processed.
	[self schedule];
}

-(BOOL)shouldBeRunning
{
	return isRunning && !isPaused;
}

// This is used for periodic status updates. It's called by an NSTimer.
-(void)status
{
	[outputModules makeObjectsPerformSelector: @selector(handleQueueCounts:)
		withObject: [scheduler taskCounts]];
}


// Setup the scan, start the status timer, put us in the schedule, set our status,
// tell everyone we're starting.
-beginScan
{
	[self setupScan];
	[NSTimer scheduledTimerWithTimeInterval: 5.0 
		target: self 
		selector: @selector(status)
		userInfo: nil
		repeats: YES];
	isRunning = YES;
	isPaused = NO;
	[self schedule];
	[outputModules makeObjectsPerformSelector: @selector(scanBegan)];
	return self;
}

// Cancel our method if its in the queue. This won't affect any method that is currently being executed ...
-stopScan
{
	[[NSRunLoop currentRunLoop] 
		cancelPerformSelector: @selector(processTask)
		target: self
		argument: nil];
	isRunning = NO;
	isPaused = NO;
	
	[outputModules makeObjectsPerformSelector: @selector(scanStopped)];
	return self;
}

// Cancel the scanner, but don't mark us as being stopped. Effectively, there's little else.
-pauseScan
{
	[[NSRunLoop currentRunLoop] 
		cancelPerformSelector: @selector(processTask)
		target: self
		argument: nil];
	isRunning = YES;
	isPaused = YES;
	[outputModules makeObjectsPerformSelector: @selector(scanPaused)];
	return self;
}

// We're already setup, so we just have to mark us as scanning, and schedule.
-resumeScan
{
	isRunning = YES;
	isPaused = NO;
	[self schedule];
	[outputModules makeObjectsPerformSelector: @selector(scanResumed)];
	return self;
}

@end 
