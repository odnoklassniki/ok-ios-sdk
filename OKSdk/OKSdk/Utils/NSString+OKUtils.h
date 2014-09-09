
#import <Foundation/Foundation.h>

@interface NSString (OKUtils)

- (NSString *)md5;
- (NSDictionary *)dictionaryByParsingURLQueryPart;
- (NSString *)stringByURLDecodingString;
- (NSString *)URLEncodedString;

@end
