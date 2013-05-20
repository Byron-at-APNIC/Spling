//
//  SplingBeansByProtocolTests.m
//  Spling
//
//  Created by Byron Ellacott on 20/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingBeansByProtocolTests.h"
#import "Component.h"
#import "SplingContext.h"

@protocol FindMe <NSObject> @end

@interface SplingContextByProtocol : NSObject <Component, FindMe> @end @implementation SplingContextByProtocol @end

@implementation SplingBeansByProtocolTests

- (void)testByProtocolSuccess
{
    SplingContext *context = [[SplingContext alloc] initWithBaseClass:[SplingContextByProtocol class]];
    STAssertNotNil(context, @"Created a SplingContext");
    
    NSError *error = nil;
    NSObject *bean = [context getBeanWithProtocol:@protocol(FindMe) error:&error];
    STAssertNotNil(bean, @"Bean should exist");
    STAssertTrue([bean conformsToProtocol:@protocol(FindMe)], @"Bean confirms to FindMe protocol");
}


@end
