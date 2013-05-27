//
//  SFComponent.h
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SFComponent

@optional
+ (NSDictionary *)autowiredProperties;

@end
