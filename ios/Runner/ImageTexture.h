//
//  ImageTexture.h
//  Runner
//
//  Created by jonasluo on 2019/12/12.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageTexture : NSObject<FlutterTexture>

+ (instancetype)textureWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
