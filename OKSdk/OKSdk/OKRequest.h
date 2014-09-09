
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OKApiErrorCode) {
    OKApiErrorCodeSessionExpired = 102
};

extern NSString * const OKApiErrorDomain;

@class OKRequest;

@protocol OKRequestDelegate<NSObject>
@optional
- (void)request:(OKRequest *)request didLoad:(id)result;
- (void)request:(OKRequest *)request didFailWithError:(NSError *)error;
@end

typedef void (^OKResultBlock)(id data);
typedef void (^OKErrorBlock)(NSError *error);

@interface OKRequest : NSObject

@property (nonatomic, weak) id<OKRequestDelegate> delegate;
@property (nonatomic, copy) OKResultBlock completionBlock;
@property (nonatomic, copy) OKResultBlock errorBlock;

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *httpMethod;

@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, assign) BOOL sessionExpired;
@property (nonatomic) BOOL hasError;
@property (nonatomic, strong) NSMutableData *responseData;


+ (NSString *)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params
			   httpMethod:(NSString *)httpMethod;

+ (NSString *)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params;

+ (OKRequest *)requestWithParams:(NSDictionary *)params
                      httpMethod:(NSString *)httpMethod
                        delegate:(id <OKRequestDelegate>)delegate
                       apiMethod:(NSString *)apiMethod;

+ (OKRequest *)requestWithParams:(NSDictionary *)params
                      httpMethod:(NSString *)httpMethod
                       apiMethod:(NSString *)apiMethod;

- (void)load;

- (void)executeWithCompletionBlock:(OKResultBlock)completionBlock errorBlock:(OKErrorBlock)errorBlock;

@end

