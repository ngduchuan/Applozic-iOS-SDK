//
//  ALLinkCell.h
//  Applozic
//
//  Created by apple on 22/11/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ALMediaBaseCell.h"
#import <ApplozicCore/ApplozicCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALLinkCell : ALMediaBaseCell

- (instancetype)populateCell:(ALMessage *)alMessage viewSize:(CGSize)viewSize;

@property(strong,nonatomic) UITapGestureRecognizer *tapperForLocationMap;


@end

NS_ASSUME_NONNULL_END
