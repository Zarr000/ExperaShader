#version 150
#ifndef WEATHER_CLOUDS_GLSL
#define WEATHER_CLOUDS_GLSL

#include "weather_common.glsl"
#include "weather_wind.glsl"

// Weather-to-Cloud integration
// Weather Engine controls cloud coverage, storm cells, humidity, wind, density, lighting

// Compute cloud parameters driven by weather state
CloudParameters weatherDrivenClouds(WeatherState w, WeatherWind wind, float time) {
    CloudParameters c;

    // Base cloud layer heights
    c.baseHeight = w.cloudAltitude;
    c.topHeight = w.cloudAltitude + 64.0;
    c.thickness = 64.0;

    // Coverage driven by weather
    c.coverage = w.coverage;

    // Density modulated by storm intensity
    c.density = w.cloudDensity * (0.5 + 0.5 * (1.0 + w.stormIntensity * 0.5));

    // Humidity from weather
    c.humidity = w.humidity;

    // Storm factor
    c.stormFactor = w.stormIntensity;

    // Erosion: less erosion in storms (clouds are denser)
    c.erosion = 0.5 + 0.5 * (1.0 - w.stormIntensity);

    // Wind from weather wind system
    c.windSpeed = weatherWindCloudSpeed(wind);
    c.windDirection = weatherWindCloudDirection(wind);

    // Quality from weather quality
    c.quality = weatherQualityLevel();
    c.temporalFeedback = weatherQualityScale(c.quality, 0.7, 0.8, 0.85, 0.9, 0.93);

    return c;
}

// Cloud coverage modifier from weather
float weatherCloudCoverageModifier(WeatherState w, vec3 worldPos, float time) {
    // Spatial variation of coverage
    float noiseScale = 0.0003;
    float variation = hash12(worldPos.xz * noiseScale + time * 0.001);
    float localCoverage = w.coverage * mix(0.7, 1.3, variation);

    return saturate(localCoverage);
}

// Cloud density modifier from weather
float weatherCloudDensityModifier(WeatherState w, vec3 worldPos, float time) {
    // Storm cells create denser patches
    float stormNoise = hash12(worldPos.xz * 0.0002 + time * 0.002);
    float stormMod = 1.0 + stormNoise * w.stormIntensity * 0.5;

    return w.cloudDensity * stormMod;
}

// Cloud brightness modifier from weather
float weatherCloudBrightness(WeatherState w) {
    // Clouds are darker in storms, brighter in clear weather
    float brightness = 1.0 - w.stormIntensity * 0.3 - w.precipitation * 0.2;
    return saturate(brightness);
}

#endif