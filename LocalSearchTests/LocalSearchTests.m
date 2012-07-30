//
//  LocalSearchTests.m
//  LocalSearchTests
//
//  Created by Kayle Gishen on 6/28/12.
//  Copyright (c) 2012 Kayle Gishen. All rights reserved.
//

#import "LocalSearchTests.h"
#import "BSLocalSearch.h"
#import "Exceptions.h"

static NSString* google_api_key = @"AIzaSyBvXdcfOZg_J3BGJLhH1vs-5UZ2_R0S-e8";

@interface BSLocalSearch ()

- (id)objectWithJSONString:(NSString*)string;
- (id)executeTextSearch:(NSString*)string;

@end


@implementation LocalSearchTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    
    [super tearDown];
}

- (void)testDecodingString
{
    BSLocalSearch* search = [BSLocalSearch new];
    NSDictionary * dict = [search objectWithJSONString:@"{ \"test\": \"This is a test\" }"];
    
    STAssertNotNil(dict, @"The dictionary representation should not be nil");
    STAssertNotNil([dict valueForKey:@"test"], @"The dictionary should have a key-value pair for key 'test'");
    
}

- (void)testUnknownException
{
    BSLocalSearch *search = [BSLocalSearch new];
    STAssertThrowsSpecificNamed([search executeTextSearch:@""], NSException, BSLocalSearchUnknownService, @"Calling search wihtout setting a service should through an exception");
}


- (void)testAPIKeyException
{
    BSLocalSearch *search = [BSLocalSearch new];
    search.service = GOOGLE_PlACES;
    STAssertThrowsSpecificNamed([search executeTextSearch:@""], NSException, BSLocalSearchMissingAPIKey, @"Calling search wihtout an API Key should through an exception");
}

//- (void)testTextSearch
//{
//    BSLocalSearch* search = [BSLocalSearch new];
//    search.service = GOOGLE_PlACES;
//    search.apiKey = google_api_key;
//    
//    
//    NSDictionary *results = [search executeTextSearch:@"starbucks near boca raton"];
//    STAssertNotNil(results, @"Search result should never be nil");
//    STAssertTrue([[results valueForKey:@"status"] isEqualToString:@"OK"], @"Search Status should be OK");
//    STAssertTrue([[results valueForKey:@"results"] count] > 0, @"There should be at least one result");
//    STAssertTrue([[[results valueForKey:@"results"] objectAtIndex:0] class] == [BSLocalSearchResult class], @"Results should be converted to instances of BSLocalSearchResult");
//}

- (void)testOpenStreetMap
{
    BSLocalSearch* search = [BSLocalSearch new];
    search.service = OPEN_STREET_MAP;
    
    NSDictionary *results = [search executeTextSearch:@"boca raton"];
    STAssertNotNil(results, @"Search result should never be nil");
    STAssertTrue([[results valueForKey:@"results"] count] > 0, @"There should be at least one result");
    STAssertTrue([[[results valueForKey:@"results"] objectAtIndex:0] class] == [BSLocalSearchResult class], @"Results should be converted to instances of BSLocalSearchResult");
}

- (void)testYelp
{
    BSLocalSearch* search = [BSLocalSearch new];
    search.service = YELP;
    search.consumerKey = @"CONSUMER_KEY";
    search.consumerSecret = @"CONSUMER_SECRET";
    search.token = @"TOKEN";
    search.tokenSecret = @"TOKEN_SECRET";
    
    NSDictionary *results = [search executeTextSearch:@"starbucks near boca raton"];
    STAssertNotNil(results, @"Search result should never be nil");
    STAssertTrue([[results valueForKey:@"results"] count] > 0, @"There should be at least one result");
    STAssertTrue([[[results valueForKey:@"results"] objectAtIndex:0] class] == [BSLocalSearchResult class], @"Results should be converted to instances of BSLocalSearchResult");
}

- (void)testFactual
{
    BSLocalSearch *search = [BSLocalSearch new];
    search.service = FACTUAL;
    search.consumerKey = @"KEY";
    search.consumerSecret = @"SECRET";
    
    NSDictionary *results = [search executeTextSearch:@"starbucks near boca raton"];
    STAssertNotNil(results, @"Search result should never be nil");
    STAssertTrue([[results valueForKey:@"results"] count] > 0, @"There should be at least one result");
    STAssertTrue([[[results valueForKey:@"results"] objectAtIndex:0] class] == [BSLocalSearchResult class], @"Results should be converted to instances of BSLocalSearchResult");
    
}

@end
