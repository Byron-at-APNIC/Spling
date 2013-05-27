//
//  SplingContextImpl.m
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingContextImpl.h"

#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>

#import "SFComponent.h"

@interface SplingContextImpl ()

@property (nonatomic) Class baseClass;
@property (nonatomic) NSMutableSet *beans;
@property (nonatomic) NSMutableDictionary *protocolMap;

- (void)loadAllBeans;
- (void)autowireAllBeans;
- (void)updateMapsWithBean:(NSObject *)bean;

@end

@implementation SplingContextImpl

- (id)init
{
    return [self initWithBaseClass:[NSObject class]];
}

- (id)initWithBaseClass:(Class)base
{
    if ((self = [super init]) != nil) {
        self.baseClass = base;
        
        self.beans = [NSMutableSet setWithCapacity:5];
        self.protocolMap = [NSMutableDictionary dictionaryWithCapacity:5];
        
        // Load all <Component> classes beneath base
        [self loadAllBeans];
        
        // Autowire all loaded beans with dependencies - may throw an exception
//        [self autowireAllBeans];
    }

    return self;
}

- (void)loadAllBeans
{
    int classCount = objc_getClassList(NULL, 0);
    
    if (classCount > 0) {
        Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * classCount);
        classCount = objc_getClassList(classes, classCount);
        for (int i = 0; i < classCount; i++) {
            if (class_conformsToProtocol(classes[i], @protocol(SFComponent))) {
                for (Class tester = classes[i]; tester; tester = class_getSuperclass(tester)) {
                    if (tester == self.baseClass) {
                        // TODO: factory initialisers?
                        id<NSObject> bean = [[classes[i] alloc] init];
                        [self.beans addObject:bean];
                        
                        [self updateMapsWithBean:bean];
                    }
                }
            }
        }
        free(classes);
    }
}

- (void)updateMapsWithBean:(NSObject *)bean
{
    for (Class class = [bean class]; class; class = class_getSuperclass(class)) {        
        // Update beans by protocol
        Protocol * __unsafe_unretained *protocols = class_copyProtocolList(class, NULL);
        for (Protocol * __unsafe_unretained *proto = protocols; proto && *proto; proto++) {
            NSMutableArray *beans = [self.protocolMap valueForKey:NSStringFromProtocol(*proto)];
            if (!beans) beans = [NSMutableArray arrayWithCapacity:1];
            [beans addObject:bean];
            [self.protocolMap setValue:beans forKey:NSStringFromProtocol(*proto)];
        }
        free(protocols);
        
        // Stop iterating superclasses at the base class
        if (class == self.baseClass) break;
    }
}

- (void)autowireAllBeans
{
    /*
     // Look at ivars
     */
    
    for (id<SFComponent> bean in self.beans) {
        Class class = [bean class];
        NSLog(@"Class %s ivars", class_getName(class));
        objc_property_t *props = class_copyPropertyList(class, NULL);
        for (objc_property_t *prop = props; prop && *prop; prop++) {
            NSArray *attributes = [[NSString stringWithUTF8String:property_getAttributes(*prop)] componentsSeparatedByString:@","];
            NSLog(@"attributes: %@", attributes);
        }
        
        Ivar *ivars = class_copyIvarList([bean class], NULL);
        for (Ivar *ivar = ivars; ivar && *ivar; ivar++) {
            const char *typeEncoding = ivar_getTypeEncoding(*ivar);
            NSLog(@"type encoding: %s", typeEncoding);
        }
    }
}

- (id)getBeanWithProtocol:(Protocol *)proto error:(NSError *__autoreleasing *)error
{
    NSArray *beans = self.protocolMap[NSStringFromProtocol(proto)];
    if (!beans) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"org.the-wanderers.Spling" code:CONTEXT_ERROR_UNKNOWN userInfo:nil];
        }
        return nil;
    }
    if (beans.count > 1) {
        if (error != nil) {
            *error = [NSError errorWithDomain:@"org.the-wanderers.Spling" code:CONTEXT_ERROR_AMBIGUOUS userInfo:nil];
        }
        return nil;
    }

    return beans[0];
}

@end
