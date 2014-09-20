//
//  Line.h
//  RoundTripEditingDemo
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Line : NSObject <NSCopying, NSCoding>

@property (nonatomic) NSPoint startPoint;
@property (nonatomic) NSPoint endPoint;

@property (nonatomic) NSRect boundingRect;

@end
