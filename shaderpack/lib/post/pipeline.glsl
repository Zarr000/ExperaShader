#version 150

#ifndef POST_PIPELINE_GLSL
#define POST_PIPELINE_GLSL

#include "../common/math.glsl"
#include "../common/color.glsl"
#include "../common/noise.glsl"

vec3 applyAutoExposure(vec3 hdrColor, float exposureBias, float autoExposureAmount) {
    float luma = max(evaluateLuminance(hdrColor), 1e-5);
    float targetLuma = 0.18;
    float exposureScale = 1.0 / max(luma + 0.0001, targetLuma * 0.5);
    exposureScale = mix(1.0, exposureScale, saturate(autoExposureAmount));
    return hdrColor * (exposureBias * exposureScale);
}

vec3 applyChromaticAberration(sampler2D colorTex, vec2 uv, vec3 baseColor, float strength) {
    if (strength <= 0.0) {
        return baseColor;
    }

    vec2 center = uv - 0.5;
    float dist = length(center);
    vec2 dir = (dist > 1e-4) ? (center / dist) : vec2(0.0, 0.0);
    float shift = strength * 0.0025;

    vec3 shifted;
    shifted.r = texture2D(colorTex, uv + dir * shift).r;
    shifted.g = baseColor.g;
    shifted.b = texture2D(colorTex, uv - dir * shift).b;

    return mix(baseColor, shifted, saturate(strength));
}

vec3 applyFilmGrain(vec3 color, vec2 uv, float strength, float time) {
    if (strength <= 0.0) {
        return color;
    }

    vec2 grainUV = uv * vec2(1920.0, 1080.0) + vec2(time * 0.13, time * 0.07);
    float grain = hash12(grainUV) - 0.5;
    return color + vec3(grain * strength * 0.035);
}

vec3 applySharpen(sampler2D colorTex, vec2 uv, vec3 baseColor, float strength) {
    if (strength <= 0.0) {
        return baseColor;
    }

    vec2 texel = 1.0 / max(screenSize, vec2(1.0));
    vec3 center = baseColor;
    vec3 left = texture2D(colorTex, uv - vec2(texel.x, 0.0)).rgb;
    vec3 right = texture2D(colorTex, uv + vec2(texel.x, 0.0)).rgb;
    vec3 up = texture2D(colorTex, uv - vec2(0.0, texel.y)).rgb;
    vec3 down = texture2D(colorTex, uv + vec2(0.0, texel.y)).rgb;

    vec3 blurred = (left + right + up + down + center) * 0.2;
    vec3 sharpened = center + (center - blurred) * strength;
    return mix(center, sharpened, saturate(strength));
}

#endif
