#import <UIKit/UIKit.h>

@interface TFNScrollingSegmentedViewController : UIViewController
- (void)setSelectedIndex:(NSInteger)index;
- (NSInteger)selectedIndex;
@end

@interface THFTimelineViewController : UIViewController
- (void)_pullToRefresh:(id)sender;
@end

// Helper function to check if current view controller is homepage timeline container
static inline BOOL isHomeTimelineContainer(UIViewController *vc) {
    return [vc.parentViewController isKindOfClass:NSClassFromString(@"THFHomeTimelineContainerViewController")];
}

// Helper function to refresh layout after a delay on main thread
static void refreshLayoutAfterDelay(UIView *view, NSTimeInterval delaySeconds) {
    if (!view) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view setNeedsLayout];
        [view layoutIfNeeded];
    });
}

%hook TFNScrollingSegmentedViewController

// Hide tab bar labels only on homepage timeline container
- (BOOL)_tfn_shouldHideLabelBar {
    return isHomeTimelineContainer(self) ? YES : %orig;
}

// Always load "Following" tab content for homepage timeline container; otherwise default behavior.
- (UIViewController *)pagingViewController:(id)viewCtrl viewControllerAtIndexPath:(NSIndexPath *)indexPath {
    if (isHomeTimelineContainer(self)) {
        NSIndexPath *followingTab = [NSIndexPath indexPathForRow:1 inSection:0]; // Following tab index path
        return %orig(viewCtrl, followingTab);
    }
    
    return %orig(viewCtrl, indexPath);
}

// Ensure selected tab defaults to "Following" upon loading homepage timeline container.
- (void)viewDidLoad {
    %orig;

    if (isHomeTimelineContainer(self)) {
        [self setSelectedIndex:1]; // Set directly to Following tab at startup
    }
}

// Fix potential white screen issue by forcing layout update shortly after appearing.
- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);

    if (isHomeTimelineContainer(self)) {
        [self setSelectedIndex:1]; 
        refreshLayoutAfterDelay(self.view, 0.1); // Slight delay ensures proper rendering 
    }
}

// Prevent changing away from "Following" tab when on homepage timeline container.
- (void)setSelectedIndex:(NSInteger)newIndex {
   NSInteger forcedIndex = isHomeTimelineContainer(self) ? 1 : newIndex;  
   %orig(forcedIndex);
}

%end

%hook THFTimelineViewController

// Fix pull-to-refresh functionality by ensuring proper layout updates afterward.
- (void)_pullToRefresh:(id)sender { 
   %orig(sender);
   refreshLayoutAfterDelay(self.view, 0.5); // Delay slightly longer for reliable UI update after refreshing data 
}

%end
