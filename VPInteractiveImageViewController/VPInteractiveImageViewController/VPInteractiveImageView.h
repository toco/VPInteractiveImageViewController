//
//  VPInteractiveImageView.h
//  VPInteractiveImageViewController
//
//  Created by Vidu Pirathaparajah on 27/01/14.
//  Copyright (c) 2014 Vidu Pirathaparajah. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPInteractiveImageView : UIImageView

@property (nonatomic) UIViewController *presentingViewController;

- (void)presentFullscreen;
@end
