//
//  SplingContext.m
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingContext.h"

#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>

#import "Component.h"

@interface SplingContext ()

@property (nonatomic) NSMutableDictionary *beans;
@property (nonatomic) Class baseClass;

- (void)loadAllBeans;
- (void)autowireAllBeans;

@end

@implementation SplingContext

- (id)init
{
    return [self initWithBaseClass:[NSObject class]];
}

- (id)initWithBaseClass:(Class)base
{
    if ((self = [super init]) != nil) {
        self.baseClass = base;
        
        self.beans = [NSMutableDictionary dictionaryWithCapacity:5];
        
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
                    }
                }
            }
        }
        free(classes);
    }
}

- (void)autowireAllBeans
{
    [self.beans enumerateKeysAndObjectsUsingBlock:^(id key, NSObject *obj, BOOL *stop) {
        if ([[obj class] respondsToSelector:@selector(autowiredProperties)]) {
            NSDictionary *autowired = [[obj class] autowiredProperties];
            [autowired enumerateKeysAndObjectsUsingBlock:^(id key, id class, BOOL *stop) {
                // TODO: watch out for circular dependencies
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
    // TODO: return the already instantiated singleton (or call the factory method when factory methods are introduced)
    Class *classes = NULL;
    int classCount = 0;
    id obj = nil;
    
    classCount = objc_getClassList(NULL, 0);
    
    if (error) *error = nil;
    
    if (classCount > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * classCount);
        classCount = objc_getClassList(classes, classCount);
        for (int i = 0; i < classCount; i++) {
            if (class_conformsToProtocol(classes[i], @protocol(Component))) {
                BOOL matchesClass = NO;
                BOOL matchesBase = NO;
                for (Class tester = classes[i]; tester; tester = class_getSuperclass(tester)) {
                    if (tester == class) matchesClass = YES;
                    if (tester == self.baseClass) matchesBase = YES;
                }
                
                if (matchesClass && matchesBase) {
                    if (obj != nil) {
                        // Ambiguous beans are an error condition
                        if (error) {
                            *error = [NSError errorWithDomain:@"org.the-wanderers.Spling"
                                                            code:CONTEXT_ERROR_AMBIGUOUS userInfo:nil];
                        }
                        obj = nil;
                        break;
                    }
                    obj = [[classes[i] alloc] init];
                }
            }
        }
        free(classes);
    }
    
    if (obj == nil && error != nil && *error == nil) {
        *error = [NSError errorWithDomain:@"org.the-wanderers.Spling" code:CONTEXT_ERROR_UNKNOWN userInfo:nil];
    }
    
    // Autowire the object's dependencies
    if (obj && [[obj class] respondsToSelector:@selector(autowiredProperties)]) {
        NSDictionary *autowired = [[obj class] autowiredProperties];
        __block BOOL errors = NO;
        [autowired enumerateKeysAndObjectsUsingBlock:^(id key, id class, BOOL *stop) {
            // TODO: watch out for circular dependencies
            id bean = [self getBeanWithClass:class error:error];
            if (!bean) errors = *stop = YES;
            [obj setValue:bean forKey:key];
        }];
        if (errors) obj = nil;
    }

    return obj;
}

@end
