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
    for (NSObject<SFComponent> *bean in self.beans) {
        Class class = [bean class];
        objc_property_t *props = class_copyPropertyList(class, NULL);
        for (objc_property_t *prop = props; prop && *prop; prop++) {
            NSArray *attributes = [[NSString stringWithUTF8String:property_getAttributes(*prop)] componentsSeparatedByString:@","];
            
            if ([attributes containsObject:@"R"]) continue; // read-only property, skip it
            
            NSString *ivarname = [attributes lastObject];
            if (![ivarname hasPrefix:@"V"]) continue; // last attribute should be V<ivar name>
            
            ivarname = [ivarname substringFromIndex:1];
            Ivar ivar = class_getInstanceVariable(class, [ivarname UTF8String]);
            NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
            
            if (![ivarType hasPrefix:@"@\""]) continue; // ivar type must start with @ for object, and must have further type information
            
            if ([ivarType rangeOfString:@"<SFAutowire>"].location == NSNotFound) continue; // must conform to SFAutowire protocol

            ivarType = [ivarType stringByReplacingOccurrencesOfString:@"<SFAutowire>" withString:@""];

            // Strip off the @""
            ivarType = [ivarType substringWithRange:NSMakeRange(2, [ivarType length] - 3)];

            // Split around <
            NSArray *parts = [ivarType componentsSeparatedByString:@"<"];

            if ([parts count] != 2) continue; // must be one class name (maybe empty) and one protocol left
            
            // Get the candidates
            NSString *proto = [parts[1] substringToIndex:[parts[1] length] - 1];
            NSArray *candidates = [self.protocolMap valueForKey:proto];
            if (!candidates) continue;  // or error?
            
            NSString *propName = [NSString stringWithUTF8String:property_getName(*prop)];

            NSString *beanType = parts[0];
            if ([beanType isEqualToString:@""]) {
                if ([candidates count] != 1) continue;  // or error?
                [bean setValue:candidates[0] forKey:propName];
            } else if ([beanType isEqualToString:@"NSArray"]) {
                [bean setValue:candidates forKey:propName];
            } else if ([beanType isEqualToString:@"NSSet"]) {
                [bean setValue:[NSSet setWithArray:candidates] forKey:propName];
            }
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
