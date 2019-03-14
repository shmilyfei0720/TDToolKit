//
//  TDGLRender.m
//  TDGLRender
//
//  Created by tiandy on 2019/1/29.
//

#import "TDGLRender.h"
#import <GLKit/GLKit.h>
#import "TDGLProgram.h"

@interface TDGLRender ()
@property (strong,nonatomic) CAEAGLLayer *renderLayer;
@property (strong,nonatomic) EAGLContext *context;
@property (strong,nonatomic) TDGLProgram *pixelBufferProgram;
@property (strong,nonatomic) TDGLProgram *imageProgram;
@end

@implementation TDGLRender{
    GLuint _vertexId;
    GLuint _texCoordId;
    GLuint _indicesId;
    GLuint _frameBuffer;
    GLuint _colorRenderBuffer;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
}

#pragma mark - setup OpenGL
-(void)buildPixelProgram {
    if ([EAGLContext currentContext] != self.context) {
        [EAGLContext setCurrentContext:self.context];
    }
    self.pixelBufferProgram = [[TDGLProgram alloc] initWithVertexShaderString:VertexShader fragmentShaderString:PixelBufferFragmentShader];
    [self.pixelBufferProgram addAttribute:@"position"]; //位置
    [self.pixelBufferProgram addAttribute:@"texCoord"]; //纹理坐标
    if (![self.pixelBufferProgram link]) {
        self.pixelBufferProgram = nil;
        NSAssert(NO, @"Falied to link HalfSpherical shaders");
    }
    [self.pixelBufferProgram use];
    glUniform1i([self.pixelBufferProgram uniformIndex:@"SamplerY"], 0);
    glUniform1i([self.pixelBufferProgram uniformIndex:@"SamplerUV"], 1);
    glUniformMatrix3fv([self.pixelBufferProgram uniformIndex:@"colorConversionMatrix"], 1, GL_FALSE, kColorConversion709);
}

-(void)buildImageProgram {
    if ([EAGLContext currentContext] != self.context) {
        [EAGLContext setCurrentContext:self.context];
    }
    self.imageProgram = [[TDGLProgram alloc] initWithVertexShaderString:VertexShader fragmentShaderString:ImageFragmentShader];
    [self.imageProgram addAttribute:@"position"]; //位置
    [self.imageProgram addAttribute:@"texCoord"]; //纹理坐标
    if (![self.imageProgram link]) {
        self.imageProgram = nil;
        NSAssert(NO, @"Falied to link HalfSpherical shaders");
    }
    [self.imageProgram use];
    glUniform1i([self.imageProgram uniformIndex:@"Texture"], 0);
}

-(void)setupVertices {
    if ([EAGLContext currentContext] != self.context) {
        [EAGLContext setCurrentContext:self.context];
    }
    GLfloat vertices[] = {-1,1,0,-1,-1,0,1,-1,0,1,1,0};
    GLfloat textCoords[] = {0,0,0,1,1,1,1,0};
    GLushort indices[] = {0,1,2,2,3,0};
    //Indices   索引数据
    glGenBuffers(1, &_indicesId);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesId);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6*sizeof(GLushort), indices, GL_STATIC_DRAW);
    // Vertex    顶点数据
    glGenBuffers(1, &_vertexId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexId);
    glBufferData(GL_ARRAY_BUFFER, 12*sizeof(GLfloat), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*3, NULL);
    
    // Texture Coordinates    纹理数据
    glGenBuffers(1, &_texCoordId);
    glBindBuffer(GL_ARRAY_BUFFER, _texCoordId);
    glBufferData(GL_ARRAY_BUFFER, 8*sizeof(GLfloat), textCoords, GL_DYNAMIC_DRAW);
    
    GLuint vertexTexCoordAttrIndex = [self.pixelBufferProgram attributeIndex:@"texCoord"];
    glEnableVertexAttribArray(vertexTexCoordAttrIndex);
    glVertexAttribPointer(vertexTexCoordAttrIndex, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*2, NULL);
}

- (void)setupVideoCache{
    if ([EAGLContext currentContext] != self.context) {
        [EAGLContext setCurrentContext:self.context];
    }
    if (_videoTextureCache) {
        return;
    }
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
    }
}

#pragma mark - 设置渲染视图
-(void)setVideoLayer:(CALayer *)layer {
    if (!self.context) {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!self.context) {
            NSLog(@"Failed to initialize OpenGLES 2.0 context");
        }
        [self buildPixelProgram];
        [self setupVertices];
        [self setupVideoCache];
    }
    if (self.renderLayer) {
        [self.renderLayer removeFromSuperlayer];
        self.renderLayer = nil;
    }
    self.renderLayer = [[CAEAGLLayer alloc] initWithLayer:layer];
    self.renderLayer.frame = layer.bounds;
    self.renderLayer.contentsScale = [UIScreen mainScreen].scale;
    self.renderLayer.opaque = YES;
    [layer addSublayer:self.renderLayer];
    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.renderLayer];
    
    glGenFramebuffers(1,&_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER,_frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,_colorRenderBuffer);
}
-(void)clearVideoLayer {
    if (self.renderLayer) {
        [self.renderLayer removeFromSuperlayer];
        self.renderLayer = nil;
    }
}

#pragma mark - render
-(void)renderPixelBuffer:(CVPixelBufferRef)frameBuffer {
    if (!self.pixelBufferProgram) {
        [self buildPixelProgram];
    }
    [self.pixelBufferProgram use];
    [self refreshTextureWithBuffer:frameBuffer];
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    float portWith = CGRectGetWidth(self.renderLayer.frame) * [UIScreen mainScreen].scale;
    float portHeight = CGRectGetHeight(self.renderLayer.frame) * [UIScreen mainScreen].scale;
    glViewport(0, 0, portWith, portHeight);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}
-(void)renderImage:(UIImage *)image {
    if (!self.imageProgram) {
        [self buildImageProgram];
    }
    [self.imageProgram use];
    [self refreshTextureWithImage:image];
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    float portWith = CGRectGetWidth(self.renderLayer.frame) * [UIScreen mainScreen].scale;
    float portHeight = CGRectGetHeight(self.renderLayer.frame) * [UIScreen mainScreen].scale;
    glViewport(0, 0, portWith, portHeight);
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark - refresh Texture
- (void)refreshTextureWithImage:(UIImage *)image {
    if (image == nil) {
        return;
    }
    
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image texture");
        return;
    }
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _vertexId);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
}

- (void)refreshTextureWithBuffer:(CVPixelBufferRef)pixelBuffer{
    if (!pixelBuffer) {
        return ;
    }
    CVReturn err;
    GLsizei textureWidth = (GLsizei)CVPixelBufferGetWidth(pixelBuffer);
    GLsizei textureHeight = (GLsizei)CVPixelBufferGetHeight(pixelBuffer);
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    
    [self cleanUpTextures];
    if([EAGLContext currentContext] != self.context){
        [EAGLContext setCurrentContext:self.context];
    }
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);  //设置活跃单元
    //获取纹理数据
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RED_EXT,
                                                       textureWidth,
                                                       textureHeight,
                                                       GL_RED_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &_lumaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    //绑定活跃纹理单元
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // UV-plane.
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       _videoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       textureWidth/2,
                                                       textureHeight/2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CFRelease(pixelBuffer);
}
- (void)cleanUpTextures {
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark - 销毁
-(void)dealloc {
    [EAGLContext setCurrentContext:self.context];
    [self cleanUpTextures];
    if (_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    glDeleteBuffers(1, &_vertexId);
    glDeleteBuffers(1, &_texCoordId);
    glDeleteBuffers(1, &_indicesId);
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteRenderbuffers(1, &_colorRenderBuffer);
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:NULL];
    }
}

@end
