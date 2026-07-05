#version 150
#ifndef WATER_RIPPLE_GLSL
#define WATER_RIPPLE_GLSL

#include "water_common.glsl"
#include "../common/noise.glsl"
#include "../weather/weather_precipitation.glsl"

// Water ripple effects
// Rain ripples, wave ripples, detail ripples

// Rain ripple pattern
vec2 waterRainRipple(vec2 pos, float time, float intensity) {
    if (intensity < 0.01) return vec2(0.0);

    float tt = time * 1.8;
    float n = hash12(pos * 0.65 + vec2(tt * 0.2));
    float ripple = sin((pos.x + n * 1.7) * 8.0 + tt * 6.0) * 0.5 + 0.5;
    ripple *= intensity;

    return vec2(
        cos(ripple * 3.14159) * ripple * 0.1,
        sin(ripple * 3.14159) * ripple * 0.1
    );
}

// Wave ripple from waves
float waterWaveRipple(vec2 pos, float time, float windSpeed) {
    float ripple = 0.0;
    float amp = 0.02 * windSpeed;
    float freq = 2.0;

    for (int i = 0; i < 3; i++) {
        vec2 offset = vec2(
            sin(time * 0.5 + float(i) * 2.0) * 0.5,
            cos(time * 0.3 + float(i) * 1.5) * 0.5
        );
        float n = sin(dot(pos * freq + offset, vec2(1.0, 0.7)) + time * 3.0);
        ripple += amp * n;
        amp *= 0.5;
        freq *= 2.0;
    }

    return ripple;
}

// Normal perturbation from ripples
vec3 waterRippleNormal(vec2 pos, float time, WeatherPrecipitation precip, float windSpeed) {
    vec2 rainRipple = waterRainRipple(pos * 0.5, time, precip.intensity * 0.75);
    float waveRipple = waterWaveRipple(pos, time, windSpeed);

    // Combine into normal perturbation
    vec3 n = vec3(
        rainRipple.x + waveRipple * 0.5,
        1.0,
        rainRipple.y + waveRipple * 0.3
    );

    return normalize(n);
}

#endif