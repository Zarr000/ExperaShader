#version 150
#ifndef WATER_FOAM_GLSL
#define WATER_FOAM_GLSL

#include "water_common.glsl"
#include "water_waves.glsl"
#include "../weather/weather_wind.glsl"
#include "../weather/weather_precipitation.glsl"

// Water foam system
// Shore foam, wave crest foam, storm foam, wind-driven foam

// Foam at wave crests
float waterFoamWaveCrest(float steepness, float windSpeed) {
    float foam = foamFromSteepness(1.0 - steepness);
    foam *= windSpeed * 0.5;
    return saturate(foam);
}

// Shore foam (near coastline)
float waterFoamShore(float shoreDist, float shoreWidth) {
    float shoreFactor = 1.0 - saturate(shoreDist / shoreWidth);
    return shoreFactor * 0.8;
}

// Storm foam (increased during precipitation)
float waterFoamStorm(float waveCrestFoam, float shoreFoam, WeatherPrecipitation precip) {
    float stormMod = 1.0 + precip.heavyRain * 0.5 + precip.thunderstorm * 1.0;
    return saturate((waveCrestFoam + shoreFoam) * stormMod);
}

// Wind-driven foam amount
float waterFoamWindDriven(float baseFoam, WeatherWind wind) {
    float windMod = 1.0 + wind.speed * 0.3 + wind.gustStrength * 0.4;
    return saturate(baseFoam * windMod);
}

// Combined water foam
float waterComputeFoam(
    float steepness, float shoreDist, float windSpeed,
    WeatherPrecipitation precip, WeatherWind wind,
    float shoreWidth
) {
    float waveFoam = waterFoamWaveCrest(steepness, windSpeed);
    float shoreFoam = waterFoamShore(shoreDist, shoreWidth);
    float stormFoam = waterFoamStorm(waveFoam, shoreFoam, precip);
    return waterFoamWindDriven(stormFoam, wind);
}

#endif