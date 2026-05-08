#import <UIKit/UIKit.h>
#import <float.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface TFNItemsDataViewController : UIViewController
@property(copy, nonatomic) NSString *adDisplayLocation;
@property(copy, nonatomic) NSArray *sections;
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface T1URTTimelineStatusItemViewModel : NSObject
@property(nonatomic, readonly) BOOL isPromoted;
@end

@interface _TtC10TwitterURT25URTTimelineTrendViewModel : NSObject
@property(nonatomic, readonly) NSDictionary *scribeItem;
@end

@interface TFNTwitterStatus : NSObject
@property(readonly, nonatomic) BOOL isPromoted;
@end

static id LastDeepScrollState;
static NSString *TimelineTabKey = @"THFHomeTimelineContainerViewController.lastSelectedTimelineTabIdentifier";
static NSString *FollowingTimelineTabValue = @"latest";
static NSInteger MostRecentTimelineVariant = 1;

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

static NSString *RuntimeClassName(id object) {
    Class objectClass = [object classForCoder];

    if (!objectClass) {
        objectClass = [object class];
    }

    return NSStringFromClass(objectClass);
}

static BOOL ShouldHideWhoToFollowItem(TFNItemsDataViewController *controller, id item, NSIndexPath *indexPath) {
    BOOL isHomeTimeline = [controller.adDisplayLocation isEqual:@"TIMELINE_HOME"];
    BOOL isProfileTweets = [controller.adDisplayLocation isEqual:@"PROFILE_TWEETS"];

    if (!isHomeTimeline && !isProfileTweets) {
        return NO;
    }

    if ([RuntimeClassName(item) isEqual:@"T1URTTimelineUserItemViewModel"]) {
        return YES;
    }

    if (indexPath.section >= controller.sections.count) {
        return NO;
    }

    NSArray *section = controller.sections[indexPath.section];

    if (![section isKindOfClass:NSArray.class] || section.count != 3) {
        if (!isHomeTimeline) {
            return NO;
        }
    }

    if (isHomeTimeline) {
        for (id sectionItem in section) {
            if ([RuntimeClassName(sectionItem) isEqual:@"T1URTTimelineUserItemViewModel"]) {
                return YES;
            }
        }
    }

    if (!isProfileTweets || section.count != 3) {
        return NO;
    }

    BOOL hasHeader = [RuntimeClassName(section[0]) isEqual:@"TwitterURT.URTModuleHeaderViewModel"];
    BOOL hasCarousel = [RuntimeClassName(section[1]) isEqual:@"T1TwitterSwift.URTTimelineCarouselViewModel"];
    BOOL hasFooter = [RuntimeClassName(section[2]) isEqual:@"TwitterURT.URTModuleFooterViewModel"];

    return hasHeader && hasCarousel && hasFooter;
}

%hook TFNScrollingSegmentedViewController
- (id)initWithDataSource:(id)dataSource delegate:(id)delegate externalLabelBar:(UIView *)externalLabelBar addLabelBarToNavigationBarBlur:(BOOL)addLabelBarToNavigationBarBlur useAlternateBackgroundColor:(BOOL)useAlternateBackgroundColor {
    BOOL home = [dataSource isKindOfClass:NSClassFromString(@"_TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController")];
    return %orig(dataSource, delegate, externalLabelBar, home ? NO : addLabelBarToNavigationBarBlur, useAlternateBackgroundColor);
}

- (void)setLabelBarHideMode:(NSInteger)mode {
    for (id parent = self; parent; parent = [parent parentViewController]) {
        if ([parent isKindOfClass:NSClassFromString(@"_TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController")] && mode == 0) {
            %orig(1);
            return;
        }
    }

    %orig;
}
%end

%hook _TtC32TwitterHomeFeatureImplementation35HomeTimelineContainerViewController
- (NSInteger)numberOfEntriesForSegmentedViewController:(id)controller {
    return MIN(%orig, 1);
}

- (UIViewController *)segmentedViewController:(id)controller viewControllerAtIndex:(NSInteger)index {
    return %orig(controller, index ?: 1);
}

- (NSString *)segmentedViewController:(id)controller titleAtIndex:(NSInteger)index {
    return %orig(controller, index ?: 1);
}

- (NSAttributedString *)segmentedViewController:(id)controller attributedTitleAtIndex:(NSInteger)index {
    return %orig(controller, index ?: 1);
}

- (NSString *)segmentedViewController:(id)controller accessibilityLabelAtIndex:(NSInteger)index {
    return %orig(controller, index ?: 1);
}

- (BOOL)tfn_supportsTabBarCollapsing {
    return NO;
}

- (BOOL)tfn_supportsNavigationBarCollapsing {
    return NO;
}

- (BOOL)segmentedViewControllerShouldAutoHideNavigationBar:(id)controller {
    return NO;
}

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
%end

%hook TFNTwitterAccount
- (NSInteger)restartFromTopNavigationMinBackgroundMinutes {
    return -1;
}
%end

%hook TwitterHomeFeatures
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
- (BOOL)isRankedFollowingTimelineEnabled {
    return NO;
}
%end

%hook URTHomeTimelineStream
- (BOOL)enableRankedFollowingTimeline {
    return NO;
}
%end

/* Tab bar */
%group Tabs
%hook T1TabBarViewController
- (void)setTabViews:(NSArray *)tabViews {
    NSMutableArray *filteredTabViews = [NSMutableArray new];

    if (tabViews.count > 0) {
        [filteredTabViews addObject:tabViews[0]];

        if (tabViews.count > 1) {
            [filteredTabViews addObject:tabViews[1]];
        }
    }

    %orig(filteredTabViews);
}

- (void)setTabBarScrolling:(BOOL)scrolling {
    %orig(NO);
}

- (void)setTabBarHidden:(BOOL)hidden withDuration:(double)duration {
    %orig(NO, duration);
}

- (void)setTabBarHidden:(BOOL)hidden withDuration:(double)duration completion:(id)completion {
    %orig(NO, duration, completion);
}

- (void)setTabBarCollapseRatio:(double)ratio {
    %orig(0);
}
%end
%end

/* No new posts pill */
%group NewPosts
%hook TUIUpdateIndicator
- (void)showIfNeeded {
}

- (void)showIfNeededHideOnScroll:(BOOL)hideOnScroll {
}
%end

%hook THFHomeTimelineItemsViewController
- (void)_showNewTweetsPillIfNeeded {
}

- (BOOL)canShowUpdateIndicator:(id)updateIndicator withContentNotification:(id)contentNotification {
    return NO;
}
%end

%hook THFHomeTimelineItemsViewControllerV2
- (BOOL)canShowUpdateIndicator:(id)updateIndicator withContentNotification:(id)contentNotification {
    return NO;
}
%end
%end

/* No ads */
%group Ads
%hook TFNItemsDataViewAdapterRegistry
- (id)dataViewAdapterForItem:(id)item {
    if ([item isKindOfClass:objc_getClass("T1URTTimelineStatusItemViewModel")] && ((T1URTTimelineStatusItemViewModel *)item).isPromoted) {
        return nil;
    }

    if ([item isKindOfClass:objc_getClass("TwitterURT.URTTimelineGoogleNativeAdViewModel")]) {
        return nil;
    }

    return %orig;
}
%end

%hook TFNTwitterStatus
- (BOOL)isCardHidden {
    return [self isPromoted] ? true : %orig;
}
%end

%hook TFSTwitterAPICommandAccountStateProvider
- (BOOL)allowPromotedContent {
    return NO;
}
%end

%hook TFNTwitterAccount
- (BOOL)isVideoDynamicAdEnabled {
    return false;
}
%end
%end

/* Articles */
%group Articles
%hook TPSTwitterFeatureSwitches
- (BOOL)boolForKey:(NSString *)key {
    if ([key isEqualToString:@"articles_api_enabled"] ||
        [key isEqualToString:@"articles_consumption_enabled"] ||
        [key isEqualToString:@"articles_preview_enabled"] ||
        [key isEqualToString:@"articles_rest_api_enabled"] ||
        [key isEqualToString:@"articles_timeline_profile_tab_enabled"] ||
        [key isEqualToString:@"longform_notetweets_rich_text_timeline_enabled"]) {
        return true;
    }

    if ([key isEqualToString:@"ios_in_app_article_webview_enabled"]) {
        return false;
    }

    if ([key isEqualToString:@"photo_ignore_autoplay_settings_for_gif"]) {
        return false;
    }

    return %orig;
}
%end

%hook T1UnifiedCardsFeatures
- (BOOL)isArticleViewerEnabled {
    return true;
}
%end

%hook TFSTwitterCoreAPIConfiguration
- (BOOL)isArticlePreviewEnabled {
    return true;
}

- (BOOL)isArticleRestAPIEnabled {
    return true;
}
%end

%hook TTACoreAnatomyFeatures
- (BOOL)isArticleTweetConsumptionEnabled {
    return true;
}

- (BOOL)isLongformNotetweetsRichTextTimelineEnabled {
    return true;
}
%end

%hook T1ProfileUserViewModel
- (BOOL)shouldDisplayArticlesTab {
    return true;
}
%end
%end

/* Make GIFs obey the video autoplay setting */
%group GifAutoplay
%hook T1AccountAutoplayPolicy
- (id)initWithCurrentSettings:(id)settings currentNetworkReachabilityStatus:(id)status notificationCenter:(id)center ignoreCurrentSettingsWhenAutoplayingGif:(BOOL)ignore account:(id)account {
    return %orig(settings, status, center, NO, account);
}

- (id)initWithIgnoreCurrentSettingsWhenAutoplayingGif:(BOOL)ignore account:(id)account {
    return %orig(NO, account);
}
%end
%end

/* No who to follow */
%group WhoToFollow
%hook TFNItemsDataViewController
- (id)tableViewCellForItem:(id)item atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = %orig;
    id currentItem = item;

    if (!currentItem) {
        currentItem = [self itemAtIndexPath:indexPath];
    }

    NSString *className = RuntimeClassName(currentItem);

    if ([className isEqual:@"TwitterURT.URTTimelineGoogleNativeAdViewModel"]) {
        cell.hidden = YES;
    }

    if ([currentItem respondsToSelector:@selector(isPromoted)] && ((BOOL (*)(id, SEL))objc_msgSend)(currentItem, @selector(isPromoted))) {
        cell.hidden = YES;
    }

    if ([self.adDisplayLocation isEqualToString:@"OTHER"]) {
        if ([className isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [className isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [className isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
            cell.hidden = YES;
        }

        if ([className isEqualToString:@"TwitterURT.URTTimelineEventSummaryViewModel"]) {
            cell.hidden = YES;
        }

        if ([className isEqualToString:@"TwitterURT.URTTimelineTrendViewModel"]) {
            _TtC10TwitterURT25URTTimelineTrendViewModel *trendModel = currentItem;

            if ([[trendModel.scribeItem allKeys] containsObject:@"promoted_id"]) {
                cell.hidden = YES;
            }
        }
    }

    if (ShouldHideWhoToFollowItem(self, currentItem, indexPath)) {
        cell.hidden = YES;
    }

    if ([className isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
        cell.hidden = YES;
    }

    return cell;
}

- (double)tableView:(id)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = [self itemAtIndexPath:indexPath];
    NSString *className = RuntimeClassName(item);

    if ([className isEqual:@"TwitterURT.URTTimelineGoogleNativeAdViewModel"]) {
        return 0;
    }

    if ([item respondsToSelector:@selector(isPromoted)] && ((BOOL (*)(id, SEL))objc_msgSend)(item, @selector(isPromoted))) {
        return 0;
    }

    if ([self.adDisplayLocation isEqualToString:@"OTHER"]) {
        if ([className isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [className isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [className isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
            return 0;
        }

        if ([className isEqualToString:@"TwitterURT.URTTimelineEventSummaryViewModel"]) {
            return 0;
        }

        if ([className isEqualToString:@"TwitterURT.URTTimelineTrendViewModel"]) {
            _TtC10TwitterURT25URTTimelineTrendViewModel *trendModel = item;

            if ([[trendModel.scribeItem allKeys] containsObject:@"promoted_id"]) {
                return 0;
            }
        }
    }

    if (ShouldHideWhoToFollowItem(self, item, indexPath)) {
        return 0;
    }

    if ([className isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
        return 0;
    }

    return %orig;
}
%end
%end

/* Hide Premium offers */
%group Premium
%hook T1ProfileSummaryView
- (BOOL)shouldShowGetVerifiedButton {
    return false;
}
%end

%hook THFHomeTimelineContainerViewController
- (void)_t1_showPremiumUpsellIfNeeded {
}

- (void)_t1_showPremiumUpsellIfNeededWithScribing:(BOOL)arg1 {
}
%end
%end

/* No search history */
%group History
%hook T1SearchTypeaheadViewController
- (void)viewDidLoad {
    if ([(id)self respondsToSelector:@selector(clearActionControlWantsClear:)]) {
        [(id)self performSelector:@selector(clearActionControlWantsClear:)];
    }

    %orig;
}
%end

%hook TTSSearchTypeaheadViewController
- (void)viewDidLoad {
    if ([(id)self respondsToSelector:@selector(clearActionControlWantsClear:)]) {
        [(id)self performSelector:@selector(clearActionControlWantsClear:)];
    }

    %orig;
}
%end
%end

/* No sensitive tweet warnings */
%group SensitiveWarnings
%hook TFNTwitterStatus
- (BOOL)isPossiblySensitive {
    return NO;
}
%end

%hook TTACoreStatusViewModel
- (BOOL)isPossiblySensitiveViewModelForAccount:(id)account {
    return NO;
}

- (BOOL)hasImageInterstitial {
    return NO;
}
%end

%hook T1StatusViewModel
- (BOOL)isPossiblySensitiveViewModelForAccount:(id)account {
    return NO;
}

- (BOOL)hasImageInterstitial {
    return NO;
}
%end
%end

/* No reel-style video paging */
%group ImmersivePaging
%hook T1ImmersiveViewController
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return [gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class] ? NO : %orig;
}
%end
%end

%ctor {
    %init;
    %init(Tabs);
    %init(NewPosts);
    %init(Ads);
    %init(Articles);
    %init(GifAutoplay);
    %init(WhoToFollow);
    %init(Premium);
    %init(History);
    %init(SensitiveWarnings);
    %init(ImmersivePaging);
}
