#version 150

// Centralized uniform declarations.
// OptiFine/Iris provide many of these automatically; we declare additional globals.

#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

// Time
uniform float time;
uniform float frameTimeCounter;

// Resolution
uniform vec2 screenSize;

// Camera matrices
uniform mat4 gbufferModelViewInverse;

// Projection and view
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 previousViewProjection;
uniform mat4 currentViewProjection;

// Lighting / exposure
uniform float exposure;
uniform float exposureAdaptSpeed;
uniform float autoExposure; // 0..1

// Quality presets (0..1 toggles)
uniform float presetLow;
uniform float presetMedium;
uniform float presetHigh;
uniform float presetUltra;

// Post-processing
uniform float bloomIntensity;
uniform float bloomThreshold;
uniform float lensDirtIntensity;
uniform float vignetteIntensity;
uniform float chromaticAberrationStrength;

// Motion blur
uniform float motionBlurStrength;

// TAA
uniform float taaEnabled;
uniform float taaFeedback;
uniform float taaSharpen;

// Previous frame matrices / camera
uniform mat4 previousViewProjection;
uniform mat4 currentViewProjection;
uniform vec3 previousCameraPosition;
uniform vec3 cameraPosition;

// Motion vectors
uniform float motionBlurEnabled;
uniform float motionBlurStrength;
uniform float velocityClamp;

// History samplers (names used by resolve passes)
uniform sampler2D gPrevSSR;
uniform sampler2D gHistoryPrev;
uniform sampler2D gPrevVelocity;
uniform sampler2D gVelocity;

// SSAO
uniform float ssaoEnabled;
uniform float ssaoRadius;
uniform float ssaoBias;

// SSR
uniform float ssrEnabled;
uniform float ssrQuality;


// Volumetrics
uniform float cloudsEnabled;
uniform float cloudsQuality;
uniform float volumetricFogEnabled;
uniform float volumetricFogQuality;

// Shadows
uniform float shadowEnabled;
uniform float shadowQuality;
uniform float contactShadowEnabled;
uniform float contactShadowStrength;

// Hi-Z / depth pyramid
uniform sampler2D gHiZ;
uniform float hiZEnabled;

#endif


