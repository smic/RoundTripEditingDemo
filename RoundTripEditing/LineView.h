//
//  LineView.h
//  RoundTripEditingDemo
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, LineViewEditMode) {
    LineViewEditModeSelect = 0,
    LineViewEditModePaint,
};

@interface LineView : NSView

@property (nonatomic, copy) NSArray *lines;
@property (nonatomic, copy) NSArray *selectedLines;

@property (nonatomic) LineViewEditMode editMode;

- (NSData *)exportPDF:(BOOL)useSelectedLines;

@end
