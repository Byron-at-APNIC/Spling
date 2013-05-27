//
//  SFSplingContext.h
//  Spling
//
//  Created by Byron Ellacott on 18/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFBeanFactory.h"

@protocol SFSplingContext <NSObject, SFBeanFactory>

- (id)init;
- (id)initWithBaseClass:(Class)base;

@end
