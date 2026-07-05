#version 150
#ifndef WEATHER_WETNESS_GLSL
#define WEATHER_WETNESS_GLSL

#include "weather_common.glsl"
#include "../common/noise.glsl"

// Renderer-wide wetness accumulation
// Supports surface wetness, drying, humidity, evaporation, puddle factor
// Material Framework must consume wetness

// Compute wetness parameters from weather state
WeatherWetness weatherComputeWetness(WeatherState w, float time) {
    WeatherWetness ww;
    ww.surfaceWetness = 0.0;
    ww.dryingRate = 0.0;
    ww.humidity = 0.0;
    ww.evaporation = 0.0;
    ww.puddleFactor = 0.0;
    ww.materialResponse = 0.0;

    float precip = w.precipitation;
    float humidity = w.humidity;
    float temp = w.temperature;
    float coverage = w.coverage;

    // Surface wetness accumulates with precipitation
    ww.surfaceWetness = saturate(precip * 1.2 + humidity * 0.3);

    // Drying rate: faster in clear weather, slower in overcast
    ww.dryingRate = (1.0 - coverage) * (0.5 + temp * 0.5);

    // Humidity
    ww.humidity = humidity;

    // Evaporation: temperature-dependent
    ww.evaporation = temp * (1.0 - humidity) * 0.5;

    // Puddle factor: water accumulation on flat surfaces
    ww.puddleFactor = ww.surfaceWetness * (1.0 - ww.dryingRate);

    // Material response: how much materials should react to wetness
    ww.materialResponse = ww.surfaceWetness * (0.5 + 0.5 * ww.puddleFactor);

    return ww;
}

// Wetness at a specific world position (spatial variation)
float weatherWetnessAtPosition(vec3 worldPos, WeatherWetness ww, float time) {
    // Spatial variation of wetness
    float noiseScale = 0.001;
    float variation = hash12(worldPos.xz * noiseScale + time * 0.001);

    // Wetness varies more in areas with puddles
    float puddleVariation = mix(0.8, 1.2, variation);
    return saturate(ww.surfaceWetness * puddleVariation);
}

// Material wetness response factor
float weatherMaterialWetness(WeatherWetness ww, float materialRoughness) {
    // Smooth surfaces get wetter appearance
    float roughnessFactor = 1.0 - materialRoughness;
    return ww.materialResponse * (0.3 + 0.7 * roughnessFactor);
}

// Specular boost from wetness
float weatherWetnessSpecular(float wetness, float baseSpecular) {
    return baseSpecular * (1.0 + wetness * 2.0);
}

// Albedo darkening from wetness
float weatherWetnessDarkening(float wetness) {
    return 1.0 - wetness * 0.15;
}

#endif