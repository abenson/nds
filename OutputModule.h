//  OutputModule.h
//
//  Created by Andrew Benson on 2008-09-29.
//

@protocol OutputModule

/* Handling output from the modules of the scan. */
-(void)handleAliveOutput: aliveOutput;
-(void)handleTcpOutput: tcpOutput;
-(void)handleUdpOutput: udpOutput;
-(void)handleModuleOutput: moduleOutput;

/* Handling scanner start/stop events. */
-(void)scanBegan;
-(void)scanPaused;
-(void)scanResumed;
-(void)scanStopped;

/* Information on queues. */
-(void)handleQueueCounts: aDictionary;
@end
