//
//  BeanFactory.h
//  spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BeanFactory <NSObject>

- (id)getBeanWithClass:(Class)class error:(NSError **)error;

@end
