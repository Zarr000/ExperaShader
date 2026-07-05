#version 150
#ifndef WATER_DEBUG_GLSL
#define WATER_DEBUG_GLSL

#include "water_common.glsl"
#include "water_waves.glsl"
#include "water_fresnel.glsl"
#include "water_absorption.glsl"
#include "water_foam.glsl"
#include "water_caustics.glsl"

// Water debug visualization
// Supports: waves, foam, caustics, absorption, scattering, reflection, refraction, ripples

vec3 waterDebugVisualization(
    float mode,
    WaterSurfaceSample sample,
    WaterReflection ref,
    WaterRefraction refr,
    WaterScattering scatter,
    float caustic,
    float ripple
) {
    if (mode < 1.0) return vec3(0.0); // Normal

    // Mode 1: Waves
    if (mode < 2.0) {
        vec3 n = sample.normal;
        return n * 0.5 + 0.5;
    }

    // Mode 2: Foam
    if (mode < 3.0) {
        return vec3(sample.foam);
    }

    // Mode 3: Caustics
    if (mode < 4.0) {
        return vec3(caustic);
    }

    // Mode 4: Absorption
    if (mode < 5.0) {
        float depth = sample.depth / 10.0;
        return vec3(exp(-depth));
    }

    // Mode 5: Scattering
    if (mode < 6.0) {
        return scatter.singleScatter * 2.0;
    }

    // Mode 6: Reflection
    if (mode < 7.0) {
        return ref.combined;
    }

    // Mode 7: Refraction
    if (mode < 8.0) {
        return vec3(refr.distortionStrength);
    }

    // Mode 8: Ripples
    if (mode < 9.0) {
        return vec3(ripple * 5.0);
    }

    // Mode 9: Fresnel
    if (mode < 10.0) {
        return vec3(ref.fresnel);
    }

    return vec3(0.0);
}

#endif