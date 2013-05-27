//
//  SplingContextTests.m
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingContextTests.h"

#import <objc/runtime.h>

#import "SFSplingContext.h"
#import "SplingContextImpl.h"
#import "SFComponent.h"

@interface SplingContextTestsCircularBase : NSObject @end
@interface SplingContextTestsHead : SplingContextTestsCircularBase <SFComponent> @property (strong) id tail; @end
@interface SplingContextTestsTail : SplingContextTestsCircularBase <SFComponent> @property (strong) id head; @end

@interface SplingContextTestsBase : NSObject @end
@interface SplingContextFirstComponent : SplingContextTestsBase <SFComponent> @end
@interface SplingContextSecondComponent : SplingContextTestsBase <SFComponent> @end
@interface SplingContextWiredComponent : SplingContextTestsBase <SFComponent> @end
@interface SplingContextOutsiderComponent : NSObject <SFComponent> @end

@implementation SplingContextTestsCircularBase @end
@implementation SplingContextTestsHead @end
@implementation SplingContextTestsTail @end

@implementation SplingContextTestsBase @end
@implementation SplingContextFirstComponent @end
@implementation SplingContextSecondComponent @end
@implementation SplingContextOutsiderComponent @end
@implementation SplingContextWiredComponent @end

@implementation SplingContextTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAmbiguity
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextTestsBase class]];
    STAssertNotNil(context, @"Created a SplingContext");

}

- (void)testNonBean
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextTestsBase class]];
    STAssertNotNil(context, @"Created a SplingContext");
    
}

- (void)testOutsiderBean
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextTestsBase class]];
    STAssertNotNil(context, @"Created a SplingContext");
    
}

- (void)testWiredBean
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextTestsBase class]];
    STAssertNotNil(context, @"Created a SplingContext");

}

- (void)testCircularity
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextTestsCircularBase class]];
    STAssertNotNil(context, @"Created a SplingContext");
    
}


@end
