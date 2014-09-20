//
//  Document.m
//  RoundTripEditingDemo
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import "Document.h"
#import <RoundTripEditing/RoundTripEditing.h>

@interface Document ()

@property (weak) IBOutlet NSWindow *mainWindow;
@property (weak) IBOutlet LineView *lineView;

@property (nonatomic, copy) NSArray *lines;

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    self.lineView.lines = self.lines;
    NSToolbar *toolbar = self.mainWindow.toolbar;
    for (NSToolbarItem *item in toolbar.items) {
        if (item.tag == 0) {
            toolbar.selectedItemIdentifier = item.itemIdentifier;
            break;
        }
    }
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    return [NSKeyedArchiver archivedDataWithRootObject:self.lineView.lines ?: [NSArray array]];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    
    NSArray *lines = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"lines=%@", lines);
    self.lines = lines;
    return YES;
}

#pragma mark - Actions

- (IBAction)chooseEditMode:(id)sender {
    NSLog(@"tag=%li", [sender tag]);
    self.lineView.editMode = [sender tag];
}

@end
