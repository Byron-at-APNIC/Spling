//
//  SplingTests.m
//  SplingTests
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingTests.h"

#import <objc/runtime.h>

#import "SFSplingContext.h"
#import "SplingContextImpl.h"
#import "SFComponent.h"

@interface SplingTestsBase : NSObject  @end
@interface SplingTestsComponent : SplingTestsBase <SFComponent> @end
@implementation SplingTestsBase @end
@implementation SplingTestsComponent @end

@interface SplingTests () {
    Class baseClass;
    Class testComponentClass;
    BOOL initialised;
}

@end

@implementation SplingTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testBasics
{
    initialised = NO;
    
    SplingContextImpl *context = [[SplingContextImpl alloc] init];

    STAssertNotNil(context, @"Created a SplingContext");
    
//    id bean = [context getBeanWithClass:baseClass error:nil];
//    STAssertNotNil(bean, @"An NSObject bean is created");
//    STAssertTrue([bean isKindOfClass:testComponentClass], @"Bean is of the right type");
//    STAssertTrue(initialised, @"Bean initialised itself");
}

@end
