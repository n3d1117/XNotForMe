#import <UIKit/UIKit.h>

@interface TFNScrollingSegmentedViewController : UIViewController
@end

%hook TFNScrollingSegmentedViewController
// Hides the sub bar with tabs
- (BOOL)_tfn_shouldHideLabelBar { return YES; }

// Sets the number of tabs in the sub bar
- (NSInteger)pagingViewController:(id)arg1 numberOfPagesInSection:(id)arg2 { 
    if ([self.parentViewController isKindOfClass:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
        return 1; 
    }

    return %orig;
}

// Returns the "Following" tab's view controller for the "For You" tab
- (UIViewController *)pagingViewController:(UIViewController *)viewController viewControllerAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.parentViewController isKindOfClass:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
        indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    }

    return %orig(viewController, indexPath);
}
%end
