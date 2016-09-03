//
//  SW_smugAwarePlaneObject.m
//  beaconinventory
//
//  Created by Clarence Fields on 3/8/16.
//  Copyright © 2016 Buzztouch. All rights reserved.
//

#import "SW_smugAwarePlaneObject.h"

@implementation SW_smugAwarePlaneObject

//
@synthesize coordinate;
@synthesize title;
@synthesize subtitle;
//
@synthesize flightNumber;
@synthesize flightDetails;
@synthesize listIndex;
@synthesize hex;
@synthesize squawk;
@synthesize lat;
@synthesize lon;
@synthesize validPosition;
@synthesize altitude;
@synthesize vert_rate;
@synthesize track;
@synthesize validTrack;
@synthesize speed;
@synthesize messages;
@synthesize seen;
@synthesize mlat;

-(id)initWithCoordinate:(CLLocationCoordinate2D) c {
    [BT_debugger showIt:self message:[NSString stringWithFormat:@"Coordinates: %f,%f", c.latitude, c.longitude]];
    self = [super init];
    if(self) {
        self.coordinate = c;
    }
    return self;
}

-(id) initWithTitle:(NSString *)myTitle AndCoordinate:(CLLocationCoordinate2D)myCoordinate{
    self = [super init];
    if(self) {
        title = myTitle;
        coordinate = myCoordinate;
    }
    return self;
}

-(id) initWithTitle:(NSString *)myTitle AndSubTitle:(NSString *)mySubTitle AndCoordinate:(CLLocationCoordinate2D)myCoordinate {
    self = [super init];
    if (self) {
        title = myTitle;
        subtitle = mySubTitle;
        coordinate = myCoordinate;
    }
    return self;
}

-(id) initWithFlightNum:(NSString *)myFlightNumber AndDetails:(NSDictionary *)myFlightDictionary {
    self = [super init];
    if (self) {
        //         listIndex = [myFlightDictionary objectForKey:@"listIndex"];
        flightNumber = myFlightNumber;
        flightDetails = [myFlightDictionary objectForKey:@"flightDetails"];
        hex = [myFlightDictionary objectForKey:@"hex"];
        squawk = [myFlightDictionary objectForKey:@"squawk"];
        lat = [myFlightDictionary objectForKey:@"lat"];
        lon = [myFlightDictionary objectForKey:@"lon"];
        validPosition = [myFlightDictionary objectForKey:@"validPosition"];
        altitude = [myFlightDictionary objectForKey:@"altitude"];
        vert_rate = [myFlightDictionary objectForKey:@"vert_rate"];
        track = [myFlightDictionary objectForKey:@"track"];
        validTrack = [myFlightDictionary objectForKey:@"validTrack"];
        speed = [myFlightDictionary objectForKey:@"speed"];
        messages = [myFlightDictionary objectForKey:@"messages"];
        seen = [myFlightDictionary objectForKey:@"seen"];
        mlat = [myFlightDictionary objectForKey:@"mlat"];
    }
    return self;
}

@end
