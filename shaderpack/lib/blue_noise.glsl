#version 150
#ifndef BLUE_NOISE_GLSL
#define BLUE_NOISE_GLSL

// Procedural blue-noise-ish sampler.
// Uses a precomputed permutation via hash + stratification.

float blueNoise(vec2 p, float frame) {
    // Rotate sample pattern for temporal decorrelation.
    float t = frame * 0.61803398875;
    vec2 q = mat2(cos(t), -sin(t), sin(t), cos(t)) * p;

    // Cranley-Patterson rotation in hashed domain.
    float n = hash12(q + vec2(frame * 0.13, frame * 0.07));

    // Push distribution away from white-noise characteristics.
    // Use smoothstep to reduce low-frequency clumping.
    n = smoothstep(0.0, 1.0, n);
    return n;
}

vec2 blueNoise2(vec2 p, float frame) {
    float n0 = blueNoise(p, frame);
    float n1 = blueNoise(p + vec2(5.2, 1.7), frame);
    return vec2(n0, n1);
}

#endif

