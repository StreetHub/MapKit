//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

@interface MapKitView()<CCHMapClusterControllerDelegate>
//@property (strong, nonatomic) CCHMapClusterController *mapClusterController;
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


    self.mapClusterControllerRed = [[CCHMapClusterController alloc] initWithMapView:self.mapView];
    self.mapClusterControllerRed.delegate = self;

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

    // If already added pins, don t re-add them
    if([self.mapView.annotations count] > 1){
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    } else {

        for (int y = 0; y < pins.count; y++)
        {
            NSDictionary *pinData = [pins objectAtIndex:y];

            CLLocationCoordinate2D coordinate = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
            NSString* title = [[pinData valueForKey:@"name"] description];
            NSString* subTitle = [[pinData valueForKey:@"slug"] description];
            NSString* slug = [[pinData valueForKey:@"slug"] description];
            NSString *imageURL = nil;
            NSInteger index=[[pinData valueForKey:@"index"] integerValue];
            CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:coordinate index:index title:title subTitle:subTitle imageURL:imageURL slug:slug];

            [newPins addObject:annotation];
        }

        self.mapClusterControllerRed.debuggingEnabled = NO;
        self.mapClusterControllerRed.cellSize = 30;
        //    self.mapClusterController.maxZoomLevelForClustering = 13;

        __weak MapKitView *weakSelf = self; // self = this in obj-c - Avoid Strong Reference Cycles

        [self.mapClusterControllerRed addAnnotations:newPins withCompletionHandler:^{

            CDVPluginResult* pluginResult = nil;

            MKMapRect visibleMapRect = weakSelf.mapView.visibleMapRect;
            NSSet *visibleAnnotations = [weakSelf.mapView annotationsInMapRect:visibleMapRect];

           // NSLog(@"I was blind but now I see %d %@", [visibleAnnotations count], [visibleAnnotations description]);

            if([visibleAnnotations count] == 1 && [[[visibleAnnotations allObjects] firstObject ] isKindOfClass:[MKUserLocation class]]){ // if only user location pin
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"false"];
            } else {

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
            }

            [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

        }];

    }

//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

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

    // NSLog(@"// MOVE CENTER: %@ %@ ", command.arguments[0][@"lat"], command.arguments[0][@"lon"]);

    float spanX = 0.00725*3;
    float spanY = 0.00725*3;

    MKCoordinateRegion region;
    region.center.latitude = [command.arguments[0][@"lat"] doubleValue] ;
    region.center.longitude = [command.arguments[0][@"lon"] doubleValue] ;
    region.span = MKCoordinateSpanMake(spanX, spanY);


    [self.mapView setRegion:region animated:YES];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)updatePins:(CDVInvokedUrlCommand *)command
{
    if (!self.mapView || self.childView.hidden==YES)
    {
        return;
    }

   // NSLog(@"updatePINS %@", command.arguments);

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

//Might need this later?
// - (void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
//  {
//  MKCoordinateRegion mapRegion;
//  mapRegion.center = userLocation.coordinate;
//  mapRegion.span.latitudeDelta = 0.2;
//  mapRegion.span.longitudeDelta = 0.2;

//  [self.mapView setRegion:mapRegion animated: YES];
//  }



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

//-(void)openAnnotation:(id <MKAnnotation>) annotation
//{
//    [ self.mapView selectAnnotation:annotation animated:YES];
//
//}
//
//- (void) checkButtonTapped:(id)button
//{
//    UIButton *tmpButton = button;
//    NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
//    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
//}

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

    NSMutableArray *response = [[NSMutableArray alloc] init];

    if([[self.mapView.selectedAnnotations firstObject ] isKindOfClass:[MKUserLocation class]]){ // if only user location pin
        [response addObject:[[NSString alloc] init]];
    } else {
        // Return array of slugs
        for(CCHMapClusterAnnotation* cluster in self.mapView.selectedAnnotations){
            for (CDVAnnotation *annotation in cluster.annotations) {
                [response addObject:[[NSString alloc] initWithFormat:@"%@", [ annotation slug ] ]];
            }
        }
    }

    NSString * responseStr = [[response valueForKey:@"description"] componentsJoinedByString:@","];

    NSString *annotationTapFunctionString = [NSString stringWithFormat:@"%s%@%s", "mapKit.didSelectAnnotationView('", responseStr, "')"];
    [self.webView stringByEvaluatingJavaScriptFromString:annotationTapFunctionString];
}

// Change title on the annotation bubble (first line)
- (NSString *)mapClusterController:(CCHMapClusterController *)mapClusterController titleForMapClusterAnnotation:(CCHMapClusterAnnotation *)mapClusterAnnotation
{

    NSString *title;
    NSUInteger numAnnotations = mapClusterAnnotation.annotations.count;

    if(numAnnotations == 1){
        title = [[[mapClusterAnnotation.annotations allObjects] firstObject] valueForKey:@"title"];
    } else {
        title = [NSString stringWithFormat:@"%tu boutiques", numAnnotations];
    }

    return [title description];
}

- (NSString *)mapClusterController:(CCHMapClusterController *)mapClusterController subtitleForMapClusterAnnotation:(CCHMapClusterAnnotation *)mapClusterAnnotation
{
    NSUInteger numAnnotations = MIN(mapClusterAnnotation.annotations.count, 5);
    NSString *subtitle;

    if(numAnnotations == 1){
        subtitle = @"";
    } else {
        NSArray *annotations = [mapClusterAnnotation.annotations.allObjects subarrayWithRange:NSMakeRange(0, numAnnotations)];
        NSArray *subtitles = [annotations valueForKey:@"title"];
        subtitle = [subtitles componentsJoinedByString:@", "];
    }

    return [subtitle description];
}

- (void)mapClusterController:(CCHMapClusterController *)mapClusterController willReuseMapClusterAnnotation:(CCHMapClusterAnnotation *)mapClusterAnnotation
{
    ClusterAnnotationView *clusterAnnotationView = (ClusterAnnotationView *)[self.mapView viewForAnnotation:mapClusterAnnotation];
    clusterAnnotationView.count = mapClusterAnnotation.annotations.count;
    clusterAnnotationView.uniqueLocation = mapClusterAnnotation.isUniqueLocation;
}

// When the map is moved
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {


    MKMapRect visibleMapRect = self.mapView.visibleMapRect;
    NSSet *visibleAnnotations = [self.mapView annotationsInMapRect:visibleMapRect];

    // Callback to filter the response for CCHMapClusterAnnotation
    NSPredicate *predCluster = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isMemberOfClass:[CCHMapClusterAnnotation class]];
    }];

    NSSet *clusterSet = [visibleAnnotations filteredSetUsingPredicate:predCluster];

    NSMutableArray *response = [[NSMutableArray alloc] init];

    // There are two for loops because self.mapView.selectedAnnotations is a NSArray and clusterSet a NSSet
    if([self.mapView.selectedAnnotations count] > 0 &&
       ![[self.mapView.selectedAnnotations firstObject ] isKindOfClass:[MKUserLocation class]]){// only return selected and if location not selected
        for(CCHMapClusterAnnotation* cluster in self.mapView.selectedAnnotations){
            for (CDVAnnotation *annotation in cluster.annotations) {
                [response addObject:[[NSString alloc] initWithFormat:@"%@", [ annotation slug ] ]];
            }
        }
    } else {

        for(CCHMapClusterAnnotation* cluster in clusterSet) {
            for (CDVAnnotation *annotation in cluster.annotations) {
                [response addObject:[[NSString alloc] initWithFormat:@"%@", [ annotation slug ] ]];
            }
        }

    }

    // Convert to string - stringByEvaluatingJavaScriptFromString only accepts strings
    NSString * responseStr = [[response valueForKey:@"description"] componentsJoinedByString:@","];
    // NSLog(@"returned slugs %@", responseStr);
    NSString *regionDidChangeAnimatedFunctionString = [NSString stringWithFormat:@"%s%@%s", "mapKit.regionDidChangeAnimated('", responseStr,"')"];
    [self.webView stringByEvaluatingJavaScriptFromString:regionDidChangeAnimatedFunctionString];
}


@end

