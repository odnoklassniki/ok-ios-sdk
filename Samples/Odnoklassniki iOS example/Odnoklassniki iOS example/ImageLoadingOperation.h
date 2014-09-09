
typedef void (^OKImageLoadingBlock)(UIImage *image, NSURL *originalURL, NSError *error);


@interface ImageLoadingOperation : NSOperation
+ (instancetype)operationWithImageURL:(NSURL *)imageURL completion:(OKImageLoadingBlock)completion;
@end