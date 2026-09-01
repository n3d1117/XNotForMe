#import <UIKit/UIKit.h>
#import <float.h>

static id LastDeepScrollState;
static NSString *TimelineTabKey = @"THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier";
static NSString *FollowingTimelineTabValue = @"latest";
static NSInteger MostRecentTimelineVariant = 1;

static NSInteger FollowingIndex(NSInteger index) {
    return index == 0 ? 1 : index;
}

static BOOL StateIsAtTop(id state) {
    id value = [state isKindOfClass:NSDictionary.class] ? [state objectForKey:@"atTopLeft"] : nil;
    return [value respondsToSelector:@selector(boolValue)] && [value boolValue];
}

static CGFloat StateContentOffsetY(id state) {
    id value = [state isKindOfClass:NSDictionary.class] ? [state objectForKey:@"contentOffset"] : nil;

    if ([value isKindOfClass:NSString.class]) {
        return CGPointFromString(value).y;
    }

    if ([value isKindOfClass:NSValue.class]) {
        return [value CGPointValue].y;
    }

    return 0;
}

static BOOL ShouldPreserveScrollState(id state) {
    return state && !StateIsAtTop(state) && StateContentOffsetY(state) > 0;
}

%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController
/* Show only Following. */
- (NSInteger)numberOfTabsIn:(id)controller {
    NSInteger count = %orig;
    return count > 1 ? 1 : count;
}

- (UIViewController *)segmentedViewController:(id)controller pageViewControllerAtIndex:(NSInteger)index {
    return %orig(controller, FollowingIndex(index));
}

- (id)segmentedViewController:(id)controller descriptorAtIndex:(NSInteger)index {
    return %orig(controller, FollowingIndex(index));
}

- (BOOL)tfn_supportsTabBarCollapsing {
    return NO;
}

/* Hide the Following pill tab bar (segmented control + add-tab button). */
- (id)tfn_navigationBarAccessoryView {
    return nil;
}

/* Keep Following selected. */
- (void)clearLastSelectedTabIdentifier {
}

- (void)selectTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    %orig(MostRecentTimelineVariant, shouldRefresh);
}

- (void)selectFilteredTimelineVariant:(NSInteger)variant shouldRefresh:(BOOL)shouldRefresh {
    %orig(MostRecentTimelineVariant, shouldRefresh);
}
%end

%hook THFURTHomeTimelineStream
/* Save scroll state. */
- (void)setVisibleScrollPositionState:(id)state {
    if (ShouldPreserveScrollState(state)) {
        LastDeepScrollState = state;
    }

    if (StateIsAtTop(state) && LastDeepScrollState) {
        return;
    }

    if (state) {
        %orig;
    }
}

- (id)getVisibleScrollPositionState {
    id state = %orig;

    if (ShouldPreserveScrollState(state)) {
        LastDeepScrollState = state;
    }

    if (StateIsAtTop(state) && LastDeepScrollState) {
        state = LastDeepScrollState;
    }

    return state;
}

/* Keep Following in chronological order. */
- (BOOL)enableRankedFollowingTimeline {
    return NO;
}
%end

%hook TFNTwitterAccount
- (NSInteger)restartFromTopNavigationMinBackgroundMinutes {
    return -1;
}
%end

%hook TwitterHomeFeatures
/* Keep cached timeline data across launches. */
- (BOOL)coldStartEarlyCacheTruncationEnabled {
    return NO;
}

- (double)coldStartStaleCacheThresholdMinutes {
    return DBL_MAX;
}

- (BOOL)clearCacheAfterManualJTTEnabled {
    return NO;
}

- (BOOL)clearCacheAutoloadBottomAfterManualJTTEnabled {
    return NO;
}

/* Block background refreshes that reset scroll position. */
- (double)homeTimelineForegroundRefreshMinBackgroundSeconds {
    return DBL_MAX;
}

- (double)homeTimelineWarmStartMinBackgroundMinutes {
    return DBL_MAX;
}

- (NSInteger)restartFromTopNavigationMinBackgroundMinutes {
    return NSIntegerMax;
}

- (NSInteger)jumpToTopNavigationMinBackgroundMinutes {
    return NSIntegerMax;
}

- (double)homeTimelineFetchNewerOnNavigateMinMinutes {
    return DBL_MAX;
}

- (BOOL)isHomeTimelineFetchNewerOnNavigationEnabled {
    return NO;
}
%end

%hook NSUserDefaults
/* Persist Following as the selected timeline. */
- (id)objectForKey:(NSString *)key {
    if ([key isEqualToString:TimelineTabKey]) {
        return FollowingTimelineTabValue;
    }

    return %orig;
}

- (NSString *)stringForKey:(NSString *)key {
    if ([key isEqualToString:TimelineTabKey]) {
        return FollowingTimelineTabValue;
    }

    return %orig;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:TimelineTabKey]) {
        %orig(FollowingTimelineTabValue, key);
        return;
    }

    %orig(value, key);
}

- (void)removeObjectForKey:(NSString *)key {
    if ([key isEqualToString:TimelineTabKey]) {
        return;
    }

    %orig(key);
}
%end

%hook THFHomeTimelineFilterStateProvider
/* Keep Following in chronological order. */
- (BOOL)isRankedFollowingTimelineEnabled {
    return NO;
}
%end
