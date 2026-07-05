#version 150
#ifndef CLOUD_SHAPE_GLSL
#define CLOUD_SHAPE_GLSL

#include "cloud_common.glsl"
#include "cloud_noise.glsl"

// Cloud shape functions
// Defines base layer, middle layer, high layer shapes with height gradients

// Base layer cloud shape (cumulus-like)
float cloudShapeBase(vec3 pos, float heightGradient, float coverage, float octaves) {
    // Dense at bottom, billowy at top
    float bottomDensity = 1.0 - heightGradient;
    float topDensity = pow(heightGradient, 0.3);

    float shape = cloudFBM(pos * 0.0008, octaves);
    shape = saturate(shape * 1.2 - 0.1);

    float heightBlend = mix(bottomDensity, topDensity, heightGradient);
    return shape * heightBlend * coverage;
}

// Middle layer cloud shape (altocumulus-like)
float cloudShapeMiddle(vec3 pos, float heightGradient, float coverage, float octaves) {
    // Thin, layered clouds
    float layerDensity = 1.0 - abs(heightGradient - 0.5) * 2.0;
    layerDensity = pow(layerDensity, 1.5);

    float shape = cloudFBM(pos * 0.001, octaves);
    shape = saturate(shape * 1.1 - 0.15);

    return shape * layerDensity * coverage * 0.6;
}

// High layer cloud shape (cirrus-like)
float cloudShapeHigh(vec3 pos, float heightGradient, float coverage, float octaves) {
    // Wispy, thin clouds at top
    float topDensity = pow(heightGradient, 2.0);

    float shape = cloudFBM(pos * 0.002, octaves);
    shape = saturate(shape * 1.0 - 0.2);

    return shape * topDensity * coverage * 0.3;
}

// Combined cloud shape with layer blending
float cloudShapeCombined(
    vec3 pos,
    float heightGradient,
    float coverage,
    float octaves,
    float stormFactor
) {
    float base = cloudShapeBase(pos, heightGradient, coverage, octaves);
    float middle = cloudShapeMiddle(pos, heightGradient, coverage, octaves);
    float high = cloudShapeHigh(pos, heightGradient, coverage, octaves);

    // Storm clouds are thicker and reach higher
    float stormBoost = 1.0 + stormFactor * 0.5;
    base *= stormBoost;

    return base + middle + high;
}

// Cloud edge softness
float cloudEdgeSoftness(float density, float heightGradient) {
    // Softer edges at top and bottom
    float edgeFade = 1.0 - abs(heightGradient - 0.5) * 1.5;
    edgeFade = saturate(edgeFade);

    // Density-based edge falloff
    float densityFade = saturate(density * 2.0);

    return min(edgeFade, densityFade);
}

#endif