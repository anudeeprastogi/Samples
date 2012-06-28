//
//  Documents.m
//  DocManager
//
//  Created by Anudeep Rastogi on 4/12/12.
//  Copyright (c) 2012 Appmosphere Inc. All rights reserved.
//

#import "Documents.h"

@implementation Documents

@synthesize documentText = _documentText;
@synthesize delegate = _delegate;

- (void)setDocumentText:(NSString *)newText {
    
    NSString* oldText = _documentText;
    _documentText = [newText copy];
    
    // Register the undo operation.
    [self.undoManager setActionName:@"Text Change"];
    [self.undoManager registerUndoWithTarget:self selector:@selector(setDocumentText:) object:oldText];
    
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError {
   
    if (!self.documentText)
        self.documentText = @"";
    
    NSData *docData = [self.documentText dataUsingEncoding:NSUTF8StringEncoding];
    return docData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError {
    
    if ([contents length] > 0)
        self.documentText = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    else
        self.documentText = @"";
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentContentsDidChange:)])
        [self.delegate documentContentsDidChange:self];

    
    return YES;
}

@end
