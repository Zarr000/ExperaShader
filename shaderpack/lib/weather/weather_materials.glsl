#version 150
#ifndef WEATHER_MATERIALS_GLSL
#define WEATHER_MATERIALS_GLSL

#include "weather_common.glsl"
#include "weather_wetness.glsl"

// Weather-to-Material Framework integration
// Materials consume wetness, temperature, and exposure for weather response

struct WeatherMaterialResponse {
    float wetness;
    float specularBoost;
    float albedoDarkening;
    float roughnessChange;
    float emissiveBoost;
    vec3 tint;
};

// Compute material response to weather conditions
WeatherMaterialResponse weatherMaterialResponse(WeatherWetness ww, float materialRoughness) {
    WeatherMaterialResponse r;
    r.wetness = 0.0;
    r.specularBoost = 0.0;
    r.albedoDarkening = 0.0;
    r.roughnessChange = 0.0;
    r.emissiveBoost = 0.0;
    r.tint = vec3(1.0);

    // Wetness from weather
    r.wetness = weatherMaterialWetness(ww, materialRoughness);

    // Specular boost: wet surfaces are more reflective
    r.specularBoost = weatherWetnessSpecular(r.wetness, 0.04);

    // Albedo darkening: wet surfaces appear darker
    r.albedoDarkening = weatherWetnessDarkening(r.wetness);

    // Roughness change: wet surfaces appear smoother
    r.roughnessChange = 1.0 - r.wetness * 0.3;

    // Emissive boost: wet surfaces can appear slightly emissive (reflections)
    r.emissiveBoost = r.wetness * 0.05;

    // Tint: slight blue shift when wet
    r.tint = mix(vec3(1.0), vec3(0.95, 0.97, 1.0), r.wetness * 0.3);

    return r;
}

// Apply weather response to material albedo
vec3 weatherApplyAlbedo(vec3 albedo, WeatherMaterialResponse r) {
    return albedo * r.albedoDarkening * r.tint;
}

// Apply weather response to material specular
float weatherApplySpecular(float baseSpecular, WeatherMaterialResponse r) {
    return baseSpecular * r.specularBoost;
}

// Apply weather response to material roughness
float weatherApplyRoughness(float baseRoughness, WeatherMaterialResponse r) {
    return baseRoughness * r.roughnessChange;
}

// Apply weather response to material emissive
float weatherApplyEmissive(float baseEmissive, WeatherMaterialResponse r) {
    return baseEmissive + r.emissiveBoost;
}

#endif