#import "tempsensor.h"
#import "XRGCPUMiner.h"
#import "XRGTemperatureMiner.h"
#import "definitions.h"
#include <sys/sysctl.h>

#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

// Declarations from other IOKit source code

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
int IOHIDEventSystemClientSetMatchingMultiple(IOHIDEventSystemClientRef client, CFArrayRef match);

#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature  15
#define kIOHIDEventTypePower        25


@implementation TempSensor

- (BOOL)showUnknownSensors {
    BOOL showUnknown = [[NSUserDefaults standardUserDefaults] boolForKey:XRG_tempShowUnknownSensors];
    
    // show all unnamed sensors if very few are known
    showUnknown |= [XRGTemperatureMiner shared].smcSensors.knownTemperatureKeys.count < 10;

    return showUnknown;
}

// calculate average CPU temperature of all cores
- (NSString *)averageTemperatureFromArray:(NSArray *)temperaturesArray {
    
    NSArray *sortedArray = [temperaturesArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double temp1 = [obj1 doubleValue];
        double temp2 = [obj2 doubleValue];
        if (temp1 < temp2) {
            return NSOrderedDescending;
        } else if (temp1 < temp2) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    NSArray *slicedArray = [sortedArray subarrayWithRange:NSMakeRange(0, 3)];
    
    
    double sum = 0;
    double count = 0;
    for (NSNumber *temperature in slicedArray) {
        if(temperature >0 ){
            sum += [temperature doubleValue];
            count = count+1;
        }

    }
    double average = sum / slicedArray.count;

    
    double roundedUpTemp = ceil(average);
    
    int averageInt = (int) roundedUpTemp;
    
    NSString *resultString = [NSString stringWithFormat:@"%d°C", averageInt];
    return resultString;
}

// create a dict ref, like for temperature sensor {"PrimaryUsagePage":0xff00, "PrimaryUsage":0x5}
CFDictionaryRef matching(int page, int usage)
{
    CFNumberRef nums[2];
    CFStringRef keys[2];

    keys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
    keys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);
    nums[0] = CFNumberCreate(0, kCFNumberSInt32Type, &page);
    nums[1] = CFNumberCreate(0, kCFNumberSInt32Type, &usage);

    CFDictionaryRef dict = CFDictionaryCreate(0, (const void**)keys, (const void**)nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return dict;
}

// get thermal value
CFArrayRef getThermalValues(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system);

    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0); // here we use ...CopyEvent

        CFNumberRef value;
        if (event != 0) {
            double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        } else {
            double temp = 0;
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        }
        CFArrayAppendValue(array, value);
    }
    return array;
}

NSArray* returnThermalValues(void) {
    // thermalSensors's PrimaryUsagePage should be 0xff00 for M1 chip, instead of 0xff05
    CFDictionaryRef currentSensors = matching(0xff00, 5);
    return CFBridgingRelease(getThermalValues(currentSensors));
}

- (NSString *)getTemperature {
    
    NSArray *thermalValuesArray = returnThermalValues();
    
//    NSLog(@"%@", thermalValuesArray);

    NSString *resultString = [self averageTemperatureFromArray:thermalValuesArray];
    
    return resultString;
}

- (NSMutableString *) printValues {
    // Copy text to a clipboard.
        NSMutableString *copyText = [[NSMutableString alloc] init];

        NSString *appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        if (!appVersion) appVersion = @"";
        [[XRGTemperatureMiner shared] reset];
    
        [[XRGTemperatureMiner shared] updateCurrentTemperatures:[self showUnknownSensors]];
    
        [copyText appendFormat:@"XRG %@\n", appVersion];
        [copyText appendFormat:@"Mac model: %@\n", [XRGCPUMiner systemModelIdentifier]];
        [copyText appendFormat:@"Running macOS %@\n\n", [[NSProcessInfo processInfo] operatingSystemVersionString]];
        [copyText appendString:@"Discovered Sensors:\n"];

        for (NSString *sensorKey in [[XRGTemperatureMiner shared] locationKeysIncludingUnknown:YES]) {
            
            XRGSensorData *sensor = [[XRGTemperatureMiner shared] sensorForLocation:sensorKey];

            [copyText appendFormat:@"\t%@:  %.1f\n", sensor.label, sensor.currentValue];
        }

//         NSLog(@"%@", copyText);
    return copyText;
    }

@end





