#import "Ride.h"

static NSDateFormatter *dateParserFormatter;
static NSDateFormatter *otherDateParserFormatter;

@implementation Ride

- (instancetype)initWithDictionary:(NSDictionary *)ride {
    self = [super init];
    if (self) {
        NSString *dateTimeString = [NSString stringWithFormat:@"%@ %@", ride[@"mydate"], ride[@"mytime"]];
        _date = [Ride dateFromString:dateTimeString];
        _neighborhood = ride[@"neighborhood"];
        _place = ride[@"place"];
        _route = ride[@"route"];
        _zone = ride[@"myzone"];
        _slots = [ride[@"slots"] unsignedIntValue];
        _notes = ride[@"description"];
        _hub = ride[@"hub"];
        _going = [ride[@"going"] boolValue];
        _rideID = [ride[@"rideId"] longValue];
        if (_rideID == 0) {
            _rideID = [ride[@"id"] longValue];
        }
        
        if (ride[@"driver"]) {
            NSError *error;
            User *driver = [MTLJSONAdapter modelOfClass:User.class fromJSONDictionary:ride[@"driver"] error:&error];
            if (!error) {
                _driver = driver;
            } else {
                NSLog(@"Error parsing driver from JSON. %@", error.localizedDescription);
            }
        }
        
        if (ride[@"riders"]) {
            NSError *error;
            NSArray<User *> *riders = [MTLJSONAdapter modelsOfClass:User.class fromJSONArray:ride[@"riders"] error:&error];
            if (!error) {
                _users = riders;
            } else {
                NSLog(@"Error parsing riders from JSON. %@", error.localizedDescription);
            }
        }
    }
    return self;
}

- (NSString *)title {
    if (_going) {
        return [NSString stringWithFormat:@"%@ → %@", _neighborhood, _hub];
    }
    else {
        return [NSString stringWithFormat:@"%@ → %@", _hub, _neighborhood];
    }
}

/**
 *  Parse date/time string to a NSDate object. The seconds are optional.
 *
 *  @param string Date/time string in the format 'yyyy-MM-dd HH:mm' or 'yyyy-MM-dd HH:mm:ss'.
 *
 *  @return date from the string.
 */
+ (NSDate *)dateFromString:(NSString *)string {
    NSDate *date;
    
    if (!dateParserFormatter) {
        dateParserFormatter = [[NSDateFormatter alloc] init];
        dateParserFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    
    date = [dateParserFormatter dateFromString:string];
    
    if (!date) {
        if (!otherDateParserFormatter) {
            otherDateParserFormatter = [[NSDateFormatter alloc] init];
            otherDateParserFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
        }
        
        date = [otherDateParserFormatter dateFromString:string];
    }
    
    return date;
}

@end
