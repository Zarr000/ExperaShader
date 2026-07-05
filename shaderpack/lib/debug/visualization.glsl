#version 150

#ifndef DEBUG_VISUALIZATION_GLSL
#define DEBUG_VISUALIZATION_GLSL

#include "../common/math.glsl"

vec3 debugColorFromMode(
    vec3 baseColor,
    vec3 normal,
    float roughness,
    float metallic,
    float ao,
    float emissive,
    vec3 motionVector,
    float depth,
    vec3 ssgiColor,
    vec3 ssrColor,
    vec3 hizColor,
    int debugMode
) {
    if (debugMode == 1) return normalize(normal) * 0.5 + 0.5;
    if (debugMode == 2) return vec3(saturate(depth));
    if (debugMode == 3) return vec3(roughness);
    if (debugMode == 4) return vec3(metallic);
    if (debugMode == 5) return vec3(ao);
    if (debugMode == 6) return ssgiColor;
    if (debugMode == 7) return vec3(emissive);
    if (debugMode == 8) return vec3(motionVector * 0.5 + 0.5, 1.0);
    if (debugMode == 9) return hizColor;
    if (debugMode == 10) return ssrColor;
    return baseColor;
}

#endif
