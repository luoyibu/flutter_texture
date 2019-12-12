//
//  TexturePlugin.m
//  Runner
//
//  Created by jonasluo on 2019/12/11.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "TexturePlugin.h"
#import "ImageTexture.h"

@implementation TexturePlugin
{
    NSObject<FlutterTextureRegistry> *_textures;
    NSMutableDictionary *_cache;
}

- (instancetype) initWithTextures:(NSObject<FlutterTextureRegistry> *)textures {
    if (self = [super init]) {
        _textures = textures;
        _cache = [NSMutableDictionary new];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"opengl_texture" binaryMessenger:[registrar messenger]];
    
    TexturePlugin *instance = [[TexturePlugin alloc] initWithTextures:registrar.textures];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if ([call.method isEqualToString:@"newTexture"]) {
        
        UIImage *image = [UIImage imageNamed:@"111.png"];
        ImageTexture *texture = [ImageTexture textureWithImage:image];
        int64_t textureID = [_textures registerTexture:texture];
//        [_textures textureFrameAvailable:textureID];
        result(@(textureID));
        _cache[@(textureID)] = texture;
    }
}

@end
