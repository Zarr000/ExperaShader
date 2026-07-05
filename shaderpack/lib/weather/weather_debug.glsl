#version 150
#ifndef WEATHER_DEBUG_GLSL
#define WEATHER_DEBUG_GLSL

#include "weather_common.glsl"
#include "weather_state.glsl"
#include "weather_wind.glsl"
#include "weather_precipitation.glsl"
#include "weather_fog.glsl"

// Weather debug visualization
// Supports: weather state, humidity, wind vectors, wetness, precipitation, cloud coverage, fog density, storm intensity

vec3 weatherDebugVisualization(float mode, WeatherState w, WeatherWind wind,
                                WeatherPrecipitation p, WeatherFog f, WeatherWetness ww,
                                vec3 worldPos) {
    if (mode < 1.0) return vec3(0.0); // Normal

    // Mode 1: Weather state
    if (mode < 2.0) {
        float stateNorm = w.state / WEATHER_SNOW;
        return vec3(stateNorm, 0.0, 1.0 - stateNorm);
    }

    // Mode 2: Humidity
    if (mode < 3.0) {
        return vec3(w.humidity, 0.0, 1.0 - w.humidity);
    }

    // Mode 3: Wind vectors
    if (mode < 4.0) {
        vec2 windVec = weatherWindAtPoint(worldPos, wind, 0.0);
        return vec3(windVec * 0.5 + 0.5, 0.0);
    }

    // Mode 4: Wetness
    if (mode < 5.0) {
        return vec3(ww.surfaceWetness, 0.0, 1.0 - ww.surfaceWetness);
    }

    // Mode 5: Precipitation
    if (mode < 6.0) {
        return vec3(p.intensity, 0.0, 1.0 - p.intensity);
    }

    // Mode 6: Cloud coverage
    if (mode < 7.0) {
        return vec3(w.coverage, 0.0, 1.0 - w.coverage);
    }

    // Mode 7: Fog density
    if (mode < 8.0) {
        return vec3(f.density, 0.0, 1.0 - f.density);
    }

    // Mode 8: Storm intensity
    if (mode < 9.0) {
        return vec3(w.stormIntensity, 0.0, 1.0 - w.stormIntensity);
    }

    // Mode 9: Wind speed
    if (mode < 10.0) {
        return vec3(wind.speed, 0.0, 1.0 - wind.speed);
    }

    // Mode 10: Combined weather overview
    if (mode < 11.0) {
        return vec3(w.coverage, w.precipitation, w.stormIntensity);
    }

    return vec3(0.0);
}

#endif