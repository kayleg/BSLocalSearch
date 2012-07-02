//
//  LocalSearch.h
//  LocalSearch
//
//  Created by Kayle Gishen on 6/28/12.
//  Copyright (c) 2012 Kayle Gishen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BSLocalSearchCallback)(id response);

@class JSONDecoder;
@class BSLocalSearch;

enum BSLocalSearchService {
    GOOGLE_PlACES = 1,
    YELP = 2
    };

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
@property (nonatomic, readwrite, getter = isSensorEnabled) bool sensorEnabled;

- (void)submitTextSearch:(NSString*)query;
- (void)submitTextSearch:(NSString*)query completionHandler:(BSLocalSearchCallback)handler;

@end