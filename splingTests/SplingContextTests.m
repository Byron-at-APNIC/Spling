//
//  SplingContextTests.m
//  spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingContextTests.h"

#import <objc/runtime.h>

#import "SplingContext.h"
#import "Component.h"

@interface SplingContextTests () {
    Class baseClass;
    Class firstComponentClass;
    Class secondComponentClass;
    Class outsiderComponentClass;
    Class wiredComponentClass;
}

@property (nonatomic, strong) id someProperty;

- (BOOL)addIvar:(const char *)ivar ofTypeEncoding:(const char *)typeenc toClass:(Class)class;

@end

@implementation SplingContextTests

- (void)setUp
{
    [super setUp];
    
    // Only do the remaining setup once!
    if (objc_getClass("SplingContextTestsBase") != nil) {
        baseClass = objc_getClass("SplingContextTestsBase");
        firstComponentClass = objc_getClass("SplingContextFirstComponent");
        secondComponentClass = objc_getClass("SplingContextSecondComponent");
        outsiderComponentClass  = objc_getClass("SplingContextOutsiderComponent");
        wiredComponentClass = objc_getClass("SplingContextWiredComponent");
        return;
    }
    
    baseClass = objc_allocateClassPair([NSObject class], "SplingContextTestsBase", 0);
    assert(baseClass != NULL);
    objc_registerClassPair(baseClass);
    
    firstComponentClass = objc_allocateClassPair(baseClass, "SplingContextFirstComponent", 0);
    assert(firstComponentClass != NULL);
    assert(class_addProtocol(firstComponentClass, @protocol(Component)));
    objc_registerClassPair(firstComponentClass);
    
    secondComponentClass = objc_allocateClassPair(baseClass, "SplingContextSecondComponent", 0);
    assert(secondComponentClass != NULL);
    assert(class_addProtocol(secondComponentClass, @protocol(Component)));
    objc_registerClassPair(secondComponentClass);

    outsiderComponentClass = objc_allocateClassPair([NSObject class], "SplingContextOutsiderComponent", 0);
    assert(outsiderComponentClass != NULL);
    assert(class_addProtocol(outsiderComponentClass, @protocol(Component)));
    objc_registerClassPair(outsiderComponentClass);
    
    // Define a property to go on the wired component
    const objc_property_attribute_t wiredAttributes[] = {
        {"T", @encode(id)},
        {"R", ""},
        {"V", "_firstComponent"},
        nil
    };
    const int wiredAttributeCount = sizeof(wiredAttributes) / sizeof(objc_property_attribute_t);
    
    wiredComponentClass = objc_allocateClassPair(baseClass, "SplingContextWiredComponent", 0);
    assert(wiredComponentClass != NULL);
    assert(class_addProtocol(wiredComponentClass, @protocol(Component)));
    assert([self addIvar:"_firstComponent" ofTypeEncoding:@encode(id) toClass:wiredComponentClass]);
    assert(class_addMethod(wiredComponentClass, @selector(getFirstComponent), imp_implementationWithBlock(^(id _self) {
        Ivar ivar = class_getInstanceVariable([_self class], "_firstComponent");
        return object_getIvar(_self, ivar);
    }), "@@:"));
    assert(class_addMethod(wiredComponentClass, @selector(setFirstComponent:), imp_implementationWithBlock(^(id _self, id comp) {
        object_setInstanceVariable(_self, "_firstComponent", comp);
    }), "v@:@"));
    assert(class_addProperty(wiredComponentClass, "firstComponent", wiredAttributes, wiredAttributeCount));
    Class meta = object_getClass(wiredComponentClass);
    assert(meta);
    assert(class_addMethod(meta, @selector(autowiredProperties), imp_implementationWithBlock(^(id _self) {
        NSLog(@"autowiredProperties, what ho");
        return @{@"firstComponent": firstComponentClass};
    }), "@@:"));
    objc_registerClassPair(wiredComponentClass);
    
//    NSLog(@"%s", method_getTypeEncoding(class_getInstanceMethod([self class], @selector(setSomeProperty:))));
//    NSLog(@"%s", method_getTypeEncoding(class_getInstanceMethod([self class], @selector(someProperty))));
//    NSLog(@"%s", [[self methodSignatureForSelector:@selector(setSomeProperty:)] getArgumentTypeAtIndex:2]);
    // c40@0:8r*16r*24#32
    // v24@0:8@16
}

- (BOOL)addIvar:(const char *)ivar ofTypeEncoding:(const char *)typeenc toClass:(Class)class
{
    NSUInteger size;
    NSUInteger align;
    NSGetSizeAndAlignment(typeenc, &size, &align);
    return class_addIvar(class, ivar, size, align, typeenc);
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAmbiguity
{
    SplingContext *context = [[SplingContext alloc] initWithBaseClass:baseClass];
    STAssertNotNil(context, @"Created a SplingContext");

    NSError *error = nil;
    id bean = [context getBeanWithClass:baseClass error:&error];
    STAssertNil(bean, @"Bean should not exist - ambiguous instantiation");
    STAssertNotNil(error, @"An error was returned");
    STAssertEquals(error.code, CONTEXT_ERROR_AMBIGUOUS, @"Bean is ambiguous");
}

- (void)testNonBean
{
    SplingContext *context = [[SplingContext alloc] initWithBaseClass:baseClass];
    STAssertNotNil(context, @"Created a SplingContext");
    
    NSError *error = nil;
    id bean = [context getBeanWithClass:[self class] error:&error];
    STAssertNil(bean, @"Bean should not exist - unregistered bean");
    STAssertNotNil(error, @"An error was returned");
    STAssertEquals(error.code, CONTEXT_ERROR_UNKNOWN, @"Bean is an unknown bean");
}

- (void)testOutsiderBean
{
    SplingContext *context = [[SplingContext alloc] initWithBaseClass:baseClass];
    STAssertNotNil(context, @"Created a SplingContext");
    
    NSError *error = nil;
    id bean = [context getBeanWithClass:outsiderComponentClass error:&error];
    STAssertNil(bean, @"Bean should not exist - not in base class");
    STAssertNotNil(error, @"An error was returned");
    STAssertEquals(error.code, CONTEXT_ERROR_UNKNOWN, @"Bean is an unknown bean");
}

- (void)testWiredBean
{
    SplingContext *context = [[SplingContext alloc] initWithBaseClass:baseClass];
    STAssertNotNil(context, @"Created a SplingContext");

    NSError *error = nil;
    id bean = [context getBeanWithClass:wiredComponentClass error:&error];
    STAssertNotNil(bean, @"Got a wired bean");
    STAssertNil(error, @"No error returned");
    STAssertTrue([bean isKindOfClass:wiredComponentClass], @"bean is a wired component");
    id subbean = [bean performSelector:@selector(getFirstComponent)];
    STAssertNotNil(subbean, @"Got an autowired subbean");
    STAssertTrue([subbean isKindOfClass:firstComponentClass], @"subbean is the right component");
}

@end
