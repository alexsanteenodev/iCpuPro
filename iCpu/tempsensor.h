#import <Foundation/Foundation.h>

@interface TempSensor : NSObject

@property (strong, nonatomic) id temperature;

- (NSString*) getTemperature;
- (NSMutableString*) printValues;
+ (BOOL)showUnknownSensors;

@end
