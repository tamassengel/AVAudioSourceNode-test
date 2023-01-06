#import <UIKit/UIKit.h>

@interface SoundFontHelper : NSObject

+ (instancetype)sharedInstance;

- (void)playSound;
- (NSData *)getSound:(int)length;

@end
