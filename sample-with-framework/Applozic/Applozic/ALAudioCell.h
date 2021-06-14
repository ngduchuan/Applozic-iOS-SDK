//
//  ALAudioCell.h
//  Applozic
//
//  Created by devashish on 20/01/2016.
//  Copyright © 2016 applozic Inc. All rights reserved.
//
/*********************************************************************
 TABLE CELL CUSTOM CLASS : THIS CLASS IS FOR AUDIO MESSAGES
 AUDIO INCLUDE RECORDED OR MUSIC FILE
 **********************************************************************/

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ApplozicCore/ApplozicCore.h>
#import "ALColorUtility.h"
#import "KAProgressLabel.h"
#import "ALMediaBaseCell.h"
#import "ALMediaPlayer.h"

@interface ALAudioCell : ALMediaBaseCell <ALALMediaPlayerDelegate>

@property (nonatomic, retain) UIButton * playPauseStop;
@property (nonatomic, retain) UIProgressView *mediaTrackProgress;
@property (nonatomic, retain) UILabel *mediaTrackLength;
@property (nonatomic, retain) UILabel *mediaName;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;


- (instancetype)populateCell:(ALMessage *)alMessage viewSize:(CGSize)viewSize;

- (void) getProgressOfTrack;
- (void) mediaButtonAction;
- (void) setupProgressValueX:(CGFloat)cooridinateX andY:(CGFloat)cooridinateY;
- (void) dowloadRetryAction;
- (void) cancelAction;

@end
