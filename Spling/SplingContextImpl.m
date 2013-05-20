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

#import "Component.h"

@interface SplingContextImpl ()

@property (nonatomic) NSMutableDictionary *beans;
@property (nonatomic) Class baseClass;
@property (nonatomic) NSMutableDictionary *classMap;
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
        
        self.beans = [NSMutableDictionary dictionaryWithCapacity:5];
        self.classMap = [NSMutableDictionary dictionaryWithCapacity:5];
        self.protocolMap = [NSMutableDictionary dictionaryWithCapacity:5];
        
        // Load all <Component> classes beneath base
        [self loadAllBeans];
        
        // Autowire all loaded beans with dependencies - may throw an exception
        [self autowireAllBeans];
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
            if (class_conformsToProtocol(classes[i], @protocol(Component))) {
                for (Class tester = classes[i]; tester; tester = class_getSuperclass(tester)) {
                    if (tester == self.baseClass) {
                        NSString *className = [NSString stringWithUTF8String:class_getName(classes[i])];
                        
                        // Sanity check: each class should only exist once!
                        if ([self.beans valueForKey:className] != nil) {
                            @throw [NSException exceptionWithName:@"Ambiguious bean definition"
                                                           reason:[NSString stringWithFormat:@"Class name %@ used twice", className]
                                                         userInfo:nil];
                        }

                        // TODO: factory initialisers?
                        [self.beans setValue:[[classes[i] alloc] init] forKey:className];
                        
                        [self updateMapsWithBean:self.beans[className]];
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
        // Update beans by class name
        NSMutableArray *beans = [self.classMap valueForKey:NSStringFromClass(class)];
        if (!beans) beans = [NSMutableArray arrayWithCapacity:1];
        [beans addObject:bean];
        [self.classMap setValue:beans forKey:NSStringFromClass(class)];
        
        // Update beans by protocol
        Protocol * __unsafe_unretained *protocols = class_copyProtocolList(class, NULL);
        for (Protocol * __unsafe_unretained *proto = protocols; proto && *proto; proto++) {
            beans = [self.protocolMap valueForKey:NSStringFromProtocol(*proto)];
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
    [self.beans enumerateKeysAndObjectsUsingBlock:^(id key, NSObject *obj, BOOL *stop) {
        if ([[obj class] respondsToSelector:@selector(autowiredProperties)]) {
            NSDictionary *autowired = [[obj class] autowiredProperties];
            [autowired enumerateKeysAndObjectsUsingBlock:^(id key, id class, BOOL *stop) {
                id bean = [self getBeanWithClass:class error:nil];
                if (!bean) {
                    @throw [NSException exceptionWithName:@"Cannot resolve dependency"
                                                   reason:[NSString stringWithFormat:@"Bean %@, dependency %s",
                                                           [obj className], class_getName(class)]
                                                 userInfo:nil];
                }
                [obj setValue:bean forKey:key];
            }];
        }
    }];
}

- (id)getBeanWithClass:(Class)class error:(NSError **)error
{
    NSArray *beans = self.classMap[NSStringFromClass(class)];
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
