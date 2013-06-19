#import <Foundation/Foundation.h>
#import <stdarg.h>

@interface NSFileHandle (Select)
-(BOOL)hasDataAvailable;
@end

@interface NSMutableArray (Shuffle)
-shuffle;
@end

@interface NSMutableArray (Unique) 
-unique;
@end

@interface NSMutableString (Chop)
-chop;
@end

void LogIt(NSString *format, ...);
