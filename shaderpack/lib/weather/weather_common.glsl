#version 150
#ifndef WEATHER_COMMON_GLSL
#define WEATHER_COMMON_GLSL

#include "../common/math.glsl"
#include "../common/uniforms.glsl"
#include "../atmosphere/atmosphere_common.glsl"
#include "../clouds/cloud_common.glsl"

// Weather quality presets
#define WEATHER_PERFORMANCE 0.0
#define WEATHER_BALANCED    1.0
#define WEATHER_HIGH        2.0
#define WEATHER_ULTRA       3.0
#define WEATHER_EXTREME     4.0

// Weather state identifiers
#define WEATHER_CLEAR          0.0
#define WEATHER_PARTLY_CLOUDY  1.0
#define WEATHER_OVERCAST       2.0
#define WEATHER_RAIN           3.0
#define WEATHER_STORM          4.0
#define WEATHER_HEAVY_STORM    5.0
#define WEATHER_FOG            6.0
#define WEATHER_SNOW           7.0

struct WeatherState {
    float state;
    float coverage;
    float humidity;
    float precipitation;
    float stormIntensity;
    float fogDensity;
    float windSpeed;
    vec2 windDirection;
    float wetness;
    float temperature;
    float visibility;
    float cloudDensity;
    float cloudAltitude;
    float lightning;
};

struct WeatherTransition {
    float duration;
    float elapsed;
    float progress;
    float fromState;
    float toState;
    bool active;
};

struct WeatherWind {
    vec2 direction;
    float speed;
    float gustStrength;
    float turbulence;
    float lowFreqVariation;
    float highFreqVariation;
    vec2 gustVector;
};

struct WeatherPrecipitation {
    float intensity;
    float stormFactor;
    float drizzle;
    float lightRain;
    float heavyRain;
    float thunderstorm;
    float snowFactor;
    float dropSize;
};

struct WeatherWetness {
    float surfaceWetness;
    float dryingRate;
    float humidity;
    float evaporation;
    float puddleFactor;
    float materialResponse;
};

// Compute weather quality level
float weatherQualityLevel() {
    return clamp(cloudsQuality, 0.0, 4.0);
}

// Quality-scaled weather parameter
float weatherQualityScale(float quality, float perf, float balanced, float high, float ultra, float extreme) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= WEATHER_PERFORMANCE) return perf;
    if (q <= WEATHER_BALANCED) return mix(perf, balanced, q - WEATHER_PERFORMANCE);
    if (q <= WEATHER_HIGH) return mix(balanced, high, q - WEATHER_BALANCED);
    if (q <= WEATHER_ULTRA) return mix(high, ultra, q - WEATHER_HIGH);
    return mix(ultra, extreme, q - WEATHER_ULTRA);
}

#endif