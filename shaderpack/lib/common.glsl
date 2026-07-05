#version 150

// Compatibility shim for the legacy common include.
// The renderer now routes shared utilities through the modular library tree.

#ifndef COMMON_GLSL
#define COMMON_GLSL

precision highp float;

#include "common/math.glsl"
#include "common/color.glsl"
#include "common/noise.glsl"
#include "common/uniforms.glsl"

vec3 ACESFilm(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

mat3 computeTBN(vec3 n, vec3 tangent, vec3 bitangent) {
    vec3 T = normalize(tangent - n * dot(n, tangent));
    vec3 B = normalize(bitangent - n * dot(n, bitangent));
    vec3 N = normalize(n);
    return mat3(T, B, N);
}

vec2 ndcFromScreen(vec2 uv, vec2 resolution) {
    vec2 p = uv * 2.0 - 1.0;
    p.x *= resolution.x / max(resolution.y, 1.0);
    return p;
}

#endif

