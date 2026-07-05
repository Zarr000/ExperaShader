#version 150
#ifndef WEATHER_UTIL_GLSL
#define WEATHER_UTIL_GLSL

#include "weather_common.glsl"
#include "weather_state.glsl"
#include "weather_wind.glsl"
#include "weather_precipitation.glsl"
#include "weather_wetness.glsl"
#include "weather_fog.glsl"
#include "weather_lighting.glsl"
#include "weather_clouds.glsl"
#include "weather_materials.glsl"

// Weather Engine unified utility
// Single entry point for consuming weather state across the renderer

// Complete weather simulation result for a frame
struct WeatherFrame {
    WeatherState state;
    WeatherWind wind;
    WeatherPrecipitation precipitation;
    WeatherWetness wetness;
    WeatherFog fog;
    WeatherLighting lighting;
    CloudParameters clouds;
    WeatherMaterialResponse materials;
    float time;
    float deltaTime;
};

// Compute complete weather frame
WeatherFrame weatherComputeFrame(float time, float deltaTime, vec3 cameraPos) {
    WeatherFrame frame;
    frame.time = time;
    frame.deltaTime = deltaTime;

    // Compute base weather state from Minecraft runtime
    frame.state = weatherComputeState(time);
    frame.state.windSpeed = 0.3 + rainStrength * 0.7;

    // Compute wind
    frame.wind = weatherComputeWind(frame.state, time);

    // Compute precipitation
    frame.precipitation = weatherComputePrecipitation(frame.state, time);

    // Compute wetness
    frame.wetness = weatherComputeWetness(frame.state, time);

    // Compute fog
    frame.fog = weatherComputeFog(frame.state, cameraPos.y);

    // Compute lighting
    frame.lighting = weatherComputeLighting(frame.state, AtmosphereRuntime()); // Simplification - full runtime available in pass

    // Compute weather-driven cloud parameters
    frame.clouds = weatherDrivenClouds(frame.state, frame.wind, time);

    // Compute material response (uses default roughness)
    frame.materials = weatherMaterialResponse(frame.wetness, 0.5);

    return frame;
}

// Apply weather to atmosphere parameters
AtmosphereParameters weatherApplyToAtmosphere(AtmosphereParameters p, WeatherLighting l, WeatherState w) {
    return weatherModifyAtmosphere(p, l, w);
}

// Apply weather to cloud parameters
CloudParameters weatherApplyToClouds(CloudParameters c, WeatherState w, WeatherWind wind, float time) {
    return weatherDrivenClouds(w, wind, time);
}

#endif