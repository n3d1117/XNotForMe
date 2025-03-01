#import <UIKit/UIKit.h>

@interface TFNScrollingSegmentedViewController : UIViewController
- (void)setSelectedIndex:(NSInteger)index;
- (NSInteger)selectedIndex;
@end

@interface THFTimelineViewController : UIViewController
- (void)_pullToRefresh:(id)sender;
@end

// Helper functions to reduce code duplication
static BOOL isHomeTimelineContainer(UIViewController *viewController) {
    return [viewController.parentViewController isKindOfClass:NSClassFromString(@"THFHomeTimelineContainerViewController")];
}

static void refreshViewIfNeeded(UIView *view, NSTimeInterval delay) {
    if (!view) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [view setNeedsLayout];
        [view layoutIfNeeded];
    });
}

%hook TFNScrollingSegmentedViewController
// Selectively hide the tab bar only on homepage
- (BOOL)_tfn_shouldHideLabelBar {
    // Only hide the label bar in the home timeline
    if (isHomeTimelineContainer(self)) {
        return YES;
    }
    
    // For all other interfaces, use default behavior
    return %orig;
}

// Sets the number of tabs in the sub bar
- (NSInteger)pagingViewController:(id)arg1 numberOfPagesInSection:(id)arg2 { 
    return %orig;
}

// Returns the "Following" tab's view controller for both tabs, but only on homepage
- (UIViewController *)pagingViewController:(UIViewController *)viewController viewControllerAtIndexPath:(NSIndexPath *)indexPath {
    if (isHomeTimelineContainer(self)) {
        // Always use the Following tab (index 1)
        NSIndexPath *followingIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        return %orig(viewController, followingIndexPath);
    }
    
    return %orig(viewController, indexPath);
}

// Ensure proper view loading and prevent white screen, only on homepage
- (void)viewDidLoad {
    %orig;
    
    if (isHomeTimelineContainer(self)) {
        [self setSelectedIndex:1];
    }
}

// Additional fix for view appearance to ensure content loads properly, only on homepage
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    if (isHomeTimelineContainer(self)) {
        [self setSelectedIndex:1];
        refreshViewIfNeeded(self.view, 0.1);
    }
}

// Ensure selected index is always the Following tab, only on homepage
- (void)setSelectedIndex:(NSInteger)index {
    if (isHomeTimelineContainer(self)) {
        %orig(1); // Always set to Following tab (index 1)
    } else {
        %orig(index); // Use the original index for other interfaces
    }
}
%end

// Fix refresh functionality
%hook THFTimelineViewController
- (void)_pullToRefresh:(id)sender {
    %orig;
    refreshViewIfNeeded(self.view, 0.5);
}
%end
