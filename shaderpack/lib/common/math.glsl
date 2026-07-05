#version 150

#ifndef COMMON_MATH_GLSL
#define COMMON_MATH_GLSL

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0.0), vec2(1.0)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0.0), vec3(1.0)); }
vec4 saturate(vec4 x) { return clamp(x, vec4(0.0), vec4(1.0)); }

float safeSqrt(float x) { return sqrt(max(x, 0.0)); }

vec3 safeNormalize(vec3 v) {
    float l = length(v);
    return (l > 0.0) ? (v / l) : vec3(0.0, 1.0, 0.0);
}

mat3 mat3FromColumns(vec3 c0, vec3 c1, vec3 c2) {
    return mat3(c0, c1, c2);
}

#endif
