//
//  SplingContext.m
//  spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import "SplingContext.h"

#import <Foundation/NSObjCRuntime.h>
#import <objc/runtime.h>

#import "Component.h"

@interface SplingContext ()

@property (nonatomic) Class baseClass;

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

        // TODO: construct a dependency graph
        // TODO: instantiate all singleton components through the dependency graph
    }

    return self;
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
