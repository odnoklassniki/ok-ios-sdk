
#import "OKRequest.h"
#import "OKSession.h"
#import "NSString+OKUtils.h"

static const NSTimeInterval kRequestTimeoutInterval = 180.0;
static NSString *kUserAgent = @"OdnoklassnikiIOs";

NSString * const OKApiErrorDomain = @"ru.ok.api";

@interface OKRequest()<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation OKRequest

+ (NSString *)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params
			   httpMethod:(NSString *)__unused httpMethod {
    return [self serializeURL:baseUrl params:params];
}

+ (NSString *)serializeURL:(NSString *)baseUrl params:(NSDictionary *)params{
    NSURL *parsedURL = [NSURL URLWithString:baseUrl];
    NSString *queryPrefix = parsedURL.query ? @"&" : @"?";

    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in [params keyEnumerator]) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, [params[key] URLEncodedString]]];
    }
    NSString *query = [pairs componentsJoinedByString:@"&"];

    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

+ (NSString *)makeSignatureWithParams:(NSDictionary *)params accessToken:(NSString *)accessToken secret:(NSString *)secret {
    NSMutableString *signatureString = [NSMutableString string];

    NSArray *sortedKeys = [[params allKeys] sortedArrayUsingSelector: @selector(compare:)];
	for (NSString *key in sortedKeys) {
		[signatureString appendString:[NSString stringWithFormat:@"%@=%@", key, [params valueForKey:key]]];
	}

	[signatureString appendString:[[NSString stringWithFormat:@"%@%@", accessToken, secret] md5]];
	return [[signatureString md5] lowercaseString];
}

+ (OKRequest *)requestWithParams:(NSDictionary *)params
                      httpMethod:(NSString *)httpMethod
                        delegate:(id <OKRequestDelegate>)delegate
                       apiMethod:(NSString *)apiMethod {
	OKRequest *request = [self requestWithParams:params httpMethod:httpMethod apiMethod:apiMethod];
	request.delegate = delegate;
	return request;
}

+ (OKRequest *)requestWithParams:(NSDictionary *)params
                      httpMethod:(NSString *)httpMethod
                       apiMethod:(NSString *)apiMethod {
    OKRequest *request = [OKRequest new];
    request.params = params;

    NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
    newParams[@"application_key"] = [OKSession activeSession].appKey;

    NSString *signature = [OKRequest makeSignatureWithParams:newParams accessToken:[OKSession activeSession].accessToken secret:[OKSession activeSession].appSecret];
    newParams[@"sig"] = signature;
    newParams[@"access_token"] = [OKSession activeSession].accessToken;

    NSString *method = [apiMethod stringByReplacingOccurrencesOfString:@"." withString:@"/"];

    request.url = [OKRequest serializeURL:[NSString stringWithFormat:@"%@%@", kAPIBaseURL, method] params:newParams];
    request.httpMethod = httpMethod;
    return request;
}

- (void)load {
	self.responseData = [[NSMutableData alloc] init];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
													   timeoutInterval:kRequestTimeoutInterval];
	request.HTTPMethod = self.httpMethod ? : @"GET";
	[request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
	self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)executeWithCompletionBlock:(OKResultBlock)completionBlock errorBlock:(OKErrorBlock)errorBlock {
    self.completionBlock = completionBlock;
    self.errorBlock = errorBlock;
    [self load];
}

- (void)handleResponse:(NSMutableData *)data {
    NSError *jsonParsingError = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];

    NSError *error = [self errorFromResponseDictionary:result];
	if (error) {
        self.sessionExpired = (error.code == OKApiErrorCodeSessionExpired);
		[self failWithError:error];
	} else {
        if ([self.delegate respondsToSelector:@selector(request:didLoad:)]) {
            [self.delegate request:self didLoad:result];
        } else if (self.completionBlock) {
            self.completionBlock(result);
        }
    }
}

- (void)failWithError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [self.delegate request:self didFailWithError:error];
    } else if (self.errorBlock) {
        self.errorBlock(error);
    }
}

- (NSError *)errorFromResponseDictionary:(NSDictionary *)data {
	if ([data isKindOfClass:[NSDictionary class]]) {
        NSNumber *error = data[@"error_code"];
        if (error) {
            return [NSError errorWithDomain:OKApiErrorDomain code:[error intValue] userInfo:data];
        }
    }
	return nil;
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self handleResponse:self.responseData];

	self.responseData = nil;
	self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self failWithError:error];

	self.responseData = nil;
	self.connection = nil;
}

@end