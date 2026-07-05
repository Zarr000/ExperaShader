#version 150

// FXAA (fast approximate anti-aliasing) - original implementation inspired by common publicly known approach.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;

vec3 fxaaSample(vec2 uv) {
    return texture2D(gColor, uv).rgb;
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    vec3 rgbNW = fxaaSample(vUV + vec2(-texel.x, -texel.y));
    vec3 rgbNE = fxaaSample(vUV + vec2( texel.x, -texel.y));
    vec3 rgbSW = fxaaSample(vUV + vec2(-texel.x,  texel.y));
    vec3 rgbSE = fxaaSample(vUV + vec2( texel.x,  texel.y));
    vec3 rgbM  = fxaaSample(vUV);

    float lNW = luma(rgbNW);
    float lNE = luma(rgbNE);
    float lSW = luma(rgbSW);
    float lSE = luma(rgbSE);
    float lM  = luma(rgbM);

    float lMin = min(lM, min(min(lNW, lNE), min(lSW, lSE)));
    float lMax = max(lM, max(max(lNW, lNE), max(lSW, lSE)));

    // Edge detection
    vec2 dir;
    dir.x = -((lNW + lNE) - (lSW + lSE));
    dir.y =  ((lNW + lSW) - (lNE + lSE));

    float dirReduce = max((lNW + lNE + lSW + lSE) * 0.25 * 0.0078125, 1.0/128.0);
    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpDirMin, vec2(-8.0), vec2(8.0)) * texel;

    vec3 rgbA = 0.5 * (fxaaSample(vUV + dir * (1.0/3.0 - 0.5)) + fxaaSample(vUV + dir * (2.0/3.0 - 0.5)));
    vec3 rgbB = rgbA * 0.5 + 0.25 * (fxaaSample(vUV + dir * -0.5) + fxaaSample(vUV + dir * 0.5));

    float lA = luma(rgbA);
    float lB = luma(rgbB);

    vec3 outRGB = (lB < lMin || lB > lMax) ? rgbA : rgbB;

    FragColor = vec4(outRGB, 1.0);
}

