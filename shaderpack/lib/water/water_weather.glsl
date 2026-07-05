#version 150
#ifndef WATER_WEATHER_GLSL
#define WATER_WEATHER_GLSL

#include "water_common.glsl"
#include "../weather/weather_common.glsl"
#include "../weather/weather_wind.glsl"
#include "../weather/weather_precipitation.glsl"
#include "../weather/weather_wetness.glsl"

// Weather Engine integration for water
// Consumes weatherComputeFrame() - does NOT read rainStrength directly

// Compute weather-driven water parameters
WaterParameters weatherDrivenWater(
    WeatherState w, WeatherWind wind, WeatherPrecipitation precip,
    WeatherWetness wetness, float quality
) {
    WaterParameters p = waterDefaultParams();

    // Wave intensity increases with wind speed and storm intensity
    p.waveAmplitude = 0.3 + wind.speed * 0.5 + precip.stormFactor * 0.3;
    p.waveFrequency = 1.0 + wind.gustStrength * 0.3;
    p.waveSpeed = 0.8 + wind.speed * 0.4;

    // Foam driven by precipitation and wind
    p.foamStrength = 0.8 + precip.precipitation * 0.4 + wind.gustStrength * 0.3;

    // Roughness increases in storms
    p.roughness = 0.02 + precip.stormFactor * 0.05;

    // Absorption: clearer in calm, murkier in storms
    vec3 clearAbs = WATER_ABSORPTION_CLEAR;
    vec3 stormAbs = WATER_ABSORPTION_MURKY;
    p.absorptionCoeff = mix(clearAbs, stormAbs, w.stormIntensity * 0.5);

    // Underwater visibility decreases in storms
    p.underwaterVisibility = mix(15.0, 5.0, w.stormIntensity);

    // Caustic strength decreases in overcast
    p.causticStrength = 0.3 * (1.0 - w.coverage * 0.5);

    return p;
}

#endif