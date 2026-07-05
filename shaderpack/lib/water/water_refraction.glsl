#version 150
#ifndef WATER_REFRACTION_GLSL
#define WATER_REFRACTION_GLSL

#include "water_common.glsl"

// Screen-space water refraction
// Depth-aware distortion with view-angle modulation

struct WaterRefraction {
    vec2 distortedUV;
    vec3 color;
    float depth;
    float distortionStrength;
};

// Compute refraction UV distortion
vec2 waterRefractionUV(vec2 screenUV, vec3 normal, vec3 viewDir, float strength, float depth) {
    // Refraction direction (Snell's law approximation)
    vec3 refractionDir = refract(-viewDir, normal, 1.0 / WATER_REFRACTIVE_INDEX);

    // Screen-space offset
    vec2 offset = refractionDir.xy * strength * 0.01;

    // Depth-based attenuation
    float depthFactor = exp(-depth * 0.1);
    offset *= depthFactor;

    return screenUV + offset;
}

// Compute water refraction
WaterRefraction waterComputeRefraction(
    vec2 screenUV, vec3 normal, vec3 viewDir,
    float depth, float roughness, float quality
) {
    WaterRefraction ref;
    ref.distortedUV = screenUV;
    ref.color = vec3(0.0);
    ref.depth = depth;
    ref.distortionStrength = waterQualityScale(quality, 0.3, 0.6, 0.8, 1.0, 1.2);

    // Distortion strength modulated by roughness
    float strength = ref.distortionStrength * (0.5 + 0.5 * roughness);

    ref.distortedUV = waterRefractionUV(screenUV, normal, viewDir, strength, depth);

    return ref;
}

#endif