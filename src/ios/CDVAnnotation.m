//
//  PHAnnotation.m
//  PhoneGapLib
//
//  Created by Brett Rudd on 17/03/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CDVAnnotation.h"

@implementation CDVAnnotation

@synthesize title = _title;
@synthesize subTitle = _subTitle;
@synthesize index = _index;
@synthesize placemark = _placemark;
@synthesize imageURL = _imageURL;
@synthesize coordinate = _coordinate;
@synthesize pinColor;
@synthesize selected;
@synthesize slug = _slug;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate index:(NSInteger)index title:(NSString*)title subTitle:(NSString*)subTitle imageURL:(NSString*)imageURL slug:(NSString*)slug{
    if ((self = [super init])) {
        _coordinate=coordinate;
        _title = title;
        _subTitle = subTitle;
        _index=index;
        _imageURL=imageURL;
        _slug = slug;
    }
    return self;
}

- (NSString *)title {
    return _title;
}

- (NSString *)subtitle {
    return _subTitle;
}

- (void)notifyCalloutInfo:(MKPlacemark *)newPlacemark {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"MKAnnotationCalloutInfoDidChangeNotification" object:self]];
}

@end
