//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@interface MapKitView()<CCHMapClusterControllerDelegate>

@property (strong, nonatomic) CCHMapClusterController *mapClusterControllerRed;
@property (strong, nonatomic) CCHMapClusterController *mapClusterControllerBlue;
@property (assign, nonatomic) NSUInteger count;
@property (strong, nonatomic) id<CCHMapClusterer> mapClusterer;
@property (strong, nonatomic) id<CCHMapAnimator> mapAnimator;

@end

@implementation MapKitView

@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
@synthesize imageButton;



-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
    NSDictionary *options = [[NSDictionary alloc] init];
    [self createViewWithOptions:options];
}

- (void)createViewWithOptions:(NSDictionary *)options {


    //This is the Designated Initializer

    // defaults
    float height = ([options objectForKey:@"height"]) ? [[options objectForKey:@"height"] floatValue] : self.webView.bounds.size.height/2;
    float width = ([options objectForKey:@"width"]) ? [[options objectForKey:@"width"] floatValue] : self.webView.bounds.size.width;
    float ratio = 0;

    float denom = 1;

    if(height != 0){
        ratio = width / height;
    }

    denom = sqrt(1 + (ratio * ratio));

    float diameter = [[options objectForKey:@"diameter"] floatValue] * 1609.344; // X miles

    float distX = ratio * (diameter) / denom;
    float distY = (diameter) / denom;

    CLLocationDistance latitudinalMeters = distX;
    CLLocationDistance longitudinalMeters = distY;

    float x = self.webView.bounds.origin.x;
    float y = self.webView.bounds.origin.y;
    BOOL atBottom = ([options objectForKey:@"atBottom"]) ? [[options objectForKey:@"atBottom"] boolValue] : NO;

    if(atBottom) {
        y += self.webView.bounds.size.height - height;
    } else {
        y = 68;
    }

    self.childView = [[UIView alloc] initWithFrame:CGRectMake(x,y,width,height)];
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(self.childView.bounds.origin.x, self.childView.bounds.origin.x, self.childView.bounds.size.width, self.childView.bounds.size.height)];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
    self.mapView.showsUserLocation = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;


    CLLocationCoordinate2D centerCoord = { [[options objectForKey:@"lat"] floatValue] , [[options objectForKey:@"lon"] floatValue] };


    MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord,
                                                                                                latitudinalMeters,
                                                                                                longitudinalMeters)];
    [self.mapView setRegion:region animated:YES];
    [self.childView addSubview:self.mapView];

    [ [ [ self viewController ] view ] addSubview:self.childView];

}

- (void)destroyMap:(CDVInvokedUrlCommand *)command
{
    if (self.mapView)
    {
        [ self.mapView removeAnnotations:mapView.annotations];
        [ self.mapView removeFromSuperview];

        mapView = nil;
    }
    if(self.imageButton)
    {
        [ self.imageButton removeFromSuperview];
        //[ self.imageButton removeTarget:self action:@selector(closeButton:) forControlEvents:UIControlEventTouchUpInside];
        self.imageButton = nil;

    }
    if(self.childView)
    {
        [ self.childView removeFromSuperview];
        self.childView = nil;
    }
    self.buttonCallback = nil;
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{


}

- (void)clearMapPins:(CDVInvokedUrlCommand *)command
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)addMapPins:(CDVInvokedUrlCommand *)command
{

    NSArray *pins = command.arguments[0];
    NSMutableArray *newPins = [[NSMutableArray alloc] init];

    for (int y = 0; y < pins.count; y++)
    {
        NSDictionary *pinData = [pins objectAtIndex:y];

        CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
//        NSString *title=[[pinData valueForKey:@"title"] description];
        NSString *title=@"Ta mere";
//        NSString *subTitle=[[pinData valueForKey:@"snippet"] description];
        NSString *subTitle=@"En String";
        NSInteger index=[[pinData valueForKey:@"index"] integerValue];
        BOOL selected = [[pinData valueForKey:@"selected"] boolValue];

        NSString *pinColor = nil;
        NSString *imageURL = nil;

        if([[pinData valueForKey:@"icon"] isKindOfClass:[NSNumber class]])
        {
            pinColor = [[pinData valueForKey:@"icon"] description];
        }
        else if([[pinData valueForKey:@"icon"] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *iconOptions = [pinData valueForKey:@"icon"];
            pinColor = [[iconOptions valueForKey:@"pinColor" ] description];
            imageURL=[[iconOptions valueForKey:@"resource"] description];
        }

        CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
        annotation.pinColor=pinColor;
        annotation.selected = selected;

        [newPins addObject:annotation];
    }

    self.mapClusterController = [[CCHMapClusterController alloc] initWithMapView:self.mapView];
    self.mapClusterController.debuggingEnabled = YES;
    self.mapClusterController.cellSize = 30;
//    self.mapClusterController.maxZoomLevelForClustering = 13;
    [self.mapClusterController addAnnotations:newPins withCompletionHandler:NULL];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *annotationView;

    if ([annotation isKindOfClass:CCHMapClusterAnnotation.class]) {
        static NSString *identifier = @"clusterAnnotation";

        ClusterAnnotationView *clusterAnnotationView = (ClusterAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (clusterAnnotationView) {
            clusterAnnotationView.annotation = annotation;
        } else {
            clusterAnnotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            clusterAnnotationView.canShowCallout = YES;
        }

        CCHMapClusterAnnotation *clusterAnnotation = (CCHMapClusterAnnotation *)annotation;
        clusterAnnotationView.count = clusterAnnotation.annotations.count;
        NSLog(@"that cluster oh yeah %d",clusterAnnotation.annotations.count);
        clusterAnnotationView.blue = (clusterAnnotation.mapClusterController == self.mapClusterControllerBlue);
        clusterAnnotationView.uniqueLocation = clusterAnnotation.isUniqueLocation;
        annotationView = clusterAnnotationView;
    }

    return annotationView;
}

-(void)showMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView)
    {
        [self createViewWithOptions:command.arguments[0]];
    }
    self.childView.hidden = NO;
    self.mapView.showsUserLocation = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}


- (void)hideMap:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }
    // disable location services, if we no longer need it.
    self.mapView.showsUserLocation = NO;
    self.childView.hidden = YES;
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)changeMapType:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }

    int mapType = ([command.arguments[0] objectForKey:@"mapType"]) ? [[command.arguments[0] objectForKey:@"mapType"] intValue] : 0;

    switch (mapType) {
        case 4:
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        case 2:
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        default:
            [self.mapView setMapType:MKMapTypeStandard];
            break;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)moveCenter:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }

    NSLog(@"///////////////////////MOVE CENTER ");

    float spanX = 0.00725;
    float spanY = 0.00725;

    MKCoordinateRegion region;
    region.center.latitude = [command.arguments[0][@"lat"] doubleValue] ;
    region.center.longitude = [command.arguments[0][@"lon"] doubleValue] ;
    region.span = MKCoordinateSpanMake(spanX, spanY);


    [self.mapView setRegion:region animated:YES];

    NSLog(@"iOS Coordinates lon %@", command.arguments[0][@"lon"] );
    NSLog(@"iOS Coordinates lat %@", command.arguments[0][@"lat"] );

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)updatePins:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }

//    NSLog(@"updatePINS %@", command.arguments);

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

//Might need this later?
/*- (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
 {
 MKCoordinateRegion mapRegion;
 mapRegion.center = userLocation.coordinate;
 mapRegion.span.latitudeDelta = 0.2;
 mapRegion.span.longitudeDelta = 0.2;

 [self.mapView setRegion:mapRegion animated: YES];
 }


 - (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated
 {
 NSLog(@"region did change animated");
 float currentLat = theMapView.region.center.latitude;
 float currentLon = theMapView.region.center.longitude;
 float latitudeDelta = theMapView.region.span.latitudeDelta;
 float longitudeDelta = theMapView.region.span.longitudeDelta;

 NSString* jsString = nil;
 jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
 [self.webView stringByEvaluatingJavaScriptFromString:jsString];
 [jsString autorelease];
 }
 */


//- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {
//
//    if ([annotation class] != CDVAnnotation.class) {
//        return nil;
//    }
//
//    CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
//    NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];
//
//    MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
//
//    if (annView!=nil) return annView;
//
//    annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
//
//    annView.animatesDrop=YES;
//    annView.canShowCallout = YES;
//    if ([phAnnotation.pinColor isEqualToString:@"120"])
//        annView.pinColor = MKPinAnnotationColorGreen;
//    else if ([phAnnotation.pinColor isEqualToString:@"270"])
//        annView.pinColor = MKPinAnnotationColorPurple;
//    else
//        annView.pinColor = MKPinAnnotationColorRed;
//
//    AsyncImageView* asyncImage = [[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)];
//    asyncImage.tag = 999;
//    if (phAnnotation.imageURL)
//    {
//        NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL];
//        [asyncImage loadImageFromURL:url];
//    }
//    else
//    {
//        [asyncImage loadDefaultImage];
//    }
//
//    annView.leftCalloutAccessoryView = asyncImage;
//
//
//    if (self.buttonCallback && phAnnotation.index!=-1)
//    {
//
//        UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        myDetailButton.frame = CGRectMake(0, 0, 23, 23);
//        myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
//        myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
//        myDetailButton.tag=phAnnotation.index;
//        annView.rightCalloutAccessoryView = myDetailButton;
//        [ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//
//    }
//
//    if(phAnnotation.selected)
//    {
//        [self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
//    }
//
//    return annView;
//}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
    [ self.mapView selectAnnotation:annotation animated:YES];

}

- (void) checkButtonTapped:(id)button
{
    UIButton *tmpButton = button;
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)dealloc
{
    if (self.mapView)
    {
        [ self.mapView removeAnnotations:mapView.annotations];
        [ self.mapView removeFromSuperview];
        self.mapView = nil;
    }
    if(self.imageButton)
    {
        [ self.imageButton removeFromSuperview];
        self.imageButton = nil;
    }
    if(childView)
    {
        [ self.childView removeFromSuperview];
        self.childView = nil;
    }
    self.buttonCallback = nil;
}

//when a pin is selected, do something
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"DEBUG: got here selectasdasdas stuff");

    NSString *annotationTapFunctionString = [NSString stringWithFormat:@"%s%@%s", "mapKit.didSelectAnnotationView('", [view.annotation title], "')"];
    [self.webView stringByEvaluatingJavaScriptFromString:annotationTapFunctionString];
}

double deg2rad(double deg) {
    return deg * (M_PI/180);
}

//when the map is moved
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

//    MKCoordinateRegion region = self.mapView.region;
//
//    const int EARTH_RADIUS = 6371;
//    const double KM_TO_MILES = 1.609344;

//    double lat = region.center.latitude;
//    double lon = region.center.longitude;
//
//    double minLat = deg2rad(lat - (region.span.latitudeDelta / 2.0));
//    double maxLat = deg2rad(lat + (region.span.latitudeDelta / 2.0));
//
//    double minLon = deg2rad(lon - (region.span.longitudeDelta / 2.0));
//    double maxLon = deg2rad(lon + (region.span.longitudeDelta / 2.0));
//
//
//    // Haversine formula
//    double h = ( pow(sin((maxLat-minLat)/2), 2) + cos(minLat)*cos(maxLat) * pow(sin((maxLon-minLon)/2), 2) );
//
//    h = h > 1.0 ? 1.0 : h; // Avoid rounding errors
//    h = h < 0.0 ? 0.0 : h; // Avoid asin errors
//
//    double radius = (asin(sqrt(h)) * 2 * EARTH_RADIUS) / KM_TO_MILES;

    MKMapRect visibleMapRect = self.mapView.visibleMapRect;
    NSSet *visibleAnnotations = [self.mapView annotationsInMapRect:visibleMapRect];

    // Callback to filter the response for CCHMapClusterAnnotation
    NSPredicate *predCluster = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isMemberOfClass:[CCHMapClusterAnnotation class]];
    }];

    // Callback to filter the response for MKUserLocation
    NSPredicate *predMK = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isMemberOfClass:[MKUserLocation class]];
    }];

    NSSet *clusterSet = [visibleAnnotations filteredSetUsingPredicate:predCluster];
    NSSet *mkSet = [visibleAnnotations filteredSetUsingPredicate:predMK];

    NSMutableArray *response = [[NSMutableArray alloc] init];

    for(CCHMapClusterAnnotation* cluster in clusterSet) {
        for (CDVAnnotation *annotation in cluster.annotations) {

            [response addObject:[[NSString alloc] initWithFormat:@"%f", annotation.coordinate.longitude]];
            [response addObject:[[NSString alloc] initWithFormat:@"%f", annotation.coordinate.latitude]];
        }
    }

    for(MKUserLocation* position in mkSet) {
        [response addObject:[[NSString alloc] initWithFormat:@"%f", position.location.coordinate.longitude]];
        [response addObject:[[NSString alloc] initWithFormat:@"%f", position.location.coordinate.latitude]];
    }

    // Convert to string - stringByEvaluatingJavaScriptFromString only accepts strings
    NSString * responseStr = [[response valueForKey:@"description"] componentsJoinedByString:@","];

    // lf : long float -> double
    NSString *regionDidChangeAnimatedFunctionString = [NSString stringWithFormat:@"%s%@%s", "mapKit.regionDidChangeAnimated('", responseStr,"')"];
    [self.webView stringByEvaluatingJavaScriptFromString:regionDidChangeAnimatedFunctionString];
}

@end

