//
//  LocalSearch.h
//  LocalSearch
//
//  Created by Kayle Gishen on 6/28/12.
//  Copyright (c) 2012 Kayle Gishen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^BSLocalSearchCallback)(id response);

@class JSONDecoder;
@class BSLocalSearch;

enum BSLocalSearchService {
    GOOGLE_PlACES = 1,
    YELP = 2,
    OPEN_STREET_MAP = 3,
    FACTUAL = 4
    };

@interface BSLocalSearchResult : NSObject

@property (nonatomic, copy) NSString *formattedAddress;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;


@end

@protocol LocalSearchDelegate <NSObject>

@required

- (void)searchReturnedWithResponse:(id)result;

@end

@interface BSLocalSearch : NSObject
{
    JSONDecoder *_decoder;
}

@property (nonatomic, retain) id<LocalSearchDelegate> delegate;
@property (nonatomic, readwrite) enum BSLocalSearchService service;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *tokenSecret;
@property (nonatomic, readwrite, getter = isSensorEnabled) bool sensorEnabled;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, assign) CLLocationDistance radius;
@property (nonatomic, readwrite) bool useLocation;

+ (BSLocalSearch*)sharedInstance;

- (void)submitTextSearch:(NSString*)query;
- (void)submitTextSearch:(NSString*)query completionHandler:(BSLocalSearchCallback)handler;

@end