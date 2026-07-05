#version 150
#ifndef WEATHER_TRANSITION_GLSL
#define WEATHER_TRANSITION_GLSL

#include "weather_common.glsl"
#include "../common/noise.glsl"

// Weather transition system
// Provides smooth interpolation between weather states
// Avoids abrupt state changes

// Initialize a weather transition
WeatherTransition weatherTransitionInit(float fromState, float toState, float duration) {
    WeatherTransition t;
    t.duration = max(duration, 0.1);
    t.elapsed = 0.0;
    t.progress = 0.0;
    t.fromState = fromState;
    t.toState = toState;
    t.active = true;
    return t;
}

// Update transition progress
void weatherTransitionUpdate(WeatherTransition t, float deltaTime) {
    t.elapsed += deltaTime;
    t.progress = saturate(t.elapsed / t.duration);
    if (t.progress >= 1.0) {
        t.active = false;
    }
}

// Get interpolated weather state during transition
float weatherTransitionState(WeatherTransition t) {
    return mix(t.fromState, t.toState, t.progress);
}

// Smooth interpolation between two weather parameter sets
float weatherTransitionParameter(float fromVal, float toVal, float progress) {
    // Smooth step for natural-feeling transitions
    float smooth = progress * progress * (3.0 - 2.0 * progress);
    return mix(fromVal, toVal, smooth);
}

// Interpolate entire WeatherState between two states
WeatherState weatherTransitionBlend(WeatherState from, WeatherState to, float progress) {
    WeatherState result;
    float s = progress * progress * (3.0 - 2.0 * progress);

    result.state = mix(from.state, to.state, s);
    result.coverage = mix(from.coverage, to.coverage, s);
    result.humidity = mix(from.humidity, to.humidity, s);
    result.precipitation = mix(from.precipitation, to.precipitation, s);
    result.stormIntensity = mix(from.stormIntensity, to.stormIntensity, s);
    result.fogDensity = mix(from.fogDensity, to.fogDensity, s);
    result.windSpeed = mix(from.windSpeed, to.windSpeed, s);
    result.windDirection = normalize(mix(from.windDirection, to.windDirection, s));
    result.wetness = mix(from.wetness, to.wetness, s);
    result.temperature = mix(from.temperature, to.temperature, s);
    result.visibility = mix(from.visibility, to.visibility, s);
    result.cloudDensity = mix(from.cloudDensity, to.cloudDensity, s);
    result.cloudAltitude = mix(from.cloudAltitude, to.cloudAltitude, s);
    result.lightning = mix(from.lightning, to.lightning, s);

    return result;
}

// Transition duration based on weather state change severity
float weatherTransitionDuration(float fromState, float toState) {
    float diff = abs(toState - fromState);
    // Small changes transition quickly, large changes take longer
    float baseDuration = 2.0; // seconds
    float severityMultiplier = 1.0 + diff * 2.0;
    return baseDuration * severityMultiplier;
}

// Determine if a weather state change should trigger a transition
bool weatherShouldTransition(WeatherState current, WeatherState target, float threshold) {
    float diff = abs(target.state - current.state);
    return diff > threshold;
}

#endif