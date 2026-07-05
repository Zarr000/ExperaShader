#version 150
#ifndef WATER_WAVES_GLSL
#define WATER_WAVES_GLSL

#include "water_common.glsl"
#include "../common/noise.glsl"
#include "../weather/weather_wind.glsl"

// Multi-scale Gerstner wave system
// Wind-driven, weather-modulated, with detail ripples and distance LOD

struct WaveOctave {
    vec2 dir;
    float amplitude;
    float frequency;
    float speed;
    float steepness;
    float wavelength;
};

// Compute wave parameters from weather wind
WaveOctave[4] waterWaveOctaves(WeatherWind wind, float quality) {
    WaveOctave waves[4];
    float q = quality;

    // Wind direction influence
    vec2 windDir = normalize(wind.direction);
    float windSpeed = wind.speed;

    // Octave 0: Large swell
    waves[0].dir = windDir;
    waves[0].amplitude = 0.3 * windSpeed;
    waves[0].frequency = 0.05;
    waves[0].speed = 1.0 * windSpeed;
    waves[0].steepness = 0.4;
    waves[0].wavelength = 20.0;

    // Octave 1: Medium waves
    waves[1].dir = normalize(windDir + vec2(0.3, -0.2));
    waves[1].amplitude = 0.2 * windSpeed;
    waves[1].frequency = 0.12;
    waves[1].speed = 1.2 * windSpeed;
    waves[1].steepness = 0.3;
    waves[1].wavelength = 8.0;

    // Octave 2: Small chop
    waves[2].dir = normalize(windDir + vec2(-0.2, 0.4));
    waves[2].amplitude = 0.1 * windSpeed;
    waves[2].frequency = 0.25;
    waves[2].speed = 1.5 * windSpeed;
    waves[2].steepness = 0.2;
    waves[2].wavelength = 3.0;

    // Octave 3: Detail ripples
    waves[3].dir = normalize(windDir + vec2(0.5, 0.3));
    waves[3].amplitude = 0.05 * windSpeed;
    waves[3].frequency = 0.5;
    waves[3].speed = 2.0 * windSpeed;
    waves[3].steepness = 0.15;
    waves[3].wavelength = 1.0;

    // Quality scaling for wave count
    if (q < WATER_HIGH) {
        waves[2].amplitude *= 0.5;
        waves[3].amplitude *= 0.3;
    }
    if (q < WATER_BALANCED) {
        waves[3].amplitude = 0.0;
    }

    return waves;
}

// Gerstner wave displacement
vec3 waterGerstnerDisplacement(vec2 pos, WaveOctave w, float time) {
    float k = 2.0 * 3.14159 / max(w.wavelength, 0.1);
    float phase = k * dot(w.dir, pos) - w.speed * time;
    float a = w.steepness / max(k, 0.01);

    return vec3(
        w.dir.x * a * cos(phase),
        a * sin(phase),
        w.dir.y * a * cos(phase)
    );
}

// Combined wave displacement and normal
void waterWaveDisplacement(vec2 pos, float time, WeatherWind wind, float quality,
                           out vec3 displacement, out vec3 normal) {
    WaveOctave[4] waves = waterWaveOctaves(wind, quality);
    displacement = vec3(0.0);
    normal = vec3(0.0, 1.0, 0.0);

    float eps = 0.1;
    vec3 totalDisp = vec3(0.0);
    vec3 totalDispX = vec3(0.0);
    vec3 totalDispZ = vec3(0.0);

    for (int i = 0; i < 4; i++) {
        if (waves[i].amplitude < 0.001) continue;

        vec3 d = waterGerstnerDisplacement(pos, waves[i], time);
        vec3 dx = waterGerstnerDisplacement(pos + vec2(eps, 0.0), waves[i], time);
        vec3 dz = waterGerstnerDisplacement(pos + vec2(0.0, eps), waves[i], time);

        totalDisp += d;
        totalDispX += dx;
        totalDispZ += dz;
    }

    displacement = totalDisp;

    // Finite difference normal
    vec3 p = vec3(pos.x, 0.0, pos.y) + totalDisp;
    vec3 px = vec3(pos.x + eps, 0.0, pos.y) + totalDispX;
    vec3 pz = vec3(pos.x, 0.0, pos.y + eps) + totalDispZ;

    vec3 tangent = normalize(px - p);
    vec3 bitangent = normalize(pz - p);
    normal = normalize(cross(bitangent, tangent));
}

// Detail ripples (high-frequency, low-amplitude)
float waterDetailRipples(vec2 pos, float time, float intensity) {
    float ripple = 0.0;
    float amp = 0.01 * intensity;
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

// Distance-dependent wave LOD
float waterWaveLOD(float distance, float quality) {
    float maxDist = waterQualityScale(quality, 50.0, 100.0, 200.0, 400.0, 800.0);
    return 1.0 - smoothstep(0.0, maxDist, distance);
}

#endif