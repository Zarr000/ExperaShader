#version 150
#ifndef ATMOSPHERE_COMMON_GLSL
#define ATMOSPHERE_COMMON_GLSL

#include "../common/math.glsl"
#include "../common/uniforms.glsl"

// Quality preset constants
#define ATMOSPHERE_PERFORMANCE 0.0
#define ATMOSPHERE_BALANCED    1.0
#define ATMOSPHERE_HIGH        2.0
#define ATMOSPHERE_ULTRA       3.0
#define ATMOSPHERE_EXTREME     4.0

// Physical constants
#define ATMOSPHERE_PI          3.14159265359
#define ATMOSPHERE_TWO_PI      6.28318530718
#define ATMOSPHERE_FOUR_PI     12.5663706144
#define ATMOSPHERE_SUN_SOLID_ANGLE 6.794e-5
#define ATMOSPHERE_PLANET_RADIUS    6371000.0
#define ATMOSPHERE_ATMOSPHERE_RADIUS 6471000.0
#define ATMOSPHERE_RAYLEIGH_SCALE    8000.0
#define ATMOSPHERE_MIE_SCALE         1200.0
#define ATMOSPHERE_OZONE_SCALE       25000.0

struct AtmosphereParameters {
    vec3 planetCenter;
    float planetRadius;
    float atmosphereRadius;
    vec3 rayleighScattering;
    vec3 mieScattering;
    vec3 mieExtinction;
    vec3 ozoneAbsorption;
    float rayleighScaleHeight;
    float mieScaleHeight;
    float ozoneScaleHeight;
    float mieG;
    float sunIntensity;
    float moonIntensity;
    float weatherIntensity;
    float fogDensity;
};

struct AtmosphereRuntime {
    vec3 sunDirection;
    vec3 moonDirection;
    float sunElevation;
    float sunAzimuth;
    float moonElevation;
    float moonAzimuth;
    float moonPhase;
    float moonIllumination;
    float timeOfDay;
    float cameraAltitude;
    float fogAltitude;
    float waterLevel;
    float mountainHeight;
    float weatherIntensity;
    float fogDensity;
    float quality;
    float sampleCount;
    float lutResolution;
};

// Quality scaling helpers
float atmosphereQualityScale(float quality, float low, float mid, float high, float ultra) {
    float q = clamp(quality, 0.0, 4.0);
    if (q <= ATMOSPHERE_PERFORMANCE) return low;
    if (q <= ATMOSPHERE_BALANCED) return mid;
    if (q <= ATMOSPHERE_HIGH) return high;
    if (q <= ATMOSPHERE_ULTRA) return ultra;
    return ultra + 0.5;
}

// Compute runtime atmosphere parameters from Minecraft uniforms
AtmosphereRuntime atmosphereComputeRuntime() {
    AtmosphereRuntime r;

    // Sun direction from sunPosition (normalized direction to sun)
    r.sunDirection = normalize(sunPosition);
    r.moonDirection = normalize(moonPosition);

    // Elevation and azimuth
    r.sunElevation = clamp(dot(r.sunDirection, vec3(0.0, 1.0, 0.0)), -1.0, 1.0);
    r.sunAzimuth = atan(r.sunDirection.x, r.sunDirection.z);
    r.moonElevation = clamp(dot(r.moonDirection, vec3(0.0, 1.0, 0.0)), -1.0, 1.0);
    r.moonAzimuth = atan(r.moonDirection.x, r.moonDirection.z);

    // Moon phase from relative sun/moon position
    float sunMoonDot = dot(r.sunDirection, r.moonDirection);
    r.moonPhase = saturate(0.5 - 0.5 * sunMoonDot);
    r.moonIllumination = 1.0 - abs(sunMoonDot);

    // Time of day from sun elevation
    r.timeOfDay = saturate(r.sunElevation * 0.5 + 0.5);

    // Camera altitude from camera position
    r.cameraAltitude = max(cameraPosition.y - 64.0, 0.0); // Sea level at y=64

    // Terrain parameters
    r.fogAltitude = 64.0; // Default fog base
    r.waterLevel = 63.0;  // Sea level
    r.mountainHeight = 0.0; // Will be computed from depth

    // Weather
    r.weatherIntensity = rainStrength;
    r.fogDensity = fogDensity;

    // Quality
    r.quality = clamp(atmosphereQuality, 0.0, 4.0);
    r.sampleCount = max(atmosphereSampleCount, 1.0);
    r.lutResolution = max(atmosphereLUTResolution, 32.0);

    return r;
}

// Height above planet surface
float atmosphereHeightAboveSurface(vec3 worldPosition, vec3 planetCenter, float planetRadius) {
    return max(length(worldPosition - planetCenter) - planetRadius, 0.0);
}

// Sun elevation helper
float atmosphereSunElevation(vec3 sunDir) {
    return clamp(dot(sunDir, vec3(0.0, 1.0, 0.0)), -1.0, 1.0);
}

// Moon elevation helper
float atmosphereMoonElevation(vec3 moonDir) {
    return clamp(dot(moonDir, vec3(0.0, 1.0, 0.0)), -1.0, 1.0);
}

// Azimuth helper
float atmosphereAzimuth(vec3 dir) {
    return atan(dir.x, dir.z);
}

// Twilight factor - smooth transition through all twilight phases
float atmosphereTwilightFactor(float elevation) {
    // Astronomical twilight: sun 18-12 degrees below horizon
    float astro = smoothstep(-0.31, -0.21, elevation);
    // Nautical twilight: sun 12-6 degrees below horizon
    float nautical = smoothstep(-0.21, -0.105, elevation);
    // Civil twilight: sun 6-0 degrees below horizon
    float civil = smoothstep(-0.105, 0.0, elevation);
    // Daytime
    float day = smoothstep(0.0, 0.05, elevation);

    // Blend twilight phases
    float twilight = mix(astro, nautical, smoothstep(-0.31, -0.105, elevation));
    twilight = mix(twilight, civil, smoothstep(-0.21, 0.0, elevation));
    return mix(twilight, day, smoothstep(-0.105, 0.05, elevation));
}

// Golden hour factor
float atmosphereGoldenHourFactor(float elevation) {
    float goldenStart = -0.05;
    float goldenPeak = 0.08;
    float goldenEnd = 0.22;
    return smoothstep(goldenStart, goldenPeak, elevation) *
           (1.0 - smoothstep(goldenPeak, goldenEnd, elevation));
}

// Horizon coloration for sunrise/sunset
vec3 atmosphereHorizonColor(float elevation, float weather) {
    // Deep red/orange at horizon, fading to yellow then blue
    float horizonGlow = exp(-abs(elevation) * 8.0);
    vec3 warmColor = vec3(1.0, 0.6, 0.2);
    vec3 midColor = vec3(1.0, 0.85, 0.5);
    vec3 coolColor = vec3(0.8, 0.85, 1.0);

    float warmWeight = exp(-elevation * 15.0) * (1.0 - smoothstep(0.0, 0.15, elevation));
    float midWeight = exp(-abs(elevation) * 5.0);
    float coolWeight = 1.0 - midWeight;

    vec3 color = warmColor * warmWeight + midColor * midWeight * 0.5 + coolColor * coolWeight * 0.3;
    color *= horizonGlow * (1.0 - weather * 0.5);
    return color;
}

// Local density factor based on terrain
float atmosphereLocalDensityFactor(float altitude, float fogAltitude, float waterLevel, float mountainHeight) {
    float altitudeTerm = saturate((altitude - fogAltitude) * 0.0025 + 0.15);
    float terrainTerm = saturate(mountainHeight * 0.0008);
    float waterTerm = saturate((waterLevel - altitude) * 0.01);
    return mix(0.6, 1.0, altitudeTerm) * (0.7 + 0.3 * terrainTerm) * (0.85 + 0.15 * waterTerm);
}

// Night brightness adaptation
float atmosphereNightAdaptation(float sunElevation, float moonElevation, float moonIllumination) {
    float nightFactor = 1.0 - smoothstep(-0.15, 0.05, sunElevation);
    float moonBoost = smoothstep(-0.15, 0.1, moonElevation) * moonIllumination;
    return mix(0.02, 1.0, nightFactor * (0.3 + 0.7 * moonBoost));
}

// Atmospheric attenuation factor
float atmosphereAttenuation(float height, float density) {
    return exp(-height * density * 0.001);
}

#endif