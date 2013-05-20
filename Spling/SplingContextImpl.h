//
//  SplingContext.h
//  Spling
//
//  Created by Byron Ellacott on 16/05/13.
//  Copyright (c) 2013 The Wanderers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplingContext.h"

#define CONTEXT_ERROR_AMBIGUOUS ((NSInteger)-1)
#define CONTEXT_ERROR_UNKNOWN ((NSInteger)-2)

@interface SplingContextImpl : NSObject <SplingContext>

- (id)init;
- (id)initWithBaseClass:(Class)base;

@end
