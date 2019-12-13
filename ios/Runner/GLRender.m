//
//  GLRender.m
//  Runner
//
//  Created by jonasluo on 2019/12/12.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

#import "GLRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

static const char *mm = "#version 330 core";

//layout (location = 0) in vec3 aPos;
//
//void main()
//{
//    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
//}
//";



@implementation GLRender
{
    FrameUpdateCallback _callback;
    EAGLContext *_context;
    CGSize _size;
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _texture;
    CVPixelBufferRef _target;
    
    GLuint _frameBuffer;
    GLuint _depthBuffer;
    
    CADisplayLink *_displayLink;
    
    int _frameCount;
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
    return _target;
}

- (instancetype)initWithFrameUpdateCallback:(FrameUpdateCallback)callback
{
    if (self = [super init]) {
        _callback = callback;
        _size = [UIScreen mainScreen].bounds.size;
        
        [self initGL];
    }
    return self;
}

- (void)initGL {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
    [self createCVBufferWith:&_target withOutTexture:&_texture];
        
    // 创建帧缓冲区
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 将纹理附加到帧缓冲区上
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);
    
    
    // 定点数据
    float vertices[] = {
        -0.5f, 0.0f, 0.0f,
        0.5f, 0.0f, 0.0f,
    };
    
    // vbo
    unsigned int VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    
    // 上传数据到vbo
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    // 创建顶点着色器
    unsigned int vertexShader;
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)createCVBufferWith:(CVPixelBufferRef *)target withOutTexture:(CVOpenGLESTextureRef *)texture {
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
    if (err) {
        return;
    }
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, _size.width, _size.height, kCVPixelFormatType_32BGRA, attrs, target);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, *target, NULL, GL_TEXTURE_2D, GL_RGBA, _size.width, _size.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, texture);
    
    CFRelease(empty);
    CFRelease(attrs);
}

- (void)deinitGL {
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteFramebuffers(1, &_depthBuffer);
    CFRelease(_target);
    CFRelease(_textureCache);
    CFRelease(_texture);
}

- (void)startRender
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
        _displayLink.preferredFramesPerSecond = 60;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)update
{
    [EAGLContext setCurrentContext:_context];
        
    _frameCount = ++_frameCount%60;
    
    glClearColor(1, 0, 0, _frameCount/60.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glFlush();
    
    _callback();
}

@end
