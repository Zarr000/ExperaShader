#version 150
#ifndef RENDERER_SAMPLING_GLSL
#define RENDERER_SAMPLING_GLSL

#include "renderer_common.glsl"

// Centralized sample generation and shared sample pools

// Sample patterns
#define SAMPLE_BLUE_NOISE    0.0
#define SAMPLE_HALTON        1.0
#define SAMPLE_HAMMERSLEY    2.0
#define SAMPLE_POISSON_DISK  3.0

// Sample pool for shared reuse across passes
struct SamplePool {
    float pattern;
    float count;
    float size;
    bool rotated;
    float seed;
};

// Initialize sample pool
SamplePool rendererSamplePoolInit(float pattern, float count, bool rotated) {
    SamplePool s;
    s.pattern = pattern;
    s.count = count;
    s.size = 1.0;
    s.rotated = rotated;
    s.seed = 0.0;
    return s;
}

// Get sample count based on quality and budget
float rendererSampleCount(float quality, float budgetAvailable) {
    float baseCount = 0.0;
    if (quality <= RENDERER_PERFORMANCE) baseCount = 4.0;
    else if (quality <= RENDERER_BALANCED) baseCount = 8.0;
    else if (quality <= RENDERER_HIGH) baseCount = 16.0;
    else if (quality <= RENDERER_ULTRA) baseCount = 32.0;
    else baseCount = 64.0;

    // Scale by available budget
    float budgetFactor = clamp(budgetAvailable / 100.0, 0.25, 1.0);
    return max(floor(baseCount * budgetFactor), 1.0);
}

// Blue noise sample (shared across SSR, SSGI, Clouds, Water, Shadows)
vec2 rendererBlueNoiseSample(float index, float frame) {
    // Use golden ratio for rotation
    float angle = index * 2.399963 + frame * 0.618033;
    return vec2(cos(angle), sin(angle)) * 0.5 + 0.5;
}

// Halton sequence sample
vec2 rendererHaltonSample(float index) {
    // Simplified Halton sequence (2, 3)
    float a = 0.0;
    float b = 0.0;
    float f = 0.5;
    float i = index;
    while (i > 0.0) {
        a += f * mod(i, 2.0);
        i = floor(i / 2.0);
        f *= 0.5;
    }
    f = 1.0 / 3.0;
    i = index;
    while (i > 0.0) {
        b += f * mod(i, 3.0);
        i = floor(i / 3.0);
        f *= 1.0 / 3.0;
    }
    return vec2(a, b);
}

// Hammersley sequence sample
vec2 rendererHammersleySample(float index, float count) {
    // Simplified Hammersley sequence
    float a = index / count;
    float b = 0.0;
    float f = 0.5;
    float i = index;
    while (i > 0.0) {
        b += f * mod(i, 2.0);
        i = floor(i / 2.0);
        f *= 0.5;
    }
    return vec2(a, b);
}

// Poisson disk sample
vec2 rendererPoissonDiskSample(float index) {
    // Precomputed Poisson disk samples (16 samples)
    vec2 samples[16];
    samples[0] = vec2(0.0, 0.0);
    samples[1] = vec2(0.5, 0.0);
    samples[2] = vec2(0.0, 0.5);
    samples[3] = vec2(0.5, 0.5);
    samples[4] = vec2(0.25, 0.25);
    samples[5] = vec2(0.75, 0.25);
    samples[6] = vec2(0.25, 0.75);
    samples[7] = vec2(0.75, 0.75);
    samples[8] = vec2(0.125, 0.125);
    samples[9] = vec2(0.625, 0.125);
    samples[10] = vec2(0.375, 0.375);
    samples[11] = vec2(0.875, 0.375);
    samples[12] = vec2(0.125, 0.625);
    samples[13] = vec2(0.625, 0.625);
    samples[14] = vec2(0.375, 0.875);
    samples[15] = vec2(0.875, 0.875);

    int idx = int(mod(index, 16.0));
    return samples[idx];
}

// Get sample from pool
vec2 rendererSampleFromPool(SamplePool pool, float index, float frame) {
    if (pool.pattern == SAMPLE_BLUE_NOISE) return rendererBlueNoiseSample(index, frame);
    if (pool.pattern == SAMPLE_HALTON) return rendererHaltonSample(index);
    if (pool.pattern == SAMPLE_HAMMERSLEY) return rendererHammersleySample(index, pool.count);
    if (pool.pattern == SAMPLE_POISSON_DISK) return rendererPoissonDiskSample(index);
    return vec2(0.0);
}

#endif