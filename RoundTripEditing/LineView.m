//
//  LineView.m
//  RoundTripEditingDemo
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import "LineView.h"
#import "Line.h"

static void *ObservationContext = &ObservationContext;

@interface LineView ()

@property (nonatomic) NSRect selectionRect;

@end

@implementation LineView

- (instancetype)initWithFrame:(NSRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    
    [self setUp];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (!(self = [super initWithCoder:coder])) return nil;
    
    [self setUp];

    return self;
}

- (void)setUp {
    [self addObserver:self
           forKeyPath:@"lines"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:ObservationContext];
    [self addObserver:self
           forKeyPath:@"selectedLines"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:ObservationContext];
    [self addObserver:self
           forKeyPath:@"selectionRect"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:ObservationContext];
}

- (void)dealloc {
    for (Line *line in self.lines) {
        [self stopObservationOfLine:line];
    }
    [self removeObserver:self
              forKeyPath:@"lines"
                 context:ObservationContext];
    [self removeObserver:self
              forKeyPath:@"selectedLines"
                 context:ObservationContext];
    [self removeObserver:self
              forKeyPath:@"selectionRect"
                 context:ObservationContext];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != ObservationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqual:@"lines"]) {
        NSArray *oldLines = change[NSKeyValueChangeOldKey];
        if (oldLines != (id)[NSNull null]) {
            for (Line *line in oldLines) {
                [self stopObservationOfLine:line];
            }
        }
        NSArray *newLines = change[NSKeyValueChangeNewKey];
        if (newLines != (id)[NSNull null]) {
            for (Line *line in newLines) {
                [self startObservationOfLine:line];
            }
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)startObservationOfLine:(Line *)line {
    [line addObserver:self
           forKeyPath:@"startPoint"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:ObservationContext];
    [line addObserver:self
           forKeyPath:@"endPoint"
              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
              context:ObservationContext];
}

- (void)stopObservationOfLine:(Line *)line {
    [line removeObserver:self
              forKeyPath:@"startPoint"
                 context:ObservationContext];
    [line removeObserver:self
              forKeyPath:@"endPoint"
                 context:ObservationContext];
}

- (void)drawRect:(NSRect)dirtyRect {
    [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
    
    NSArray *selectedLines = self.selectedLines;
    
    
    for (Line *line in self.lines) {
        if ([selectedLines containsObject:line]) {
            [[NSColor redColor] set];
            [NSBezierPath setDefaultLineWidth:3.0];
            [NSBezierPath strokeLineFromPoint:line.startPoint
                                      toPoint:line.endPoint];
        }
        
        [[NSColor blackColor] set];
        [NSBezierPath setDefaultLineWidth:0.0];
        [NSBezierPath strokeLineFromPoint:line.startPoint
                                  toPoint:line.endPoint];
    }
    
    NSRect selectionRect = self.selectionRect;
    if (self.editMode == LineViewEditModeSelect && NSWidth(selectionRect) > 0.0 && NSHeight(selectionRect) > 0.0) {
        [[NSColor blueColor] set];
        [NSBezierPath strokeRect:selectionRect];
    }
}

#pragma mark - Mouse Handling

- (void)mouseDown:(NSEvent *)event {
    NSPoint startPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if (self.editMode == LineViewEditModeSelect) {
        NSArray *lines = self.lines;
        [self.window trackEventsMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask
                                     timeout:NSEventDurationForever
                                        mode:NSEventTrackingRunLoopMode
                                     handler:^(NSEvent *event, BOOL *stop)
         {
             NSPoint endPoint = [self convertPoint:[event locationInWindow] fromView:nil];
             NSRect selectionRect = NSMakeRect(MIN(startPoint.x, endPoint.x),
                                               MIN(startPoint.y, endPoint.y),
                                               ABS(startPoint.x - endPoint.x),
                                               ABS(startPoint.y - endPoint.y));
             self.selectionRect = selectionRect;
             
             NSMutableArray *selectedLines = [NSMutableArray arrayWithCapacity:lines.count];
             for (Line *line in lines) {
                 if (NSIntersectsRect(selectionRect, line.boundingRect)) {
                     [selectedLines addObject:line];
                 }
             }
             self.selectedLines = selectedLines;
             
             if (event.type == NSLeftMouseUp) {
                 self.selectionRect = NSZeroRect;
                 *stop = YES;
             }
         }];
    } else {
        Line *line = [[Line alloc] init];
        line.startPoint = startPoint;
        line.endPoint = startPoint;
        
        NSMutableArray *newLines = [NSMutableArray arrayWithArray:self.lines];
        [newLines addObject:line];
        self.lines = newLines;
        
        self.selectedLines = nil;
        
        [self.window trackEventsMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask
                                     timeout:NSEventDurationForever
                                        mode:NSEventTrackingRunLoopMode
                                     handler:^(NSEvent *event, BOOL *stop)
         {
             NSPoint endPoint = [self convertPoint:[event locationInWindow] fromView:nil];
             line.endPoint = endPoint;
             
             if (event.type == NSLeftMouseUp) {
                 if (NSEqualPoints(line.startPoint, line.endPoint)) {
                     NSMutableArray *newLines = [NSMutableArray arrayWithArray:self.lines];
                     [newLines removeObject:line];
                     self.lines = newLines;
                 } else {
                     self.selectedLines = @[line];
                 }
                 
                 *stop = YES;
             }
         }];
    }
}

#pragma mark - Actions

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (IBAction)selectAll:(id)sender {
    NSLog(@"select all");
    self.selectedLines = self.lines;
}

- (IBAction)deselectAll:(id)sender {
    self.selectedLines = nil;
}

- (IBAction)delete:(id)sender {
    NSMutableArray *newLines = [NSMutableArray arrayWithArray:self.lines];
    [newLines removeObjectsInArray:self.selectedLines];
    self.lines = newLines;
}

- (void)deleteBackward:(id)sender {
    [self delete:sender];
}

- (void)keyDown:(NSEvent *)event {
    [self interpretKeyEvents:@[event]];
}

@end
