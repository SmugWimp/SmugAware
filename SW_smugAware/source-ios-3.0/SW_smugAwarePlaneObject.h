//
//  SW_smugAwarePlaneObject.h
//  beaconinventory
//
//  Created by Clarence Fields on 3/8/16.
//  Copyright © 2016 Buzztouch. All rights reserved.
//
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>

@interface SW_smugAwarePlaneObject : NSObject < MKAnnotation > {

    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    int listIndex;
}

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic) int listIndex;

@property (nonatomic, copy) NSString *flightNumber;
@property (nonatomic, copy) NSString *flightDetails;
@property (nonatomic, retain) NSString *hex;
@property (nonatomic, retain) NSString *squawk;
@property (nonatomic, retain) NSString *lat;
@property (nonatomic, retain) NSString *lon;
@property (nonatomic, retain) NSString *validPosition;
@property (nonatomic, retain) NSString *altitude;
@property (nonatomic, retain) NSString *vert_rate;
@property (nonatomic, retain) NSString *track;
@property (nonatomic, retain) NSString *validTrack;
@property (nonatomic, retain) NSString *speed;
@property (nonatomic, retain) NSString *messages;
@property (nonatomic, retain) NSString *seen;
@property (nonatomic, retain) NSString *mlat;

-(id)initWithCoordinate:(CLLocationCoordinate2D)c;
-(id) initWithTitle:(NSString *)myTitle AndCoordinate:(CLLocationCoordinate2D)myCoordinate;
-(id) initWithTitle:(NSString *)myTitle AndSubTitle:(NSString *)mySubTitle AndCoordinate:(CLLocationCoordinate2D)myCoordinate;
-(id) initWithFlightNum:(NSString *)myFlightNumber AndDetails:(NSDictionary *)myFlightDictionary;

@end
