//
//  GLRender.h
//  Runner
//
//  Created by jonasluo on 2019/12/12.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FrameUpdateCallback)(void);

@interface GLRender : NSObject <FlutterTexture>

- (instancetype)initWithFrameUpdateCallback:(FrameUpdateCallback)callback;

- (void)startRender;

@end

NS_ASSUME_NONNULL_END
