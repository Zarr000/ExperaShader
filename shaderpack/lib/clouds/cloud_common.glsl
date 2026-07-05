#version 150
#ifndef CLOUD_COMMON_GLSL
#define CLOUD_COMMON_GLSL

#include "../common/math.glsl"
#include "../common/uniforms.glsl"
#include "../atmosphere/atmosphere_common.glsl"

// Cloud quality presets
#define CLOUD_PERFORMANCE 0.0
#define CLOUD_BALANCED    1.0
#define CLOUD_HIGH        2.0
#define CLOUD_ULTRA       3.0
#define CLOUD_EXTREME     4.0

// Cloud layer heights (in world units, sea level = 64)
#define CLOUD_BASE_HEIGHT     192.0
#define CLOUD_TOP_HEIGHT      256.0
#define CLOUD_THICKNESS       64.0
#define CLOUD_ALTITUDE_MIN    128.0
#define CLOUD_ALTITUDE_MAX    320.0

// Cloud physical constants
#define CLOUD_EXTINCTION_MAX  20.0
#define CLOUD_SCATTERING_MAX  15.0
#define CLOUD_AMBIENT_MIN     0.05
#define CLOUD_PHASE_G         0.6
#define CLOUD_PHASE_G_SILVER  -0.2

struct CloudParameters {
    float baseHeight;
    float topHeight;
    float thickness;
    float coverage;
    float density;
    float humidity;
    float stormFactor;
    float erosion;
    float windSpeed;
    vec2 windDirection;
    float quality;
    float temporalFeedback;
};

struct CloudDensitySample {
    float density;
    float coverage;
    float erosion;
    float heightGradient;
    float weatherModulation;
};

struct CloudRaymarchConfig {
    float maxSteps;
    float shadowSteps;
    float stepSize;
    float shadowStepSize;
    float depthThreshold;
    float noiseOctaves;
    float detailOctaves;
};

// Compute cloud parameters from runtime uniforms
CloudParameters cloudComputeParameters(AtmosphereRuntime r) {
    CloudParameters c;
    c.baseHeight = CLOUD_BASE_HEIGHT;
    c.topHeight = CLOUD_TOP_HEIGHT;
    c.thickness = CLOUD_THICKNESS;
    c.coverage = saturate(0.5 + 0.5 * r.weatherIntensity);
    c.density = 1.0 + r.weatherIntensity * 0.5;
    c.humidity = saturate(0.4 + 0.6 * r.weatherIntensity);
    c.stormFactor = r.weatherIntensity;
    c.erosion = 0.5 + 0.5 * (1.0 - r.weatherIntensity);
    c.windSpeed = 0.5 + r.weatherIntensity * 0.3;
    c.windDirection = vec2(0.5, 0.3);
    c.quality = clamp(cloudsQuality, 0.0, 4.0);
    c.temporalFeedback = 0.85;
    return c;
}

// Quality-scaled cloud parameters
CloudRaymarchConfig cloudRaymarchConfig(CloudParameters c) {
    CloudRaymarchConfig cfg;
    float q = c.quality;

    if (q <= CLOUD_PERFORMANCE) {
        cfg.maxSteps = 16.0;
        cfg.shadowSteps = 4.0;
        cfg.stepSize = 8.0;
        cfg.shadowStepSize = 16.0;
        cfg.depthThreshold = 0.01;
        cfg.noiseOctaves = 3.0;
        cfg.detailOctaves = 2.0;
    } else if (q <= CLOUD_BALANCED) {
        cfg.maxSteps = 32.0;
        cfg.shadowSteps = 6.0;
        cfg.stepSize = 6.0;
        cfg.shadowStepSize = 12.0;
        cfg.depthThreshold = 0.005;
        cfg.noiseOctaves = 4.0;
        cfg.detailOctaves = 3.0;
    } else if (q <= CLOUD_HIGH) {
        cfg.maxSteps = 48.0;
        cfg.shadowSteps = 8.0;
        cfg.stepSize = 4.0;
        cfg.shadowStepSize = 10.0;
        cfg.depthThreshold = 0.003;
        cfg.noiseOctaves = 5.0;
        cfg.detailOctaves = 4.0;
    } else if (q <= CLOUD_ULTRA) {
        cfg.maxSteps = 64.0;
        cfg.shadowSteps = 10.0;
        cfg.stepSize = 3.0;
        cfg.shadowStepSize = 8.0;
        cfg.depthThreshold = 0.002;
        cfg.noiseOctaves = 6.0;
        cfg.detailOctaves = 5.0;
    } else {
        cfg.maxSteps = 96.0;
        cfg.shadowSteps = 12.0;
        cfg.stepSize = 2.0;
        cfg.shadowStepSize = 6.0;
        cfg.depthThreshold = 0.001;
        cfg.noiseOctaves = 7.0;
        cfg.detailOctaves = 6.0;
    }

    return cfg;
}

// Cloud height gradient (0 at base, 1 at top)
float cloudHeightGradient(float height, float base, float top) {
    return saturate((height - base) / max(top - base, 1.0));
}

// Cloud altitude range check
bool cloudInRange(float height, float base, float top) {
    return height >= base && height <= top;
}

#endif