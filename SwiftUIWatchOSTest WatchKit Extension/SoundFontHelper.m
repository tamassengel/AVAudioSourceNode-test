#import "SoundFontHelper.h"
#define TSF_IMPLEMENTATION
#import "tsf.h"

@implementation SoundFontHelper

tsf *tinySoundFont;

// https://stackoverflow.com/a/7569010/3151675
+ (instancetype)sharedInstance
{
    static SoundFontHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[SoundFontHelper alloc] init];
    });

    return sharedInstance;
}

- (id)init {
    const char *soundFontPath = [[[NSBundle mainBundle] pathForResource:@"GMGSx" ofType:@"sf2"] UTF8String];
    tinySoundFont = tsf_load_filename(soundFontPath);
    tsf_set_output(tinySoundFont, TSF_MONO, 44100, 0);

    return self;
}

- (void)playSound {
    tsf_note_on(tinySoundFont, 0, 60, 1.0f); //preset 0, middle C
}

- (NSData *)getSound:(int)length {
    short storage[length];
    tsf_render_short(tinySoundFont, storage, length, 0);
    NSData *data = [[NSData alloc] initWithBytes:storage length:length];

    return data;
}

@end

