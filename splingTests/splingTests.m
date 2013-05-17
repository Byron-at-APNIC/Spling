//
//  splingTests.m
//  splingTests
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "splingTests.h"

#import <objc/runtime.h>

#import "SplingContext.h"
#import "Component.h"

@interface splingTests () {
    Class baseClass;
    Class testComponentClass;
    BOOL initialised;
}

@end

@implementation splingTests

- (void)setUp
{
    [super setUp];
    
    // Only do the remaining setup once!
    if (objc_lookUpClass("splingTestsBase") != nil) return;
    
    baseClass = objc_allocateClassPair([NSObject class], "splingTestsBase", 0);
    assert(baseClass != NULL);
    objc_registerClassPair(baseClass);
    
    testComponentClass = objc_allocateClassPair(baseClass, "splingTestsComponent", 0);
    assert(testComponentClass != NULL);
    assert(class_addProtocol(testComponentClass, @protocol(Component)));
    assert(class_addMethod(testComponentClass, @selector(init), imp_implementationWithBlock(^(id _self) {
        IMP parentImp = class_getMethodImplementation(baseClass, @selector(init));
        id newself = parentImp(_self, @selector(init));
        if (newself != nil) initialised = YES;
        return newself;
    }), ""));
    objc_registerClassPair(testComponentClass);
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testBasics
{
    initialised = NO;
    
    SplingContext *context = [[SplingContext alloc] init];
    
    STAssertNotNil(context, @"Created a SplingContext");
    
    id bean = [context getBeanWithClass:baseClass error:nil];
    STAssertNotNil(bean, @"An NSObject bean is created");
    STAssertTrue([bean isKindOfClass:testComponentClass], @"Bean is of the right type");
    STAssertTrue(initialised, @"Bean initialised itself");
}

@end
