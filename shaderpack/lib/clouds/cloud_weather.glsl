#version 150
#ifndef CLOUD_WEATHER_GLSL
#define CLOUD_WEATHER_GLSL

#include "cloud_common.glsl"
#include "cloud_noise.glsl"

// Weather integration for cloud density modulation
// Prepares for future Weather Engine without implementing it

// Humidity-based density modulation
float cloudHumidityDensity(float humidity, vec3 pos, float time) {
    // Large-scale humidity patterns
    float humNoise = cloudFBM(pos * 0.0003 + vec3(0.0, 0.0, time * 0.005), 2.0);
    float humFactor = mix(0.3, 1.0, humNoise);
    return mix(0.5, 1.0, humidity) * humFactor;
}

// Storm intensity modulation
float cloudStormDensity(float stormFactor, vec3 pos, float time) {
    // Storm cells create denser cloud patches
    float stormNoise = cloudFBM(pos * 0.0002 + vec3(time * 0.008, 0.0, time * 0.004), 3.0);
    float stormCell = saturate(stormNoise * 1.5 - 0.5);
    return 1.0 + stormCell * stormFactor * 0.8;
}

// Combined weather density modulation
float cloudWeatherDensity(float humidity, float stormFactor, vec3 pos, float time) {
    float humMod = cloudHumidityDensity(humidity, pos, time);
    float stormMod = cloudStormDensity(stormFactor, pos, time);
    return humMod * stormMod;
}

// Wind influence on cloud position
vec3 cloudWindOffset(vec2 windDirection, float windSpeed, float time) {
    vec2 wind = windDirection * windSpeed * time;
    return vec3(wind.x, 0.0, wind.y);
}

// Coverage modifier based on weather
float cloudWeatherCoverage(float baseCoverage, float humidity, float stormFactor, vec3 pos, float time) {
    float humCoverage = mix(0.8, 1.2, humidity);
    float stormCoverage = 1.0 + stormFactor * 0.3;

    // Local weather noise for coverage variation
    float weatherNoise = cloudFBM(pos * 0.0004 + vec3(time * 0.003, 0.0, time * 0.002), 2.0);
    float weatherVar = mix(0.7, 1.3, weatherNoise);

    return baseCoverage * humCoverage * stormCoverage * weatherVar;
}

// Future Weather Engine hook (placeholder pattern, not implementation)
// When Weather Engine is built, this module will consume its output
// to drive cloud coverage, density, wind, and storm patterns

#endif