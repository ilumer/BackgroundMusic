// This file is part of Background Music.
//
// Background Music is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 2 of the
// License, or (at your option) any later version.
//
// Background Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Background Music. If not, see <http://www.gnu.org/licenses/>.
//

//  BGMNeteaseCloudMusic.m
//  Background Music

//  Copyright © 2019 Background Music contributors.

// Self Includes
#import "BGMNeteaseMusic.h"

// Local Includes
#import "BGMScriptingBridge.h"

// PublicUtility Includes
#import "CADebugMacros.h"


static NSString *const NetseaeMusicScriptIsPlaying = \
@"tell application \"System Events\" to tell process \"NeteaseMusic\"\n"
@"    tell menu bar 1\n"
@"        tell menu bar item 4\n"
@"            tell menu 1\n"
@"                if (menu item \"暂停\" exists) or (menu item \"Pause\" exists) then\n"
@"                    return true\n"
@"                else\n"
@"                    return false\n"
@"                end if\n"
@"            end tell\n"
@"        end tell\n"
@"    end tell\n"
@"end tell\n";

static NSString *const NeteaseMusicScriptMenuClickTemplate = \
@"tell application \"System Events\"\n"
@"    set finish to false\n"
@"    repeat with appName in {\"网易云音乐\", \"NeteaseMusic\"}\n"
@"        if UI element appName of list 1 of application process \"Dock\" exists then\n"
@"            tell UI element appName of list 1 of application process \"Dock\"\n"
@"                perform action \"AXShowMenu\"\n"
@"                tell menu 1\n"
@"                    repeat with menuName in {%@}\n"
@"                        if menu item menuName exists then\n"
@"                            click menu item menuName\n"
@"                            set finish to true\n"
@"                            exit repeat\n"
@"                        end if\n"
@"                    end repeat\n"
@"                end tell\n"
@"            end tell\n"
@"            if finish is equal to true then\n"
@"                exit repeat\n"
@"            end if\n"
@"        end if\n"
@"    end repeat\n"
@"end tell\n";

static NSString *const NeteaseMusicAppName = @"Netease Music";
static NSString *const NeteaseMusicAppBoundId = @"com.netease.163music";

@implementation BGMNeteaseMusic {
    NSAppleScript* scriptIsPlaying;
    NSAppleScript* scriptClickPlay;
    NSAppleScript* scriptClickPause;
}

- (instancetype) init {
    if ((self = [super initWithMusicPlayerID:[BGMMusicPlayerBase makeID:@"D967B6D5-8834-4176-9546-E350BB2EC657"]
                                        name:NeteaseMusicAppName
                                    bundleID:NeteaseMusicAppBoundId])) {
        scriptIsPlaying = [[NSAppleScript alloc] initWithSource:NetseaeMusicScriptIsPlaying];
        NSString* playSource = [NSString stringWithFormat:NeteaseMusicScriptMenuClickTemplate, @"\"播放\", \"Play\""];
        NSString* pauseSource = [NSString stringWithFormat:NeteaseMusicScriptMenuClickTemplate, @"\"暂停\", \"Pause\""];
        scriptClickPlay = [[NSAppleScript alloc] initWithSource:playSource];
        scriptClickPause = [[NSAppleScript alloc] initWithSource:pauseSource];
        DebugMsg("Play script: %s", [playSource UTF8String]);
        DebugMsg("Pause script: %s", [pauseSource UTF8String]);
    }
    return self;
}

- (void) onSelect {
    [super onSelect];
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt:@YES};
    AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
}

- (BOOL) isRunning {
    return [[NSRunningApplication runningApplicationsWithBundleIdentifier:(NeteaseMusicAppBoundId)] count] != 0;
}

- (BOOL) isPlaying {
    NSDictionary *error = nil;
    NSAppleEventDescriptor *result = [self->scriptIsPlaying executeAndReturnError:&error];

    if (result == nil) {
        DebugMsg("BGMNeteaseMusic::isPlaying run apple scripe error: %s", [[NSString stringWithFormat:@"%@", error] UTF8String]);
        return false;
    }

    return [result booleanValue];
}

- (BOOL) isPaused {
    return ![self isPlaying];
}
- (BOOL) commonClickMenu:(BOOL)isPlay {
    NSDictionary *error = nil;
    NSAppleEventDescriptor *result = [ isPlay ? self->scriptClickPlay : self->scriptClickPause executeAndReturnError:&error];
    if (result == nil) {
        DebugMsg(
                 "BGMNeteaseMusic::%s run apple scripe error: %s",
                 isPlay ? "unpause" : "pause",
                 [[NSString stringWithFormat:@"%@", error] UTF8String]
        );
    }
    return result != nil;
}

- (BOOL) pause {
    if ([self isPlaying]) {
        return [self commonClickMenu:false];
    }
    return false;
}

- (BOOL) unpause {
    if ([self isPaused]) {
        return [self commonClickMenu:true];
    }
    return false;
}

@end
