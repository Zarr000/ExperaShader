#version 150
#ifndef WEATHER_LIGHTING_GLSL
#define WEATHER_LIGHTING_GLSL

#include "weather_common.glsl"
#include "../atmosphere/atmosphere_common.glsl"

// Weather-driven lighting modulation
// Weather influences ambient, sun/moon color, shadow softness, sky color, cloud brightness

struct WeatherLighting {
    vec3 sunColor;
    vec3 moonColor;
    vec3 skyColor;
    vec3 ambientColor;
    float sunIntensity;
    float moonIntensity;
    float ambientIntensity;
    float shadowSoftness;
    float cloudBrightness;
    float skyLuminance;
};

// Compute weather-modulated lighting parameters
WeatherLighting weatherComputeLighting(WeatherState w, AtmosphereRuntime r) {
    WeatherLighting l;
    l.sunColor = vec3(1.0);
    l.moonColor = vec3(1.0);
    l.skyColor = vec3(0.5);
    l.ambientColor = vec3(0.1);
    l.sunIntensity = 1.0;
    l.moonIntensity = 1.0;
    l.ambientIntensity = 0.5;
    l.shadowSoftness = 0.0;
    l.cloudBrightness = 1.0;
    l.skyLuminance = 0.5;

    float precip = w.precipitation;
    float storm = w.stormIntensity;
    float coverage = w.coverage;
    float humidity = w.humidity;

    // Sun color: dimmer and warmer in rain/storms
    vec3 clearSun = vec3(1.0, 0.95, 0.85);
    vec3 rainSun = vec3(0.8, 0.7, 0.55);
    vec3 stormSun = vec3(0.5, 0.4, 0.3);
    l.sunColor = mix(clearSun, rainSun, precip);
    l.sunColor = mix(l.sunColor, stormSun, storm);

    // Moon color: dimmer in overcast conditions
    vec3 clearMoon = vec3(0.8, 0.85, 1.0);
    vec3 coveredMoon = vec3(0.4, 0.45, 0.5);
    l.moonColor = mix(clearMoon, coveredMoon, coverage);

    // Sky color: gray in rain, dark in storms
    vec3 clearSky = vec3(0.4, 0.6, 1.0);
    vec3 overcastSky = vec3(0.5, 0.5, 0.55);
    vec3 stormSky = vec3(0.2, 0.2, 0.25);
    l.skyColor = mix(clearSky, overcastSky, coverage);
    l.skyColor = mix(l.skyColor, stormSky, storm);

    // Ambient color: blue in clear, gray in rain
    vec3 clearAmbient = vec3(0.2, 0.25, 0.35);
    vec3 rainAmbient = vec3(0.15, 0.15, 0.18);
    vec3 stormAmbient = vec3(0.05, 0.05, 0.08);
    l.ambientColor = mix(clearAmbient, rainAmbient, precip);
    l.ambientColor = mix(l.ambientColor, stormAmbient, storm);

    // Sun intensity: reduced by clouds and precipitation
    l.sunIntensity = 1.0 - coverage * 0.4 - precip * 0.2;

    // Moon intensity: reduced by clouds
    l.moonIntensity = 1.0 - coverage * 0.6;

    // Ambient intensity: increases in overcast (more diffuse)
    l.ambientIntensity = 0.5 + coverage * 0.3;

    // Shadow softness: increases with cloud cover
    l.shadowSoftness = coverage * 0.3 + storm * 0.4;

    // Cloud brightness: darker in storms
    l.cloudBrightness = 1.0 - storm * 0.4 - precip * 0.2;

    // Sky luminance: overall brightness of the sky
    l.skyLuminance = 1.0 - coverage * 0.4 - storm * 0.3;

    return l;
}

// Modulate atmosphere parameters with weather
AtmosphereParameters weatherModifyAtmosphere(AtmosphereParameters p, WeatherLighting l, WeatherState w) {
    p.sunIntensity *= l.sunIntensity;
    p.moonIntensity *= l.moonIntensity;
    p.weatherIntensity = w.weatherIntensity;
    p.fogDensity = w.fogDensity;
    return p;
}

#endif