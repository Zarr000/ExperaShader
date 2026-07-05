#version 150
#ifndef WEATHER_FOG_GLSL
#define WEATHER_FOG_GLSL

#include "weather_common.glsl"

// Weather-driven fog system
// Controls humidity fog, storm fog, distance fog, ground fog, visibility

struct WeatherFog {
    float density;
    float humidityFog;
    float stormFog;
    float distanceFog;
    float groundFog;
    float visibility;
    vec3 color;
    float heightFalloff;
};

// Compute fog parameters from weather state
WeatherFog weatherComputeFog(WeatherState w, float height) {
    WeatherFog f;
    f.density = 0.0;
    f.humidityFog = 0.0;
    f.stormFog = 0.0;
    f.distanceFog = 0.0;
    f.groundFog = 0.0;
    f.visibility = 1.0;
    f.color = vec3(0.0);
    f.heightFalloff = 0.0;

    float humidity = w.humidity;
    float storm = w.stormIntensity;
    float precip = w.precipitation;
    float coverage = w.coverage;

    // Humidity fog: increases with humidity
    f.humidityFog = humidity * 0.3;

    // Storm fog: dense fog during storms
    f.stormFog = storm * 0.5;

    // Distance fog: always present, modulated by weather
    f.distanceFog = 0.05 + coverage * 0.1 + precip * 0.15;

    // Ground fog: forms near surface in humid conditions
    float groundProximity = exp(-height * 0.01);
    f.groundFog = humidity * 0.4 * groundProximity;

    // Total fog density
    f.density = f.humidityFog + f.stormFog + f.distanceFog + f.groundFog;
    f.density = saturate(f.density);

    // Visibility (inverse of density)
    f.visibility = 1.0 - f.density * 0.8;

    // Fog color: grayish in fog, darker in storms
    vec3 clearFog = vec3(0.7, 0.75, 0.8);
    vec3 rainFog = vec3(0.4, 0.42, 0.45);
    vec3 stormFog = vec3(0.2, 0.2, 0.22);
    f.color = mix(clearFog, rainFog, precip);
    f.color = mix(f.color, stormFog, storm);

    // Height falloff: fog thins with altitude
    f.heightFalloff = 0.005 + storm * 0.005;

    return f;
}

// Fog density at a specific world position
float weatherFogAtPosition(vec3 worldPos, WeatherFog f, float time) {
    float height = worldPos.y;
    float heightFactor = exp(-height * f.heightFalloff);
    return f.density * heightFactor;
}

// Fog blend factor for compositing
float weatherFogBlend(float distance, float fogDensity) {
    return 1.0 - exp(-distance * fogDensity * 0.01);
}

#endif