//
//  ModuleManager.h
//
//  Created by Andrew Benson on 2008-09-21.
//

#import <Foundation/Foundation.h>

@interface ModuleManager : NSObject
{
	id moduleInfo;
	BOOL verified;
	uint aliveIndex, tcpIndex, udpIndex;
	
}

-initWithConfig: configFile;
-(BOOL)verified;

-(uint)moduleCount;

-baseDir;

-alivePath;
-tcpPath;
-udpPath;

-tcpPorts;
-udpPorts;

-modulesForTcp: port withAddress: address;
-modulesForUdp: port withAddress: address;

@end
