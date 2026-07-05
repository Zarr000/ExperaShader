#version 150
#ifndef WEATHER_PRECIPITATION_GLSL
#define WEATHER_PRECIPITATION_GLSL

#include "weather_common.glsl"
#include "../common/noise.glsl"

// Production-quality precipitation logic
// Supports rain intensity, storm intensity, drizzle, light/heavy rain,
// thunderstorm preparation, and snow hooks

// Compute precipitation parameters from weather state
WeatherPrecipitation weatherComputePrecipitation(WeatherState w, float time) {
    WeatherPrecipitation p;
    p.intensity = 0.0;
    p.stormFactor = 0.0;
    p.drizzle = 0.0;
    p.lightRain = 0.0;
    p.heavyRain = 0.0;
    p.thunderstorm = 0.0;
    p.snowFactor = 0.0;
    p.dropSize = 0.0;

    float precip = w.precipitation;
    float storm = w.stormIntensity;
    float temp = w.temperature;

    // Precipitation intensity
    p.intensity = precip;

    // Storm factor
    p.stormFactor = storm;

    // Drizzle: light, fine precipitation (precip < 0.3)
    p.drizzle = saturate(1.0 - precip * 3.0) * precip * 2.0;

    // Light rain: moderate precipitation (precip 0.2-0.6)
    p.lightRain = saturate((precip - 0.2) * 2.5) * (1.0 - saturate((precip - 0.6) * 5.0));

    // Heavy rain: intense precipitation (precip > 0.5)
    p.heavyRain = saturate((precip - 0.5) * 3.0);

    // Thunderstorm: storm + heavy rain
    p.thunderstorm = p.heavyRain * storm;

    // Snow: temperature-dependent (future-ready)
    p.snowFactor = saturate(1.0 - temp * 3.0) * precip;

    // Raindrop size: drizzle has small drops, storms have large drops
    p.dropSize = mix(0.3, 1.5, p.heavyRain + p.thunderstorm * 0.5);

    return p;
}

// Precipitation accumulation at a world position
float weatherPrecipitationAtPosition(vec3 worldPos, WeatherState w, float time) {
    // Large-scale precipitation variation
    float noiseScale = 0.0002;
    vec2 pos = worldPos.xz * noiseScale + vec2(time * 0.002, time * 0.001);
    float variation = hash12(pos);

    // Precipitation intensity with spatial variation
    float baseIntensity = w.precipitation;
    float localIntensity = baseIntensity * mix(0.6, 1.4, variation);

    return saturate(localIntensity);
}

// Lightning flash intensity (for storm states)
float weatherLightningFlash(WeatherState w, float time) {
    if (w.lightning < 0.01) return 0.0;

    // Random lightning flashes
    float flashSeed = floor(time * 0.5);
    float flashTime = hash11(flashSeed);
    float flashDuration = 0.1; // seconds
    float flash = saturate(1.0 - abs(fract(time * 0.5) - flashTime) / flashDuration);

    // Flash intensity based on storm severity
    return flash * w.lightning * 2.0;
}

// Snow accumulation (future-ready, returns 0 until snow rendering is implemented)
float weatherSnowAccumulation(WeatherState w, float time) {
    if (w.snowFactor < 0.01) return 0.0;
    // Placeholder: will be implemented with Snow Engine
    return 0.0;
}

#endif