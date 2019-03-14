//
//  TDGLShader.h
//  TDGLRender
//
//  Created by tiandy on 2019/1/29.
//

#ifndef TDGLShader_h
#define TDGLShader_h

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

//YUV转rgb的变换矩阵
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

static NSString *const VertexShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texCoord;
 
 varying vec2 v_textureCoordinate;
 
 void main() {
     v_textureCoordinate = texCoord;
     gl_Position = position;
 }
 );
static NSString *const PixelBufferFragmentShader = SHADER_STRING
(
 precision mediump float;
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 
 varying mediump vec2 v_textureCoordinate;
 
 uniform mat3 colorConversionMatrix;
 
 void main() {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(SamplerY, v_textureCoordinate).r - (16.0/255.0);
     yuv.yz = texture2D(SamplerUV, v_textureCoordinate).rg - vec2(0.5, 0.5);
     
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);
 }
 );

//图片  fragment shader
static NSString *const ImageFragmentShader = SHADER_STRING
(
 precision mediump float;
 
 uniform sampler2D Texture;
 
 varying vec2 v_textureCoordinate;
 
 void main() {
     gl_FragColor = texture2D(Texture, v_textureCoordinate);
 }
 );


#endif /* TDGLShader_h */
