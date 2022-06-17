//
//  shaders.metal
//  BDAlphaPlayer
//
//  Created by ByteDance on 2018/6/21.
//  Copyright © 2018年 ByteDance. All rights reserved.
//

#include <metal_stdlib>
#include "BDAlphaPlayerMetalShaderType.h"

using namespace metal;

typedef struct {
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
} RasterizerData;

static inline
float sRGB_nonLinearNormToLinear(float normV)
{
  if (normV <= 0.04045f) {
    normV *= (1.0f / 12.92f);
  } else {
    const float a = 0.055f;
    const float gamma = 2.4f;
    //const float gamma = 1.0f / (1.0f / 2.4f);
    normV = (normV + a) * (1.0f / (1.0f + a));
    normV = pow(normV, gamma);
  }

  return normV;
}

vertex RasterizerData vertexShader(uint vertexID [[ vertex_id ]],
                                   constant BDAlphaPlayerVertex *vertexArray [[ buffer(BDAlphaPlayerVertexInputIndexVertices) ]]) {
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4 samplingShader(RasterizerData input [[stage_in]],
                               texture2d<float> textureY [[ texture(BDAlphaPlayerFragmentTextureIndexTextureY) ]],
                               texture2d<float> textureUV [[ texture(BDAlphaPlayerFragmentTextureIndexTextureUV) ]],
                               constant BDAlphaPlayerConvertMatrix *convertMatrix [[ buffer(BDAlphaPlayerFragmentInputIndexMatrix) ]])
{
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    
    float2 lst = input.textureCoordinate * float2(0.5, 1.0);
    float2 rst = input.textureCoordinate * float2(0.5, 1.0) + float2(0.5, 0.0);
    
    float3 yuv = float3(textureY.sample(textureSampler, lst).r,
                        textureUV.sample(textureSampler, lst).rg);
    
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    float3 alpha = float3(textureY.sample(textureSampler, rst).r,
                          textureUV.sample(textureSampler, rst).rg);
    
    float3 alphargb = convertMatrix->matrix * (alpha + convertMatrix->offset);
    
    return float4(rgb, alphargb.r);
}


