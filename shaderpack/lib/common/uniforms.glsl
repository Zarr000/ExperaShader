#version 150

#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

uniform float time;
uniform float frameTimeCounter;
uniform vec2 screenSize;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 previousViewProjection;
uniform mat4 currentViewProjection;
uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;

uniform float exposure;
uniform float exposureAdaptSpeed;
uniform float autoExposure;
uniform float presetLow;
uniform float presetMedium;
uniform float presetHigh;
uniform float presetUltra;

uniform float bloomIntensity;
uniform float bloomThreshold;
uniform float lensDirtIntensity;
uniform float vignetteIntensity;
uniform float chromaticAberrationStrength;
uniform float motionBlurStrength;
uniform float taaEnabled;
uniform float taaFeedback;
uniform float taaSharpen;
uniform float motionBlurEnabled;
uniform float velocityClamp;
uniform float ssaoEnabled;
uniform float ssaoRadius;
uniform float ssaoBias;
uniform float ssrEnabled;
uniform float ssrQuality;
uniform float cloudsEnabled;
uniform float cloudsQuality;
uniform float volumetricFogEnabled;
uniform float volumetricFogQuality;
uniform float shadowEnabled;
uniform float shadowQuality;
uniform float contactShadowEnabled;
uniform float contactShadowStrength;
uniform float debugMode;

uniform sampler2D gPrevSSR;
uniform sampler2D gHistoryPrev;
uniform sampler2D gPrevVelocity;
uniform sampler2D gVelocity;
uniform sampler2D gHiZ;
uniform float hiZEnabled;

// Minecraft/OptiFine/Iris runtime uniforms
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 sunColor;
uniform vec3 moonColor;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform float fogDensity;
uniform float rainStrength;
uniform float wetness;
uniform float worldTime;

// Atmosphere quality control
uniform float atmosphereQuality;
uniform float atmosphereLUTResolution;
uniform float atmosphereSampleCount;

#endif