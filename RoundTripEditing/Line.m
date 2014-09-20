//
//  Line.m
//  RoundTripEditingDemo
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import "Line.h"

@implementation Line

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (!(self = [super init])) return nil;
    
    self.startPoint = [coder decodePointForKey:@"startPoint"];
    self.endPoint = [coder decodePointForKey:@"endPoint"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodePoint:self.startPoint forKey:@"startPoint"];
    [coder encodePoint:self.endPoint forKey:@"endPoint"];
}

- (id)copyWithZone:(NSZone *)zone {
    Line *line = [[Line alloc] init];
    line.startPoint = self.startPoint;
    line.endPoint = self.endPoint;
    return line;
}

- (NSRect)boundingRect {
    NSPoint startPoint = self.startPoint;
    NSPoint endPoint = self.endPoint;
    return NSMakeRect(MIN(startPoint.x, endPoint.x),
                      MIN(startPoint.y, endPoint.y),
                      ABS(startPoint.x - endPoint.x),
                      ABS(startPoint.y - endPoint.y));
}

+ (NSSet *)keyPathsForValuesAffectingBoundingRect {
    return [NSSet setWithObjects:@"startPoint", @"endPoint", nil];
}

@end
