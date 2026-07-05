#version 150
#ifndef WEATHER_STATE_GLSL
#define WEATHER_STATE_GLSL

#include "weather_common.glsl"
#include "../common/noise.glsl"

// Weather state machine
// Computes weather state from Minecraft runtime uniforms and noise
// Each state exposes physically meaningful parameters

// Determine target weather state from rainStrength and wetness
float weatherDetermineState(float rain, float wetness, float humidityNoise) {
    if (rain < 0.05) {
        // Clear to partly cloudy based on humidity noise
        return (humidityNoise < 0.4) ? WEATHER_CLEAR : WEATHER_PARTLY_CLOUDY;
    } else if (rain < 0.2) {
        return WEATHER_PARTLY_CLOUDY;
    } else if (rain < 0.35) {
        return WEATHER_OVERCAST;
    } else if (rain < 0.5) {
        return WEATHER_RAIN;
    } else if (rain < 0.7) {
        return WEATHER_STORM;
    } else if (rain < 0.85) {
        return WEATHER_HEAVY_STORM;
    } else {
        return WEATHER_FOG;
    }
}

// Compute weather state parameters from Minecraft runtime
WeatherState weatherComputeState(float time) {
    WeatherState w;
    w.state = 0.0;
    w.coverage = 0.0;
    w.humidity = 0.0;
    w.precipitation = 0.0;
    w.stormIntensity = 0.0;
    w.fogDensity = 0.0;
    w.windSpeed = 0.0;
    w.windDirection = vec2(0.0);
    w.wetness = 0.0;
    w.temperature = 0.0;
    w.visibility = 1.0;
    w.cloudDensity = 0.0;
    w.cloudAltitude = 192.0;
    w.lightning = 0.0;

    // Base parameters from Minecraft runtime
    float rain = rainStrength;
    float wet = wetness;

    // Large-scale weather noise for variation
    float weatherNoise = hash12(vec2(floor(time * 0.01), 0.0));
    float humidityNoise = hash12(vec2(floor(time * 0.005), 1.0));

    // Determine weather state
    w.state = weatherDetermineState(rain, wet, humidityNoise);

    // Coverage: 0 (clear) to 1 (overcast)
    w.coverage = saturate(rain * 1.5 + humidityNoise * 0.3);

    // Humidity: 0 (dry) to 1 (saturated)
    w.humidity = saturate(0.3 + rain * 0.6 + humidityNoise * 0.2);

    // Precipitation: 0 (none) to 1 (maximum)
    w.precipitation = saturate((rain - 0.2) * 1.5);

    // Storm intensity: 0 (none) to 1 (severe)
    w.stormIntensity = saturate((rain - 0.4) * 2.5);

    // Fog density: increases with rain and humidity
    w.fogDensity = rain * 0.3 + w.humidity * 0.2;

    // Wind direction and speed from Minecraft + noise
    float windAngle = weatherNoise * 6.2832 + time * 0.0005;
    w.windDirection = vec2(cos(windAngle), sin(windAngle));
    w.windSpeed = 0.3 + rain * 0.7 + weatherNoise * 0.3;

    // Wetness: accumulates with precipitation, dries over time
    w.wetness = wet;

    // Temperature: inversely related to rain (storms are cooler)
    w.temperature = 0.6 - rain * 0.3;

    // Visibility: decreases with fog and precipitation
    w.visibility = 1.0 - w.fogDensity * 0.8 - w.precipitation * 0.3;

    // Cloud density and altitude
    w.cloudDensity = w.coverage * (0.5 + 0.5 * w.stormIntensity);
    w.cloudAltitude = 192.0 - w.stormIntensity * 32.0;

    // Lightning: present during storms
    w.lightning = w.stormIntensity * 0.3;

    return w;
}

// State-specific parameter override
float weatherStateParameter(float state, float clearVal, float cloudyVal, float overcastVal,
                            float rainVal, float stormVal, float heavyStormVal, float fogVal) {
    if (state <= WEATHER_CLEAR) return clearVal;
    if (state <= WEATHER_PARTLY_CLOUDY) return mix(clearVal, cloudyVal, state - WEATHER_CLEAR);
    if (state <= WEATHER_OVERCAST) return mix(cloudyVal, overcastVal, state - WEATHER_PARTLY_CLOUDY);
    if (state <= WEATHER_RAIN) return mix(overcastVal, rainVal, state - WEATHER_OVERCAST);
    if (state <= WEATHER_STORM) return mix(rainVal, stormVal, state - WEATHER_RAIN);
    if (state <= WEATHER_HEAVY_STORM) return mix(stormVal, heavyStormVal, state - WEATHER_STORM);
    return mix(heavyStormVal, fogVal, state - WEATHER_HEAVY_STORM);
}

#endif