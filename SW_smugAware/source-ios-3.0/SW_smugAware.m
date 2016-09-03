/*
 *	Copyright 2015, SmugWimp
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors 
 *	may be used to endorse or promote products derived from this software without specific 
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */


/*
 Sample Data (Guam's A.B. Wonpat International Airport)
 [{
	"hex": "a51c37",
	"squawk": "0000",
	"flight": "",
	"lat": 0.000000,
	"lon": 0.000000,
	"validposition": 0,
	"altitude": 200,
	"vert_rate": 0,
	"track": 0,
	"validtrack": 0,
	"speed": 0,
	"messages": 93,
	"seen": 5,
	"mlat": false
 }, {
	"hex": "a47809",
	"squawk": "2751",
	"flight": "UAL183  ",
	"lat": 13.264315,
	"lon": 142.936803,
	"validposition": 1,
	"altitude": 31550,
	"vert_rate": 1920,
	"track": 266,
	"validtrack": 1,
	"speed": 456,
	"messages": 2324,
	"seen": 255,
	"mlat": false
 }]
 */

// calculations for rotation and distance. leave'em alone.
#define METERS_PER_MILE 1609.344
#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)
#define M_PI   3.14159265358979323846264338327950288   /* pi */
//
#import "SW_smugAware.h"
#import "SW_smugAwarePlaneObject.h"
#import "SW_smugAwarePlaneView.h"

//////////////////////////////////////////////////////////////////////////////////////////////////
@implementation SW_smugAware
//////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize planeItems;
@synthesize mapView;
@synthesize didInitialPinDrop;
@synthesize mapToolbar;
@synthesize driveToLocation;
@synthesize saveAsFileName;
@synthesize downloader;
@synthesize didInitMap;
@synthesize myTimer;
//
@synthesize planeImage;
//
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//viewDidLoad
-(void)viewDidLoad{
    [BT_debugger showIt:self theMessage:@"viewDidLoad"];
    //    guamflights_appDelegate *appDelegate = (guamflights_appDelegate *)[[UIApplication sharedApplication] delegate];
    [super viewDidLoad];
    
    [self setDidInitMap:0];
    //the height of the mapView depends on whether or not we are showing a bottom tool bar.
    int mapHeight = self.view.bounds.size.height - 44;
    guamflights_appDelegate *appDelegate = (guamflights_appDelegate *)[[UIApplication sharedApplication] delegate];
    if([appDelegate.rootDevice isIPad]){
        mapHeight = self.view.bounds.size.height - 88;
    }
    int mapWidth = self.view.bounds.size.width;
    int mapTop = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0 : 0;
    CLLocationCoordinate2D baseCoords = CLLocationCoordinate2DMake(13.684219, 144.956665);
    //mapView
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, mapTop, mapWidth, mapHeight - 10)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.showsUserLocation = FALSE;
    self.mapView.mapType = MKMapTypeStandard;
    [self.mapView setZoomEnabled:TRUE];
    [self.mapView setScrollEnabled:TRUE];
    [self.mapView setCenterCoordinate:baseCoords animated:YES];
    self.mapView.delegate = self;
    [self.view addSubview:mapView];
    MKCoordinateRegion myRegion = MKCoordinateRegionMakeWithDistance(baseCoords, 150000, 150000);
    MKCoordinateRegion myAdjustedRegion = [self.mapView regionThatFits:myRegion];
    [self.mapView setRegion:myAdjustedRegion animated:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload {
    [super viewDidUnload];
    [self turnTimerOff];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [BT_debugger showIt:self theMessage:@"viewWillAppear"];
    // Update support iOS 7
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.translucent = NO;
    }
    //if we have not inited map..
    if(self.didInitMap == 0){
        [self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
        [self setDidInitMap:1];
    }
    //show adView?
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"includeAds" defaultValue:@"0"] isEqualToString:@"1"]){
        [self showHideAdView];
    }
    
    self.planeImage = [UIImage imageNamed:@"plane1.png"];
    [self turnTimerOn];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Revert to default settings
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeAll;
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // Revert to default settings
    [self turnTimerOff];
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void) turnTimerOn {
    
    int mySchedule = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"refreshInterval" defaultValue:@"1.5"] intValue];
    if (mySchedule < 1) {mySchedule = 1;}
    myTimer = [NSTimer scheduledTimerWithTimeInterval:mySchedule
                                               target:self
                                             selector:@selector(myTimerInterval)
                                             userInfo:nil
                                              repeats:YES];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void) turnTimerOff {
    [BT_debugger showIt:self message:@"turning timer off, supposedly"];
    [self.myTimer invalidate];
    myTimer = nil;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void) myTimerInterval {
    
    [self parseJsonData];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for(int i = 0; i < [self.planeItems count]; i++){
        BT_item *thisMapLocation = [self.planeItems objectAtIndex:i];
        
        if([thisMapLocation.jsonVars objectForKey:@"lat"]){
            if([thisMapLocation.jsonVars objectForKey:@"lon"]){
                if([[thisMapLocation.jsonVars objectForKey:@"lat"] integerValue] > 0 && [[thisMapLocation.jsonVars objectForKey:@"lon"] integerValue] > 0){
                    
                    //location object
                    CLLocationCoordinate2D tmpLocation;
                    tmpLocation.latitude = [[thisMapLocation.jsonVars objectForKey:@"lat"] doubleValue];
                    tmpLocation.longitude = [[thisMapLocation.jsonVars objectForKey:@"lon"] doubleValue];
                    //annotation object
                    
                    SW_smugAwarePlaneObject *tmpPlaneObject = [[SW_smugAwarePlaneObject alloc]initWithTitle:[thisMapLocation.jsonVars objectForKey:@"flight"] AndCoordinate:tmpLocation];
                    //
                    [tmpPlaneObject setFlightNumber:[thisMapLocation.jsonVars objectForKey:@"flight"]];
                    [tmpPlaneObject setSpeed:[thisMapLocation.jsonVars objectForKey:@"speed"]];
                    [tmpPlaneObject setHex:[thisMapLocation.jsonVars objectForKey:@"hex"]];
                    [tmpPlaneObject setSquawk:[thisMapLocation.jsonVars objectForKey:@"squawk"]];
                    [tmpPlaneObject setLat:[thisMapLocation.jsonVars objectForKey:@"lat"]];
                    [tmpPlaneObject setLon:[thisMapLocation.jsonVars objectForKey:@"lon"]];
                    [tmpPlaneObject setValidPosition:[thisMapLocation.jsonVars objectForKey:@"validposition"]];
                    [tmpPlaneObject setAltitude:[thisMapLocation.jsonVars objectForKey:@"altitude"]];
                    [tmpPlaneObject setVert_rate:[thisMapLocation.jsonVars objectForKey:@"vert_rate"]];
                    [tmpPlaneObject setTrack:[thisMapLocation.jsonVars objectForKey:@"track"]];
                    [tmpPlaneObject setValidTrack:[thisMapLocation.jsonVars objectForKey:@"validtrack"]];
                    [tmpPlaneObject setMessages:[thisMapLocation.jsonVars objectForKey:@"messages"]];
                    [tmpPlaneObject setSeen:[thisMapLocation.jsonVars objectForKey:@"seen"]];
                    [tmpPlaneObject setMlat:[thisMapLocation.jsonVars objectForKey:@"mLat"]];
                    [tmpPlaneObject setListIndex:i];
                    //
                    [self.mapView addAnnotation:tmpPlaneObject];
                    
                } else {//latitude / longitude length > 0
                }
                
            }//longitude
        } //latitude
    }//end for each location
    
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//load data
-(void)loadData{
    [BT_debugger showIt:self theMessage:@"loadData"];
    self.didInitialPinDrop = 1;
}
//
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(void)zoomToLocation {
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = 13.5;
    zoomLocation.longitude= 144.8;
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 7.5 * METERS_PER_MILE, 7.5 * METERS_PER_MILE);
    [self.mapView setRegion:viewRegion animated:YES];
    [self.mapView regionThatFits:viewRegion];
    
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL)canReach {
    BT_reachability *r = [BT_reachability reachabilityWithHostname:@"m.google.com"];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == NotReachable){
        // no connection
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ai Adai!"
                                                        message:@"Unable to Connect to Network..."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return FALSE;
    }else{
        // connection
        return TRUE;
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
- (void)parseJsonData {
    
    [BT_debugger showIt:self theMessage:@"parseJsonData"];
    
    BOOL ImTesting = FALSE;
    if ([self canReach]) {
        NSString *rawData = [[NSString alloc]init];
        if (ImTesting) {
            rawData = [BT_fileManager readTextFileFromBundleWithEncoding:@"testplane.txt" encodingFlag:-1];
        } else {
            NSString *urlString = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""];
            NSURL *url = [[NSURL alloc] initWithString:urlString];
            NSError *error;
            NSStringEncoding encoding = NSUTF8StringEncoding;
            rawData = [[NSString alloc]initWithContentsOfURL:url encoding:encoding error:&error];
        }
        planeItems = [[NSMutableArray alloc]init];
        [BT_debugger showIt:self message:[NSString stringWithFormat:@"Plane Data: %@", rawData]];
        @try {
            SBJsonParser *parser = [SBJsonParser new];
            id jsonData = [parser objectWithString:[NSString stringWithFormat:@"{\"planeObjects\":%@}", rawData]];
            if(!jsonData){
                [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
                //                [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"No Network", @"This function requires a network connection to work. We cannot find a network connection.") alertTag:0];
            }else{
                if([jsonData objectForKey:@"planeObjects"]){
                    NSArray *tmpPlaneCollection = [jsonData objectForKey:@"planeObjects"];
                    for (NSDictionary *tmpPlanes in tmpPlaneCollection) {
                        BT_item *thisPlaneItem = [[BT_item alloc]init];
                        thisPlaneItem.itemId = [tmpPlanes objectForKey:@"hex"];
                        thisPlaneItem.itemType = @"swPlaneItem";
                        thisPlaneItem.itemNickname = [tmpPlanes objectForKey:@"flight"];
                        thisPlaneItem.jsonVars = tmpPlanes;
                        [thisPlaneItem.jsonVars setValue:thisPlaneItem.itemId forKey:@"itemId"];
                        [thisPlaneItem.jsonVars setValue:thisPlaneItem.itemType forKey:@"itemType"];
                        [thisPlaneItem.jsonVars setValue:thisPlaneItem.itemNickname forKey:@"itemNickname"];
                        [self.planeItems addObject:thisPlaneItem];
                    }
                }
            }
        }@catch (NSException * e) {
            [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed") alertTag:0];
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"error parsing screen data: %@", e]];
        }@finally{
            //        [BT_debugger showIt:self message:@"And Now.... This."];
        }
        //    return planeItems;
    }
    
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//build screen (drops pins)
-(void)layoutScreen {
    [BT_debugger showIt:self theMessage:@"layoutScreen"];
    //the height of the mapView depends on whether or not we are showing a bottom tool bar.
    int mapHeight = self.view.bounds.size.height;
    int mapWidth = self.view.bounds.size.width;
    int mapTop = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 0 : 0;
    if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"navBarStyle" defaultValue:@""] isEqualToString:@"hidden"]){
        mapTop = 0;
    }
    
    //get the bottom toolbar (utility may return nil depending on this screens data)
    if(mapToolbar != nil){
        mapHeight = (mapHeight - 44);
    }
    
    //webView
    [self.mapView setFrame:CGRectMake(0, mapTop, mapWidth, mapHeight)];
    
    //remove possible previous pins and start over..
    int x = 0;
    for(x = 0; x < [self.mapView.annotations count]; x++){
        //do not remove users annotation
        if(self.mapView.userLocation != [self.mapView.annotations objectAtIndex:x]){
            [self.mapView removeAnnotation:[self.mapView.annotations objectAtIndex:x]];
        }
    }
    [self zoomToLocation];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//map view delegate methods
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//view for annotation
- (MKAnnotationView *) mapView:(MKMapView *)mMapView viewForAnnotation:(SW_smugAwarePlaneObject *)annotation {
    
    /*
     {
     "hex": "a47809",
     "squawk": "2751",
     "flight": "UAL183  ",
     "lat": 13.264315,
     "lon": 142.936803,
     "validposition": 1,
     "altitude": 31550,
     "vert_rate": 1920,
     "track": 266,
     "validtrack": 1,
     "speed": 456,
     "messages": 2324,
     "seen": 255,
     "mlat": false
     }
     */
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"mapView:viewForAnnotation %@", annotation.title]];
    
    SW_smugAwarePlaneObject *myPlane = [[SW_smugAwarePlaneObject alloc]init];
    NSString *planeDegree = @"0";
    NSString *planeAltitude = @"0";
    NSString *planeSpeed = @"0";
    NSString *planeSquawk = @"0000";
    float planeHeading = 0;
    int planeHeight = 0;
    for(int i = 0; i < [self.planeItems count]; i++) {
        //
        BT_item *thisPlaneItem = [self.planeItems objectAtIndex:i];
        if([[thisPlaneItem.jsonVars objectForKey:@"lat"] integerValue] > 0 && [[thisPlaneItem.jsonVars objectForKey:@"lon"] integerValue] > 0){
            //
            if([[thisPlaneItem.jsonVars objectForKey:@"itemNickname"] isEqualToString:annotation.title]) {
                //
                myPlane = [[SW_smugAwarePlaneObject alloc]initWithFlightNum:[thisPlaneItem.jsonVars objectForKey:@"flight"] AndDetails:thisPlaneItem.jsonVars];
                planeDegree = [thisPlaneItem.jsonVars objectForKey:@"track"];
                planeAltitude = [thisPlaneItem.jsonVars objectForKey:@"altitude"];
                planeSpeed = [thisPlaneItem.jsonVars objectForKey:@"speed"];
                planeSquawk = [thisPlaneItem.jsonVars objectForKey:@"squawk"];
            }
        } else {
            // an object with no coordinates... to be dealt with later... sometimes military, sometimes just not off the ground.
        }
    }
    planeHeading = [planeDegree floatValue];
    planeHeight = [planeAltitude intValue];
    UIImage *myCustomAnnotationImage = [[UIImage alloc]init];
    if (([planeSquawk isEqualToString:@"7500"])||([planeSquawk isEqualToString:@"7500"])||([planeSquawk isEqualToString:@"7500"])) {
        // 7500 = hijacking. 7600 = radio failure 7700 = general failure
        myCustomAnnotationImage = [UIImage imageNamed:@"airEmergency.png"];
    } else {
        if (planeHeight > 30000) {
            myCustomAnnotationImage = [self changeColor:@"#0A730A" ofImage:[UIImage imageNamed:@"plane1.png"]];
        } else if ((planeHeight < 30000) && (planeHeight > 20000)) {
            myCustomAnnotationImage = [self changeColor:@"#1F911F" ofImage:[UIImage imageNamed:@"plane1.png"]];
        } else if ((planeHeight < 20000) && (planeHeight > 10000)) {
            myCustomAnnotationImage = [self changeColor:@"#39A939" ofImage:[UIImage imageNamed:@"plane1.png"]];
        } else if ((planeHeight < 10000) && (planeHeight > 1000)) {
            myCustomAnnotationImage = [self changeColor:@"#5CC45C" ofImage:[UIImage imageNamed:@"plane1.png"]];
        } else {
            myCustomAnnotationImage = [self changeColor:@"#8CDC8C" ofImage:[UIImage imageNamed:@"plane1.png"]];
        }
    }
    
    MKAnnotationView *planeView = nil;
    static NSString *smugPlaneID = @"com.mgps.smugplane";
    planeView = (MKAnnotationView *)[mMapView dequeueReusableAnnotationViewWithIdentifier:smugPlaneID];
    if(planeView == nil) {
        planeView = [[MKAnnotationView alloc] initWithAnnotation:myPlane reuseIdentifier:smugPlaneID];
    }
    [planeView setCanShowCallout:TRUE];
    
    //    [planeView setImage:[UIImage imageNamed:@"plane1.png"]];
    [planeView setImage:myCustomAnnotationImage];
    [planeView setTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(planeHeading))];
    
    return planeView; // annotation;
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//handles button taps in callout bubbles
-(void)calloutButtonTapped:(id)sender{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"mapView:calloutButtonTapped%@", @""]];
    // if we ever decide to do something more when they tap a plane, this is where we'll do it.
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//done loading
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView{
    //[BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"mapView:mapViewDidFinishLoadingMap %@", @""]];
    [self hideProgress];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//error loading
-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"mapView:mapViewDidFailLoadingMap %@", @""]];
    [self hideProgress];
}

# pragma mark Miscellaneous Routines...

//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//shows directions to a location
-(NSString *)showDistanceToPlane:(BT_item *)thePlane {
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"mapView:showDirectionsToLocation%@", @""]];
    // ABWonpat:
    // N 13.483153
    // W 144.795475
    NSString *airportLatitude = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"airportLatitude" defaultValue:@"13.483153"];
    NSString *airportLongitude = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"airportLongitude" defaultValue:@"144.795475"];
    double airLat = [airportLatitude doubleValue];
    double airLng = [airportLongitude doubleValue];
    //
    NSString *aircraftLatitude = [thePlane.jsonVars objectForKey:@"lat"];
    NSString *aircraftLongitude = [thePlane.jsonVars objectForKey:@"lon"];
    double craftLat = [aircraftLatitude doubleValue];
    double craftLng = [aircraftLongitude doubleValue];
    CLLocation *wonpat = [[CLLocation alloc]initWithLatitude:airLat longitude:airLng];
    CLLocation *craftLoc = [[CLLocation alloc]initWithLatitude:craftLat longitude:craftLng];
    CLLocationDistance distOne = ([wonpat distanceFromLocation:craftLoc]) * 0.000621371192; // default output is in meters. convert to Miles.
    CLLocationDistance distTwo = ([craftLoc distanceFromLocation:wonpat]) * 0.000621371192; // default output is in meters. convert to Miles.
    CLLocationDistance avgDist = (distOne + distTwo) / 2; // Take the results, add them together, divide by 2.
    NSString *distString = [NSString stringWithFormat:@"%2.1f", avgDist]; // Format result as "00.0"
    //
    return distString;
}
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
-(UIImage *)changeColor:(NSString *)myColor ofImage: (UIImage *) myImage {
    
    UIColor *newColor = [BT_color getColorFromHexString:myColor];
    CGRect rect = CGRectMake(0, 0, myImage.size.width, myImage.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, rect, myImage.CGImage);
    CGContextSetFillColorWithColor(context, [newColor CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *flippedImage = [UIImage imageWithCGImage:img.CGImage scale:1.0 orientation:UIImageOrientationUp];
    
    return flippedImage;
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//action sheet delegate methods. Shows when 'show directions' confirmation is tapped.
-(void)actionSheet:(UIActionSheet *)actionSheet  clickedButtonAtIndex:(NSInteger)buttonIndex {
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"actionSheet:clickedButtonAtIndex %@", @""]];
    if(buttonIndex == 0){
        
        //must have the devices current location..
        //        beaconInventory_appDelegate *appDelegate = (beaconInventory_appDelegate *)[[UIApplication sharedApplication] delegate];
        
        //from location
        NSString *fromLat = @"13.5"; // [appDelegate.rootDevice deviceLatitude];
        NSString *fromLon = @"144.8"; //[appDelegate.rootDevice deviceLongitude];
        
        //to location
        BT_item *toLocation = [self driveToLocation];
        NSString *theTitle = [toLocation.jsonVars objectForKey:@"title"];
        NSString *subTitle = [toLocation.jsonVars objectForKey:@"subTitle"];
        NSString *toLat = [toLocation.jsonVars objectForKey:@"latitude"];
        NSString *toLon = [toLocation.jsonVars objectForKey:@"longitude"];
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"loading Maps, driving directions to: %@ (%@) Lat: %@ Lon: %@", theTitle, subTitle, toLat, toLon]];
        
        /*
         Maps URL Params
         --------------------
         saddr	=starting address
         daddr	=destination address
         z		=zoom level (1 - 20)
         t		=the map type, "m" map, "k" satellite, "h" hybrid, "p" terrain
         */
        
        //check for iOS 6 or capability to open native maps with options...
        Class mapItemClass = [MKMapItem class];
        if(mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]){
            
            //create an MKMapItem to pass to the Maps app
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([toLat doubleValue], [toLon doubleValue]);
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate
                                                           addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:theTitle];
            
            //pass the map item to the Maps app
            [mapItem openInMapsWithLaunchOptions:nil];
            
            
        }else{
            
            if([fromLat length] > 3 && [fromLon length] > 3 && [toLat length] > 3 && [toLon length] > 3){
                NSString *urlString = [NSString stringWithFormat:@"http://maps.apple.com?saddr=%@,%@&daddr=%@,%@", fromLat, fromLon, toLat, toLon];
                [[UIApplication sharedApplication] openURL: [NSURL URLWithString: urlString]];
            }else{
                
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"locationNotSupported", "It appears that device location information is unavailable. This feature will not work without location information.") delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
                [alertView show];
            }
            
        }//native maps capable of opening with options...
        
        
        
    }else{
        //do nothing, alert closes automatically
    }
}


//////////////////////////////////////////////////////////////////////////////////////////////

@end

