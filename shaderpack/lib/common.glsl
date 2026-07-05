#version 150

// Common utility functions and constants.
// Intended for use with OptiFine/Iris GLSL include model.

#ifndef COMMON_GLSL
#define COMMON_GLSL

precision highp float;

// =========================
// Math helpers
// =========================

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0.0), vec2(1.0)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0.0), vec3(1.0)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0.0), vec4(1.0)); }

float rcp(float x) { return 1.0 / x; }

float safeSqrt(float x) { return sqrt(max(x, 0.0)); }

// =========================
// Hash / noise (value noise)
// =========================

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    float n = hash12(p);
    float m = hash12(p + 37.1);
    return vec2(n, m);
}

// =========================
// Coordinate helpers
// =========================

vec2 ndcFromScreen(vec2 uv, vec2 resolution) {
    vec2 p = uv * 2.0 - 1.0;
    p.x *= resolution.x / max(resolution.y, 1.0);
    return p;
}

// =========================
// Color pipeline: ACES Filmic
// =========================

vec3 ACESFilm(vec3 x) {
    // Narkowicz / common ACES fitted curve
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

// =========================
// SRGB / gamma
// =========================

vec3 linearToSRGB(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 SRGBToLinear(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(2.2));
}

// =========================
// Camera helpers
// =========================

mat3 mat3FromColumns(vec3 c0, vec3 c1, vec3 c2) {
    return mat3(c0, c1, c2);
}

// =========================
// TBN helper
// =========================

mat3 computeTBN(vec3 n, vec3 tangent, vec3 bitangent) {
    vec3 T = normalize(tangent - n * dot(n, tangent));
    vec3 B = normalize(bitangent - n * dot(n, bitangent));
    vec3 N = normalize(n);
    return mat3(T, B, N);
}

// =========================
// Random access safely
// =========================

vec3 safeNormalize(vec3 v) {
    float l = length(v);
    return (l > 0.0) ? (v / l) : vec3(0.0, 1.0, 0.0);
}

#endif

