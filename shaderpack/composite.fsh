#version 150

// Composite pass: apply SSR/volumetrics and final tone mapping.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/lighting/pbr.glsl"
#include "lib/post/pipeline.glsl"

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
uniform sampler2D gSSGI;

void main() {
    vec3 base = texture2D(gColor, vUV).rgb;

    float ao = texture2D(gAO, vUV).a;
    vec3 fogCol = texture2D(gFogScatter, vUV).rgb;
    float fogFactor = texture2D(gFogFactor, vUV).a;
    float cloudShadow = texture2D(gCloudShadow, vUV).a;

    vec3 ssr = texture2D(gSSR, vUV).rgb;
    float ssrHit = texture2D(gSSR, vUV).a;

    vec3 lit = base * ao;

    vec3 skyRefl = texture2D(gFogScatter, vUV).rgb;

    float miss = 1.0 - ssrHit;
    vec3 fallback = mix(ssr, skyRefl, miss);

    float ssrWeight = mix(0.18, 0.7, ssrHit);
    lit += fallback * ssrWeight;

    lit = mix(lit, fogCol, fogFactor);
    lit *= mix(1.0, 0.92, fogFactor);
    lit *= mix(1.0, cloudShadow, 0.75);

    vec3 ssgi = texture2D(gSSGI, vUV).rgb;
    float ssgiValid = texture2D(gSSGI, vUV).a;
    lit += ssgi * ssgiValid;

    vec3 hdr = max(lit, vec3(0.0));
    hdr = applyAutoExposure(hdr, exposure, autoExposure);
    hdr = applyChromaticAberration(gColor, vUV, hdr, chromaticAberrationStrength);
    hdr = applyFilmGrain(hdr, vUV, 0.25 + 0.75 * (1.0 - presetLow), time);
    hdr = applySharpen(gColor, vUV, hdr, taaSharpen * 0.15 + 0.02);

    vec3 mapped = acesFilmic(hdr);
    vec3 srgb = linearToSRGB(mapped);
    FragColor = vec4(srgb, 1.0);
}

