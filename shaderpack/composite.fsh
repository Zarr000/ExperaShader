#version 150

// Composite pass: apply SSR/volumetrics, cloud rendering, and final tone mapping.
// Integrated with Volumetric Cloud Engine V2 and Atmosphere Engine V2.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/lighting/pbr.glsl"
#include "lib/post/pipeline.glsl"
#include "lib/atmosphere/atmosphere_common.glsl"
#include "lib/atmosphere/atmosphere_lighting.glsl"
#include "lib/atmosphere/atmosphere_lut.glsl"
#include "lib/clouds/cloud_common.glsl"
#include "lib/clouds/cloud_quality.glsl"
#include "lib/clouds/cloud_raymarch.glsl"
#include "lib/clouds/cloud_shadow.glsl"
#include "lib/clouds/cloud_util.glsl"
#include "lib/clouds/cloud_temporal.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gAO;
uniform sampler2D gFogScatter;
uniform sampler2D gFogFactor;
uniform sampler2D gCloudShadow;
uniform sampler2D gCloudHistory;
uniform sampler2D gSSR;
uniform sampler2D gDepth;
uniform sampler2D gSSGI;
uniform sampler2D gWorldPosDepth;

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

    // Volumetric Cloud Rendering
    if (cloudShouldRender(cloudsQuality)) {
        // Compute atmosphere runtime
        AtmosphereParameters p;
        p.planetCenter = vec3(0.0, -ATMOSPHERE_PLANET_RADIUS, 0.0);
        p.planetRadius = ATMOSPHERE_PLANET_RADIUS;
        p.atmosphereRadius = ATMOSPHERE_ATMOSPHERE_RADIUS;
        p.rayleighScattering = vec3(5.8e-6, 1.35e-5, 3.31e-5);
        p.mieScattering = vec3(3.0e-6);
        p.mieExtinction = vec3(4.0e-6);
        p.ozoneAbsorption = vec3(0.65e-6, 1.0e-6, 0.1e-6);
        p.rayleighScaleHeight = ATMOSPHERE_RAYLEIGH_SCALE;
        p.mieScaleHeight = ATMOSPHERE_MIE_SCALE;
        p.ozoneScaleHeight = ATMOSPHERE_OZONE_SCALE;
        p.mieG = 0.76;
        p.sunIntensity = 1.0;
        p.moonIntensity = 1.0;
        p.weatherIntensity = rainStrength;
        p.fogDensity = fogDensity;

        AtmosphereRuntime r = atmosphereComputeRuntime();
        CloudParameters c = cloudComputeParameters(r);
        CloudRaymarchConfig cfg = cloudRaymarchConfig(c);

        // Reconstruct world position and view direction
        float depth = texture2D(gDepth, vUV).r;
        vec3 viewPos = reconstructViewPosition(depth, vUV, gbufferProjection, screenSize);
        vec3 viewDir = normalize(viewPos);
        vec3 worldViewDir = normalize(mat3(gbufferModelViewInverse) * viewDir);
        vec3 cameraWorldPos = cameraPosition;

        // Raymarch clouds
        float maxDist = 500.0;
        CloudRaymarchResult cloudResult = cloudRaymarch(
            cameraWorldPos,
            worldViewDir,
            maxDist,
            p,
            r,
            c,
            cfg,
            frameTimeCounter,
            vUV
        );

        // Temporal reprojection
        vec4 wp = texture2D(gWorldPosDepth, vUV);
        vec3 worldPos = wp.xyz;
        CloudTemporalState temporal = cloudTemporalReproject(
            vUV,
            worldPos,
            depth,
            gCloudHistory,
            c.temporalFeedback
        );

        // Temporal accumulation
        vec3 cloudRadiance = cloudTemporalAccumulate(
            cloudResult.radiance,
            temporal.historyRadiance,
            temporal.blendFactor
        );

        // Composite clouds over scene
        float cloudAlpha = cloudCompositingAlpha(cloudResult.transmittance);
        lit = cloudComposite(lit, cloudRadiance, cloudAlpha);
    }

    vec3 hdr = max(lit, vec3(0.0));
    hdr = applyAutoExposure(hdr, exposure, autoExposure);
    hdr = applyChromaticAberration(gColor, vUV, hdr, chromaticAberrationStrength);
    hdr = applyFilmGrain(hdr, vUV, 0.25 + 0.75 * (1.0 - presetLow), time);
    hdr = applySharpen(gColor, vUV, hdr, taaSharpen * 0.15 + 0.02);

    vec3 mapped = acesFilmic(hdr);
    vec3 srgb = linearToSRGB(mapped);
    FragColor = vec4(srgb, 1.0);
}
