
//
//  ViewController.m
//  DiskFiller
//
//  Created by Richard Turton on 07/07/2015.
//  Copyright (c) 2015 Command Shift. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *fileCount;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateStatus];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)addFile:(id)sender {
    
    [self.indicator startAnimating];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filename = [[NSUUID UUID] UUIDString];
        NSURL *fileURL = [[self documentsFolder] URLByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:nil attributes:nil];
        NSFileHandle *writer = [NSFileHandle fileHandleForWritingToURL:fileURL error:nil];
        
        for (int i = 0; i<512; i++) {
            @autoreleasepool {
                NSUInteger numberOfBytes = 1048576;
                void *bytes = malloc(numberOfBytes);
                NSData *data = [NSData dataWithBytes:bytes length:numberOfBytes];
                free(bytes);
                [writer writeData:data];
            }
        }
        [writer closeFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.indicator stopAnimating];
            [self updateStatus];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        });
    });
}

- (IBAction)clearFiles:(id)sender {
    
    [self.indicator startAnimating];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self documentsFolder] includingPropertiesForKeys:nil options:0 error:nil];
        for (NSURL *fileURL in contents) {
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.indicator stopAnimating];
            [self updateStatus];
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        });
    });

}

-(void)updateStatus {
    self.fileCount.text = [NSString stringWithFormat:@"%lu MB used",(unsigned long)[self megabytesForFilesInFolder:[self documentsFolder]]];
}

- (NSURL*)documentsFolder {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
}

- (NSUInteger)megabytesForFilesInFolder:(NSURL*)folder {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folder includingPropertiesForKeys:nil options:0 error:nil];
    
    NSUInteger megabytes = 0;
    
    for (NSURL *fileURL in contents) {
        NSNumber *size = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil][NSFileSize];
        megabytes += [size longLongValue] / 1048576;
    }
    
    return megabytes;
}

@end
