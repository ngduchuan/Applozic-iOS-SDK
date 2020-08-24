//
//  ALDeletedMessasgeBaseCell.h
//  Applozic
//
//  Created by Sunil on 21/08/20.
//  Copyright © 2020 applozic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ALMessage.h"

@interface ALDeletedMessasgeBaseCell : UITableViewCell
@property (nonatomic,retain) UIImageView * mBubleImageView;
@property (retain, nonatomic) UILabel * mMessageLabel;
@property (nonatomic,retain) UIImageView * mDeletedIcon;
@property (retain, nonatomic) UILabel * mDateLabel;

-(void)update:(ALMessage *)message;
-(void)addViewConstraints;
-(void)setupView;

@end
