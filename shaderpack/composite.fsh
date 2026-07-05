#version 150

// Composite pass: apply SSR/volumetrics and final tone mapping.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/tonemap.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gAO;
uniform sampler2D gFogScatter;
uniform sampler2D gFogFactor;
uniform sampler2D gCloudShadow;
// SSR output (from SSR pass)
uniform sampler2D gSSR;
uniform sampler2D gDepth;

uniform float exposure;


void main() {
    vec3 base = texture2D(gColor, vUV).rgb;

    float ao = texture2D(gAO, vUV).a;
    vec3 fogCol = texture2D(gFogScatter, vUV).rgb;
    float fogFactor = texture2D(gFogFactor, vUV).a;
    float cloudShadow = texture2D(gCloudShadow, vUV).a;

    vec3 ssr = texture2D(gSSR, vUV).rgb;
    float ssrHit = texture2D(gSSR, vUV).a;

    // Apply AO.
    vec3 lit = base * ao;

    // Sky reflection fallback using atmospheric skyColor approximation.
    // If SSR misses (low hit), blend in sky.
    // We approximate sky by using fogScatter as a sky-like color source.
    vec3 skyRefl = texture2D(gFogScatter, vUV).rgb;

    // Rough/material reflection filtering handled in SSR pass; here apply view-angle fade.
    // Normal is not available in composite, so we keep conservative fade.
    float miss = 1.0 - ssrHit;
    vec3 fallback = mix(ssr, skyRefl, miss);

    // SSR contribution weighting: stronger when confident.
    float ssrWeight = mix(0.18, 0.7, ssrHit);
    lit += fallback * ssrWeight;


    // Volumetrics.
    lit = mix(lit, fogCol, fogFactor);

    // Better edge handling / reflection fading with fog (reduces SSR popping).
    lit *= mix(1.0, 0.92, fogFactor);


    // Cloud shadows.
    lit *= mix(1.0, cloudShadow, 0.75);

    // Integrate SSGI diffuse indirect if available.
    // gSSGI is expected to be the denoised/temporal resolved diffuse GI buffer.
    vec3 ssgi = texture2D(gSSGI, vUV).rgb;
    float ssgiValid = texture2D(gSSGI, vUV).a;
    lit += ssgi * ssgiValid;

    // Tone map.
    vec3 mapped = acesFilmic(lit * exposure);


    // Gamma.
    vec3 srgb = linearToSRGB(mapped);
    FragColor = vec4(srgb, 1.0);
}

