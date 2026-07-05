#version 150
#ifndef WEATHER_WIND_GLSL
#define WEATHER_WIND_GLSL

#include "weather_common.glsl"
#include "../common/noise.glsl"

// Runtime wind simulation
// Drives cloud movement, vegetation, water waves, rain direction
// Supports gusts, turbulence, low/high-frequency variation

// Compute wind parameters from weather state
WeatherWind weatherComputeWind(WeatherState w, float time) {
    WeatherWind wind;
    wind.direction = w.windDirection;
    wind.speed = w.windSpeed;
    wind.gustStrength = 0.0;
    wind.turbulence = 0.0;
    wind.lowFreqVariation = 0.0;
    wind.highFreqVariation = 0.0;
    wind.gustVector = vec2(0.0);

    // Low-frequency wind variation (slow changes over minutes)
    float lowFreq = hash12(vec2(floor(time * 0.02), 2.0));
    wind.lowFreqVariation = lowFreq * 2.0 - 1.0;

    // High-frequency wind variation (gusts over seconds)
    float highFreq = sin(time * 0.5 + hash12(vec2(floor(time * 0.1), 3.0)) * 6.2832);
    wind.highFreqVariation = highFreq;

    // Gust strength increases with storm intensity
    wind.gustStrength = 0.2 + w.stormIntensity * 0.8;

    // Turbulence increases with wind speed and storm intensity
    wind.turbulence = 0.1 + w.windSpeed * 0.3 + w.stormIntensity * 0.4;

    // Gust vector: wind direction with gust perturbation
    float gustAngle = wind.lowFreqVariation * 0.5 + wind.highFreqVariation * 0.2;
    float cosGust = cos(gustAngle);
    float sinGust = sin(gustAngle);
    wind.gustVector = vec2(
        wind.direction.x * cosGust - wind.direction.y * sinGust,
        wind.direction.x * sinGust + wind.direction.y * cosGust
    );

    return wind;
}

// Effective wind vector at a point (includes gusts and turbulence)
vec2 weatherWindAtPoint(vec3 worldPos, WeatherWind wind, float time) {
    // Spatial variation of wind
    float spatialNoise = hash12(worldPos.xz * 0.001 + time * 0.01);
    float spatialVariation = (spatialNoise - 0.5) * 0.3;

    // Combine base direction with gust vector
    vec2 effectiveDir = normalize(mix(wind.direction, wind.gustVector, wind.gustStrength * 0.5));

    // Speed with gust and turbulence modulation
    float gustMod = 1.0 + wind.gustStrength * wind.highFreqVariation * 0.5;
    float turbMod = 1.0 + wind.turbulence * spatialVariation;
    float effectiveSpeed = wind.speed * gustMod * turbMod;

    return effectiveDir * effectiveSpeed;
}

// Wind speed for cloud movement
float weatherWindCloudSpeed(WeatherWind wind) {
    return wind.speed * (1.0 + wind.gustStrength * 0.3);
}

// Wind direction for cloud movement
vec2 weatherWindCloudDirection(WeatherWind wind) {
    return normalize(mix(wind.direction, wind.gustVector, wind.gustStrength * 0.3));
}

// Wind speed for vegetation animation
float weatherWindVegetationSpeed(WeatherWind wind) {
    return wind.speed * (1.0 + wind.gustStrength * 0.5 + wind.turbulence * 0.3);
}

// Wind speed for water waves
float weatherWindWaterSpeed(WeatherWind wind) {
    return wind.speed * (1.0 + wind.gustStrength * 0.4);
}

// Wind direction for rain
vec2 weatherWindRainDirection(WeatherWind wind) {
    return normalize(mix(wind.direction, wind.gustVector, wind.gustStrength * 0.7));
}

#endif