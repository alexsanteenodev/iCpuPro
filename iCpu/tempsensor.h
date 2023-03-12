#import <Foundation/Foundation.h>

@interface TempSensor : NSObject

@property (strong, nonatomic) id temperature;

- (NSInteger) getTemperature;

@end
