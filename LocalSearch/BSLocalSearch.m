//
//  LocalSearch.m
//  LocalSearch
//
//  Created by Kayle Gishen on 6/28/12.
//  Copyright (c) 2012 Kayle Gishen. All rights reserved.
//

#import "BSLocalSearch.h"
#import "Exceptions.h"
#import "JSONKit.h"

static NSString* kGooglePlacesFormat = @"https://maps.googleapis.com/maps/api/place/textsearch/json?%@";

@interface BSLocalSearch ()

- (id)objectWithJSONString:(NSString*)string;
- (id)objectWithData:(NSData*)data;
- (id)executeTextSearch:(NSString*)query;
@end

@implementation BSLocalSearch

@synthesize delegate = delegate, service, apiKey, sensorEnabled;

- (id)init
{
    self = [super init];
    if (self) {
        _decoder = [JSONDecoder decoder];
    }
    
    return self;
}

- (id)objectWithData:(NSData *)data
{
    return [_decoder objectWithData:data];
}

- (id)objectWithJSONString:(NSString*)string
{
    return [self objectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)executeTextSearch:(NSString *)query
{
    NSURL *url;
    static NSString* TRUE_STRING = @"true";
    static NSString* FALSE_STRING = @"false";
    if(service == GOOGLE_PlACES)
    {
        if(!apiKey)
            [NSException raise:BSLocalSearchMissingAPIKey format:@"API Key was not supplied"];
        NSString *params = [NSString stringWithFormat:@"query=%@&sensor=%@&key=%@",query, (sensorEnabled ? TRUE_STRING : FALSE_STRING), apiKey];
        url = [NSURL URLWithString:[NSString stringWithFormat:kGooglePlacesFormat, [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }else{
        [NSException raise:BSLocalSearchUnknownService format:@"Unknown or no search service specified"];
    }
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [self objectWithData:data];
}

- (void)submitTextSearch:(NSString *)query
{
    dispatch_async(dispatch_get_current_queue(), ^{
        id result = [self executeTextSearch:query];
        if(delegate)
            [delegate searchReturnedWithResponse:result];
    });
}

@end
