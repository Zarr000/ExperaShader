#version 150
#ifndef WATER_NORMAL_GLSL
#define WATER_NORMAL_GLSL

#include "water_common.glsl"
#include "water_waves.glsl"

// Water normal computation from wave displacement and detail ripples

// Compute final water normal combining waves and ripples
vec3 waterComputeNormal(vec2 pos, float time, WeatherWind wind, float quality, float distance) {
    vec3 waveDisp, waveNormal;
    waterWaveDisplacement(pos, time, wind, quality, waveDisp, waveNormal);

    // Detail ripples normal perturbation
    float rippleIntensity = waterDetailRipples(pos, time, wind.speed);
    float lod = waterWaveLOD(distance, quality);

    vec3 rippleNormal = vec3(
        rippleIntensity * 0.5,
        1.0,
        rippleIntensity * 0.3
    );
    rippleNormal = normalize(rippleNormal);

    // Blend wave normal with ripple normal based on LOD
    vec3 finalNormal = normalize(mix(waveNormal, rippleNormal, 0.3 * lod));

    return finalNormal;
}

// Perturb normal for reflection/refraction
vec3 waterPerturbNormal(vec3 normal, float strength) {
    vec3 perturb = vec3(
        sin(normal.x * 10.0) * 0.02,
        0.0,
        cos(normal.z * 10.0) * 0.02
    );
    return normalize(normal + perturb * strength);
}

#endif