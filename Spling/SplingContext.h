//
//  SplingContext.h
//  Spling
//
//  Created by Byron Ellacott on 18/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeanFactory.h"

@protocol SplingContext <NSObject, BeanFactory>

- (id)init;
- (id)initWithBaseClass:(Class)base;

@end
