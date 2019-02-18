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

static NSString *const NeteaseMusicScriptClickMenu = \
@"tell application \"System Events\" to tell process \"NeteaseMusic\"\n"
@"    tell menu bar 1\n"
@"        tell menu bar item 4\n"
@"            tell menu 1\n"
@"                click menu item 1\n"
@"            end tell\n"
@"        end tell\n"
@"    end tell\n"
@"end tell\n";

static NSString *const NeteaseMusicAppName = @"Netease Music";
static NSString *const NeteaseMusicAppBoundId = @"com.netease.163music";

@implementation BGMNeteaseMusic {
    NSAppleScript* scriptIsPlaying;
    NSAppleScript* scriptClickMenu;
}

- (instancetype) init {
    if ((self = [super initWithMusicPlayerID:[BGMMusicPlayerBase makeID:@"D967B6D5-8834-4176-9546-E350BB2EC657"]
                                        name:NeteaseMusicAppName
                                    bundleID:NeteaseMusicAppBoundId])) {
        scriptIsPlaying = [[NSAppleScript alloc] initWithSource:NetseaeMusicScriptIsPlaying];
        scriptClickMenu = [[NSAppleScript alloc] initWithSource:NeteaseMusicScriptClickMenu];
    }
    return self;
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
- (BOOL) commonClickMenu:(NSString*)debugFunctionName {
    NSDictionary *error = nil;
    NSAppleEventDescriptor *result = [self->scriptClickMenu executeAndReturnError:&error];
    if (result == nil) {
        DebugMsg("BGMNeteaseMusic::%s run apple scripe error: %s", debugFunctionName.UTF8String, [[NSString stringWithFormat:@"%@", error] UTF8String]);

        // workaround for "Unused Parameter" Warning in Release mode
        (void)debugFunctionName;
    }
    return result != nil;
}

- (BOOL) pause {
    if ([self isPlaying]) {
        return [self commonClickMenu:@"pause"];
    }
    return false;
}

- (BOOL) unpause {
    if ([self isPaused]) {
        return [self commonClickMenu:@"unpause"];
    }
    return false;
}

@end
