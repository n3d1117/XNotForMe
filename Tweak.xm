#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TFNScrollingSegmentedViewController : UIViewController
- (id)parentViewController;
@end

%hook TFNScrollingSegmentedViewController

-(NSInteger)pagingViewController:(id)arg1 numberOfPagesInSection:(id)arg2 { 
	if([[self.parentViewController class] isEqual:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
		return 1; 
	}
	return %orig;
}

-(NSInteger)selectedIndex { 
	if([[self.parentViewController class] isEqual:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
		return 1; 
	}
	return %orig;
}

-(NSInteger)initialSelectedIndex { 
	if([[self.parentViewController class] isEqual:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
		return 1; 
	}
	return %orig;
}

-(id)pagingViewController:(id)arg1 viewControllerAtIndexPath:(id)arg2 {
	if([[self.parentViewController class] isEqual:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
		return %orig(arg1, [NSIndexPath indexPathForRow:1 inSection:0]);
	}
	return %orig;
}

%end

@interface TFNScrollingHorizontalLabelView
- (id)delegate;
@end

%hook TFNScrollingHorizontalLabelView
- (void)layoutSubviews {
	if([[self.delegate class] isEqual:NSClassFromString(@"TFNScrollingSegmentedViewController")]) {
		TFNScrollingSegmentedViewController *segmentedController = (TFNScrollingSegmentedViewController *)self.delegate;
        if ([[segmentedController.parentViewController class] isEqual:NSClassFromString(@"THFHomeTimelineContainerViewController")]) {
            return;
        }
	}
	%orig;
}
%end