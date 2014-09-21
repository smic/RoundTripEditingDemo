//
//  ActionViewController.m
//  RoundTripEditingExtension
//
//  Created by Stephan Michels on 20/09/14.
//  Copyright (c) 2014 Stephan Michels. All rights reserved.
//

#import "ActionViewController.h"
#import <RoundTripEditing/RoundTripEditing.h>

@interface ActionViewController ()

@property (weak) IBOutlet LineView *lineView;

@end

@implementation ActionViewController

- (NSString *)nibName {
    return @"ActionViewController";
}

- (void)loadView {
    [super loadView];
    
    // Insert code here to customize the view
    NSExtensionItem *sharedItem = [self.extensionContext.inputItems firstObject];    
    if (sharedItem.attachments.count == 0) {
        [self cancel:nil];
        return;
    }
    
    // check if attachment is of kind PDF
    NSItemProvider *attachment = sharedItem.attachments.firstObject;
    if (![attachment hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypePDF]) {
        [self cancel:nil];
        return;
    }
    
    // load item
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [attachment loadItemForTypeIdentifier:(__bridge NSString *)kUTTypePDF options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
            // check if attachment is an instance of NSData
            if (![(id)item isKindOfClass:NSData.class]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            NSData *pdfData = (NSData *)item;
            
            CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
            CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithProvider(dataProvider);
            CGDataProviderRelease(dataProvider);
            
            // check if the pdf could be loaded
            if (!pdfDocument) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            
            // check if pdf container metadata
            CGPDFDictionaryRef pdfCatalog = CGPDFDocumentGetCatalog(pdfDocument);
            CGPDFStreamRef metadataStream = 0;
            if(!CGPDFDictionaryGetStream(pdfCatalog,"Metadata", &metadataStream)) {
                CGPDFDocumentRelease(pdfDocument);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            
            // check if metadata contains raw data
            CGPDFDataFormat format = CGPDFDataFormatRaw;
            NSData *metadata = (__bridge NSData *)CGPDFStreamCopyData(metadataStream, &format);
            if(!metadata || format != CGPDFDataFormatRaw) {
                CGPDFDocumentRelease(pdfDocument);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            
            // check if header contains our header
            NSData *header = [@"Lines" dataUsingEncoding:NSUTF8StringEncoding];
            if (metadata.length < header.length) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            
            if (![[metadata subdataWithRange:NSMakeRange(0, header.length)] isEqual:header]) {
                CGPDFDocumentRelease(pdfDocument);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self cancel:nil];
                });
                return;
            }
            NSArray *lines = [NSKeyedUnarchiver unarchiveObjectWithData:[metadata subdataWithRange:NSMakeRange(header.length, metadata.length - header.length)]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.lineView.lines = lines;
            });
        }];
    });
}

- (IBAction)chooseEditMode:(id)sender {
    self.lineView.editMode = [sender selectedSegment] == 0 ? LineViewEditModePaint : LineViewEditModeSelect;
}

- (IBAction)send:(id)sender {
    NSData *pdfData = [self.lineView exportPDF:NO];
    
    if (!pdfData) {
        NSBeep();
        return;
    }
    
    NSExtensionItem *outputItem = [[NSExtensionItem alloc] init];
    NSItemProvider *attachment = [[NSItemProvider alloc] initWithItem:pdfData typeIdentifier:(NSString *)kUTTypePDF];
    outputItem.attachments = @[attachment];
    
    NSArray *outputItems = @[outputItem];
    [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

@end

