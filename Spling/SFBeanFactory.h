//
//  SFBeanFactory.h
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SFBeanFactory <NSObject>

- (id)getBeanWithProtocol:(Protocol *)proto error:(NSError **)error;

@end
