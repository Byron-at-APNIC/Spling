//
//  SplingBeansByProtocolTests.m
//  Spling
//
//  Created by Byron Ellacott on 20/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingBeansByProtocolTests.h"
#import "SFComponent.h"
#import "SplingContextImpl.h"

@protocol FindMe <NSObject> @end
@protocol Lists <NSObject> @end

@interface SplingContextByProtocol : NSObject <SFComponent, FindMe>
@property (strong, nonatomic) id<FindMe> me;
@property (strong, nonatomic) NSArray<Lists> *thee;
@end @implementation SplingContextByProtocol @end

@implementation SplingBeansByProtocolTests

- (void)testByProtocolSuccess
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[SplingContextByProtocol class]];
    STAssertNotNil(context, @"Created a SplingContextImpl");
    
    NSError *error = nil;
    NSObject *bean = [context getBeanWithProtocol:@protocol(FindMe) error:&error];
    STAssertNotNil(bean, @"Bean should exist");
    STAssertTrue([bean conformsToProtocol:@protocol(FindMe)], @"Bean confirms to FindMe protocol");
}


@end
