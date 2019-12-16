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

@implementation GLRender
{
    FrameUpdateCallback _callback;
    EAGLContext *_context;
    CGSize _size;
    CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureRef _texture;
    CVPixelBufferRef _target;
    
    GLuint _program;
    
    GLuint _frameBuffer;
    
    CADisplayLink *_displayLink;

    int _lastUpdateTs;
    GLfloat _angle;
    
}

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
    return _target;
}

- (instancetype)initWithFrameUpdateCallback:(FrameUpdateCallback)callback
{
    if (self = [super init]) {
        _callback = callback;
        _size = CGSizeMake(1000, 1000);
        
        [self initGL];
        [self loadShaders];
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
    
    glViewport(0, 0, _size.width, _size.height);
    
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
        
    NSTimeInterval now = CFAbsoluteTimeGetCurrent();
    if (now - _lastUpdateTs <= 3) { // 3秒转一个圈
        _angle = ((now - _lastUpdateTs) / 1.5 - 1) * M_PI;
    } else {
        _angle = -M_PI;
        _lastUpdateTs = now;
    }
            
    glClearColor(0.2, 0.2, 0.2, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(_program);
    
    GLuint angleUniformLocation = glGetUniformLocation(_program, "angle");
    glUniform1f(angleUniformLocation, _angle);
    
    [self drawTriangle];
    
    glFlush();
    
    _callback();
}

- (void)drawTriangle {
    static GLfloat trangleData[] = {
        0.0f,   0.5f,   0.0f,
        -0.5f,  -0.5f,  0.0f,
        0.5f,   -0.5f,  0.0f,
    };
    
    GLuint positionAttribLocation = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(positionAttribLocation);
    
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), trangleData);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

#pragma mark - shader compilation
- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    _program = glCreateProgram();
    
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"failed to compile vertex shader");
        return NO;
    }
    
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"failed to compile fragment shader");
        return NO;
    }
    
    glAttachShader(_program, vertShader);
    glAttachShader(_program, fragShader);
    
    if (![self linkProgram:_program]) {
        NSLog(@"failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        return NO;
    }
    
    if (vertShader) {
       glDetachShader(_program, vertShader);
       glDeleteShader(vertShader);
    }
    if (fragShader) {
       glDetachShader(_program, fragShader);
       glDeleteShader(fragShader);
    }
    
    NSLog(@"load shaders succ");
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar*)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"failed to load shader. type: %i", type);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    #if defined(DEBUG)
       GLint logLength;
       glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
       if (logLength > 0) {
          GLchar *log = (GLchar *)malloc(logLength);
          glGetShaderInfoLog(*shader, logLength, &logLength, log);
          NSLog(@"Shader compile log:\n%s", log);
          free(log);
       }
    #endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
       glDeleteShader(*shader);
       return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
       return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"program validate log : \n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
