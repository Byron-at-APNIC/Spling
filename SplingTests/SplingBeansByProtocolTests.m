//
//  SplingBeansByProtocolTests.m
//  Spling
//
//  Created by Byron Ellacott on 20/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingBeansByProtocolTests.h"
#import "SFAutowire.h"
#import "SFComponent.h"
#import "SplingContextImpl.h"

@protocol FindMe <NSObject> @end
@protocol Lists <NSObject> @end

@interface ByProtocolBase : NSObject @end
@implementation ByProtocolBase @end

@interface SplingListComponent : ByProtocolBase <SFComponent, Lists> @end
@implementation SplingListComponent @end

@interface SplingLerstsComponent : ByProtocolBase <SFComponent, Lists> @end
@implementation SplingLerstsComponent @end

@interface SplingContextByProtocol : ByProtocolBase <SFComponent, FindMe>

@property (strong, nonatomic) id<SFAutowire, FindMe> me;
@property (strong, nonatomic) NSArray<SFAutowire, Lists> *thee;
@property (strong, nonatomic) NSSet<Lists> *we;
@property (strong, nonatomic) NSSet<SFAutowire, Lists, FindMe> *overkill;
@property (strong, nonatomic) NSSet<SFAutowire, Lists> *justRight;
@property (strong, nonatomic) id<SFAutowire, Lists> tooMany;
@property (nonatomic) BOOL truth;

@end

@implementation SplingContextByProtocol @end

@implementation SplingBeansByProtocolTests

- (void)testByProtocolSuccess
{
    SplingContextImpl *context = [[SplingContextImpl alloc] initWithBaseClass:[ByProtocolBase class]];
    STAssertNotNil(context, @"Created a SplingContextImpl");

    NSError *error = nil;
    NSObject *bean = [context getBeanWithProtocol:@protocol(FindMe) error:&error];
    STAssertNotNil(bean, @"Bean should exist");
    STAssertTrue([bean conformsToProtocol:@protocol(FindMe)], @"Bean confirms to FindMe protocol");
    STAssertTrue([bean isKindOfClass:[SplingContextByProtocol class]], @"Bean is the right class");
    SplingContextByProtocol *o = (SplingContextByProtocol *)bean;
    STAssertNotNil(o.me, @"me property is not nil");
    STAssertNotNil(o.thee, @"thee property is not nil");
    STAssertNil(o.we, @"we property is nil");
    STAssertNil(o.overkill, @"overkill property is nil");
    STAssertNotNil(o.justRight, @"justRight property is set");
    STAssertNil(o.tooMany, @"tooMany property is nil");
}


@end
