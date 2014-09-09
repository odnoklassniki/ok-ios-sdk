
#import "ImageLoadingOperation.h"

@interface ImageLoadingOperation()
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, copy) OKImageLoadingBlock completion;
@end

@implementation ImageLoadingOperation

+ (instancetype)operationWithImageURL:(NSURL *)imageURL completion:(OKImageLoadingBlock)completion {
    ImageLoadingOperation *operation = [[self class] new];
    operation.imageURL = imageURL;
    operation.completion = completion;
    return operation;
}

- (void)main {
    NSData *data = [NSData dataWithContentsOfURL:self.imageURL];
    if (self.isCancelled) {
        return;
    }

    UIImage *img = [[UIImage alloc] initWithData:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isCancelled && self.completion) {
            self.completion(img, self.imageURL, nil);
        }
    });

}

@end