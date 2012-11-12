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
#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"
#import <CoreLocation/CoreLocation.h>

static NSString* kGooglePlacesFormat = @"https://maps.googleapis.com/maps/api/place/textsearch/json?%@";
static NSString* kOpenStreetMapFormat = @"http://nominatim.openstreetmap.org/search?format=json&q=%@";
static NSString* kYelpFormat = @"http://api.yelp.com/v2/search?%@";
static NSString* kFactualFormat = @"http://api.v3.factual.com/t/places.json?q=%@";
static NSString* kNear = @" near ";
static NSString* kTrimCharacters = @" ,";
static NSCharacterSet* kTrimSet;

static BSLocalSearch *_instance = nil;

@implementation BSLocalSearchResult

@synthesize formattedAddress, coordinate, name;

- (NSString*)title
{
    return name;
}

- (NSString*)subtitle
{
    return formattedAddress;
}

- (void)dealloc
{
    formattedAddress = nil;
    name = nil;
}

@end

@interface BSLocalSearch ()

- (id)objectWithJSONString:(NSString*)string;
- (id)objectWithData:(NSData*)data;
- (id)executeTextSearch:(NSString*)query;
@end

@implementation BSLocalSearch

@synthesize delegate = delegate, service, apiKey, sensorEnabled, consumerKey, consumerSecret, token, tokenSecret, location, useLocation;

+ (BSLocalSearch*)sharedInstance
{
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        if(_instance == nil)
            _instance = [self new];
    });
    return _instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _decoder = [JSONDecoder decoder];
        kTrimSet = [NSCharacterSet characterSetWithCharactersInString:kTrimCharacters];
        useLocation = YES;
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
    NSData *data;
    static NSString* TRUE_STRING = @"true";
    static NSString* FALSE_STRING = @"false";
    if(service == GOOGLE_PlACES)
    {
        if(!apiKey)
            [NSException raise:BSLocalSearchMissingAPIKey format:@"API Key was not supplied"];
        NSString *params = [NSString stringWithFormat:@"query=%@&sensor=%@&key=%@",query, (sensorEnabled ? TRUE_STRING : FALSE_STRING), apiKey];
        url = [NSURL URLWithString:[NSString stringWithFormat:kGooglePlacesFormat, [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    } else if(service == OPEN_STREET_MAP)
    {
        url = [NSURL URLWithString:[NSString stringWithFormat:kOpenStreetMapFormat, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    }
    else if (service == YELP)
    {
        if (!token || !tokenSecret || !consumerKey || !consumerSecret) {
            [NSException raise:BSLocalSearchMissingAPIKey format:@"Missing Yelp Credentials"];
        }
        NSRange range = [[query lowercaseString] rangeOfString:kNear];
        NSString *params;
        if (range.location != NSNotFound ) {
            NSString *term = [[query substringToIndex:range.location] stringByTrimmingCharactersInSet:kTrimSet];
            NSString *loc = [[query substringFromIndex:range.location + range.length] stringByTrimmingCharactersInSet:kTrimSet];
            params = [NSString stringWithFormat:@"term=%@&location=%@",term, loc];
        }else
            params = [NSString stringWithFormat:@"term=%@&ll=%f,%f",query, location.coordinate.latitude, location.coordinate.longitude];
        
        url = [NSURL URLWithString:[NSString stringWithFormat:kYelpFormat, [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
        OAToken *oatoken = [[OAToken alloc] initWithKey:token secret:tokenSecret];
        
        id<OASignatureProviding, NSObject> provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
        
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                       consumer:consumer
                                                                          token:oatoken
                                                                          realm:nil
                                                              signatureProvider:provider];
        [request prepare];
        NSURLResponse *resp;
        data = [NSURLConnection  sendSynchronousRequest:request returningResponse:&resp error:nil];
    } else if (service == FACTUAL)
    {
        if (!consumerKey || !consumerSecret) {
            [NSException raise:BSLocalSearchMissingAPIKey format:@"Missing Factual Credentials"];
        }
        query = [query lowercaseString];
        NSString *str;
        if([query rangeOfString:kNear].location != NSNotFound)
           str = [[query lowercaseString] stringByReplacingOccurrencesOfString:kNear withString:@" "];
        else if (useLocation && location) {
            str = [query stringByAppendingFormat:@"&geo={\"$circle\":{\"$center\":[%f,%f],\"$meters\":%f}}", location.coordinate.latitude, location.coordinate.longitude, MAX(self.radius, 500000)];
        }
        url = [NSURL URLWithString:[NSString stringWithFormat:kFactualFormat, [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        OAConsumer *consumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
        id<OASignatureProviding, NSObject> provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
        
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                       consumer:consumer
                                                                          token:nil
                                                                          realm:nil
                                                              signatureProvider:provider];
        [request prepare];
        NSURLResponse *resp;
        data = [NSURLConnection  sendSynchronousRequest:request returningResponse:&resp error:nil];
    }
    else{
        [NSException raise:BSLocalSearchUnknownService format:@"Unknown or no search service specified"];
    }
    
    if (service != YELP && service != FACTUAL) {
        data = [NSData dataWithContentsOfURL:url];
    }
    
    NSMutableDictionary *results = [NSMutableDictionary new];
    if (!data) {
        [results setValue:@"ERROR" forKey:@"status"];
        NSMutableArray *resultArray = [NSMutableArray new];
        [results setValue:resultArray forKey:@"results"];
        return results;
    }

    id response = [self objectWithData:data];
    
    if (service == GOOGLE_PlACES) {
        [results setValue:[response valueForKey:@"status"] forKey:@"status"];
        NSMutableArray *resultArray = [NSMutableArray new];
        [results setValue:resultArray forKey:@"results"];
        for(NSDictionary *attributes in [response valueForKey:@"results"])
        {
            BSLocalSearchResult *result = [BSLocalSearchResult new];
            result.formattedAddress = [attributes valueForKey:@"formatted_address"];
            result.coordinate = CLLocationCoordinate2DMake([[attributes valueForKeyPath:@"geometry.location.lat"] floatValue], [[attributes valueForKeyPath:@"geometry.location.lng"] floatValue]);
            [resultArray addObject:result];
            
        }
    }else if (service == OPEN_STREET_MAP)
    {
        [results setValue:response ? @"OK" : @"ERROR" forKey:@"status"];
        NSMutableArray *resultArray = [NSMutableArray new];
        [results setValue:resultArray forKey:@"results"];
        for(NSDictionary *attributes in response)
        {
            BSLocalSearchResult *result = [BSLocalSearchResult new];
            result.formattedAddress = [attributes valueForKey:@"display_name"];
            result.coordinate = CLLocationCoordinate2DMake([[attributes valueForKeyPath:@"lat"] floatValue], [[attributes valueForKeyPath:@"lon"] floatValue]);
            [resultArray addObject:result];
        }
    } else if(service == YELP)
    {
        if ([response valueForKey:@"error"]) {
            [results setValue:[response valueForKey:@"error"] forKey:@"status"];
        }else
            [results setValue:@"OK" forKey:@"status"];
        
        NSMutableArray *resultArray = [NSMutableArray new];
        [results setValue:resultArray forKey:@"results"];
        for(NSDictionary *attributes in [response valueForKey:@"businesses"])
        {
            BSLocalSearchResult *result = [BSLocalSearchResult new];
            result.formattedAddress = [[attributes valueForKeyPath:@"location.display_address"] componentsJoinedByString:@", "];
            result.coordinate = CLLocationCoordinate2DMake([[attributes valueForKeyPath:@"location.coordinate.latitude"] floatValue], [[attributes valueForKeyPath:@"location.coordinate.longitude"] floatValue]);
            [resultArray addObject:result];
        }
    } else if (service == FACTUAL) {
        [results setValue:[[response valueForKey:@"status"] isEqualToString:@"ok"] ? @"OK" : @"ERROR" forKey:@"status"];
        NSMutableArray *resultArray = [NSMutableArray new];
        [results setValue:resultArray forKey:@"results"];
        for(NSDictionary *attributes in [response valueForKeyPath:@"response.data"])
        {
            BSLocalSearchResult *result = [BSLocalSearchResult new];
            NSMutableArray *addressComponents = [NSMutableArray arrayWithObjects:[attributes valueForKey:@"address"], [NSString stringWithFormat:@"%@ %@", [attributes valueForKey:@"locality"], [attributes valueForKey:@"postcode"]], [attributes valueForKey:@"region"], [attributes valueForKey:@"country"], nil];
            result.formattedAddress = [addressComponents componentsJoinedByString:@", "];
            result.coordinate = CLLocationCoordinate2DMake([[attributes valueForKeyPath:@"latitude"] floatValue], [[attributes valueForKeyPath:@"longitude"] floatValue]);
            result.name = [attributes valueForKey:@"name"];
            [resultArray addObject:result];
        }
    }
    
    return results;
}

- (void)submitTextSearch:(NSString*)query completionHandler:(BSLocalSearchCallback)handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id result = [self executeTextSearch:query];
        handler(result);
    });
}

- (void)submitTextSearch:(NSString *)query
{
    [self submitTextSearch:query completionHandler:^(id response){
        if(delegate)
            [delegate searchReturnedWithResponse:response];
    }];
}

@end
