//
//  VPTransitionInteractor.m
//  VPInteractiveImageViewController
//
//  Created by Vidu Pirathaparajah on 16/02/14.
//  Copyright (c) 2014 Vidu Pirathaparajah. All rights reserved.
//

#import "VPTransitionInteractor.h"
#import "VPInteractiveImageView.h"

@interface VPTransitionInteractor () <UIGestureRecognizerDelegate>

@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIView *pinchableView;
@property (nonatomic) CGFloat fixedScale;

@end

@implementation VPTransitionInteractor

- (id)initWithViewController:(UIViewController *)viewController pinchableView:(UIView *)pinchableView {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _pinchableView = pinchableView;
        _pinchableView.userInteractionEnabled = YES;

        [self setupGestureRecognizer];
    }
    return self;
}

- (void)setupGestureRecognizer {
    UIPinchGestureRecognizer *gestureRecognizer;
    if (self.viewController) {
        gestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(handlePinchClose:)];
        gestureRecognizer.delegate = self;
    } else {
        gestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(handlePinchOpen:)];
    }
    self.pinchableView.userInteractionEnabled = YES;
    [self.pinchableView addGestureRecognizer:gestureRecognizer];

    if (!self.viewController)
        return;

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanClose:)];
    [self.pinchableView addGestureRecognizer:panGestureRecognizer];
}

- (void)handlePinchOpen:(UIPinchGestureRecognizer *)pinch {
    CGFloat scale = pinch.scale;
    switch (pinch.state) {
        case UIGestureRecognizerStateBegan: {
            self.fixedScale = 5;
            self.isInteractiveTransition = YES;
            [(VPInteractiveImageView *)self.pinchableView presentFullscreen];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat percent = (1.0f / _fixedScale) * scale;
            [self updateInteractiveTransition:(percent < 0.0) ? 0.0 : percent];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGFloat percent = (1.0f / _fixedScale) * scale;
            BOOL cancelled = ([pinch velocity] < 5.0 && percent <= 0.3);

            if (cancelled) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            self.isInteractiveTransition = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self cancelInteractiveTransition];
            self.isInteractiveTransition = NO;
            break;
        case UIGestureRecognizerStatePossible:
            break;
    }
}

-(void)handlePinchClose:(UIPinchGestureRecognizer *)pinch {
    CGFloat scale = pinch.scale;
    switch (pinch.state) {
        case UIGestureRecognizerStateBegan: {
            //TODO: Need to introduce a proper interface to get the scrollView
            UIScrollView *scrollView = (UIScrollView *)self.pinchableView.superview;
            if (scale >= 1 || scrollView.zoomScale > scrollView.minimumZoomScale) {
                pinch.enabled = NO;
                pinch.enabled = YES;
                return;
            } else {
                scrollView.pinchGestureRecognizer.enabled = NO;
                scrollView.pinchGestureRecognizer.enabled = YES;
            }
            self.fixedScale = scale;
            self.isInteractiveTransition = YES;
            [self.viewController dismissViewControllerAnimated:YES
                                                    completion:NULL];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat percent = (1.0 - scale/_fixedScale);
            [self updateInteractiveTransition:(percent < 0.0) ? 0.0 : percent];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGFloat percent = (1.0 - scale/_fixedScale);
            BOOL cancelled = ([pinch velocity] < 5.0 && percent <= 0.3);

            if (cancelled) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            self.isInteractiveTransition = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self cancelInteractiveTransition];
            self.isInteractiveTransition = NO;
            break;
        case UIGestureRecognizerStatePossible:
            break;
    }
}

- (void)handlePanClose:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat translationY = [gestureRecognizer translationInView:self.pinchableView].y;
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            //TODO: Need to introduce a proper interface to get the scrollView
            UIScrollView *scrollView = (UIScrollView *)self.pinchableView.superview;
            if (scrollView.zoomScale > scrollView.minimumZoomScale) {
                gestureRecognizer.enabled = NO;
                gestureRecognizer.enabled = YES;
                return;
            }
            self.isInteractiveTransition = YES;
            [self.viewController dismissViewControllerAnimated:YES
                                                    completion:NULL];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat percent = ((1.0f/200) * translationY);
            percent = (percent > 100) ? 100 : percent;
            percent = (percent < 0) ? 0 : percent;
            [self updateInteractiveTransition:percent];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGFloat percent = (1.0 - translationY/200);
            BOOL cancelled = ([gestureRecognizer velocityInView:self.pinchableView].y < 5.0 && percent <= 0.3);
            if (cancelled) {
                [self cancelInteractiveTransition];
            } else {
                [self finishInteractiveTransition];
            }
            self.isInteractiveTransition = NO;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self cancelInteractiveTransition];
            self.isInteractiveTransition = NO;
            break;
        case UIGestureRecognizerStatePossible:
            break;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
