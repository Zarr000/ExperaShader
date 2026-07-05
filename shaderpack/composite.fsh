#version 150

// Composite pass: Renderer Core V2 orchestration point
// Integrates all subsystems via render graph execution

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
#include "lib/weather/weather_util.glsl"
#include "lib/water/water_common.glsl"
#include "lib/water/water_util.glsl"
#include "lib/renderer/renderer_util.glsl"
#include "lib/renderer/renderer_resource.glsl"

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

// Renderer Core state
RendererState gRenderer;

void main() {
    // Initialize Renderer Core once per frame (first fragment)
    if (gl_FragCoord.x < 1.0 && gl_FragCoord.y < 1.0) {
        gRenderer = rendererInit(frameTimeCounter, 0.016, frameTimeCounter);
        rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_COLOR, RESOURCE_STATE_READ);
    }

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

    // Weather Engine integration: single evaluation per frame
    WeatherFrame weather = weatherComputeFrame(frameTimeCounter, 0.016, cameraPosition);

    // Atmosphere Engine integration
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

    // Modulate atmosphere with weather
    p = weatherApplyToAtmosphere(p, weather.lighting, weather.state);
    rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_HISTORY_TAA, RESOURCE_STATE_READ);

    // Volumetric Cloud Rendering
    if (cloudShouldRender(cloudsQuality)) {
        CloudParameters c = weatherDrivenClouds(waterApplyToAtmosphere(p, weather.lighting, weather.state), r, weather.state, weather.wind, frameTimeCounter);
        CloudRaymarchConfig cfg = cloudRaymarchConfig(c);

        float depth = texture2D(gDepth, vUV).r;
        vec3 viewPos = reconstructViewPosition(depth, vUV, gbufferProjection, screenSize);
        vec3 viewDir = normalize(viewPos);
        vec3 worldViewDir = normalize(mat3(gbufferModelViewInverse) * viewDir);

        float maxDist = waterApplyToAtmosphere(p, weather.lighting, weather.state).fogDensity * 100.0;
        CloudRaymarchResult cloudResult = cloudRaymarch(
            cameraPosition, worldViewDir, maxDist, p, r, c, cfg,
            frameTimeCounter, vUV
        );

        vec4 wp = texture2D(gWorldPosDepth, vUV);
        vec3 worldPos = wp.xyz;
        CloudTemporalState temporal = cloudTemporalReproject(
            vUV, worldPos, depth, gCloudHistory, c.temporalFeedback
        );

        vec3 cloudRadiance = cloudTemporalAccumulate(
            cloudResult.radiance, temporal.historyRadiance, temporal.blendFactor
        );

        float cloudAlpha = cloudCompositingAlpha(cloudResult.transmittance);
        lit = cloudComposite(lit, cloudRadiance, cloudAlpha);

        rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_CLOUD, RESOURCE_STATE_WRITTEN);
        rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_HISTORY_CLOUD, RESOURCE_STATE_WRITTEN);
    }

    // Water Renderer integration
    if (waterQualityLevel() >= WATER_PERFORMANCE) {
        vec4 wp = texture2D(gWorldPosDepth, vUV);
        vec3 worldPos = wp.xyz;

        float waterDepth = texture2D(gDepth, vUV).r;
        vec3 viewPos = reconstructViewPosition(waterDepth, vUV, gbufferProjection, screenSize);
        vec3 viewDir = normalize(viewPos);
        float distance = length(viewPos);

        WaterSurfaceSample waterSample = waterSampleSurface(
            worldPos.xz, worldPos, frameTimeCounter, distance,
            weather, p, r, waterQualityLevel()
        );

        vec3 ssrCol = texture2D(gSSR, vUV).rgb;
        float ssrHit = texture2D(gSSR, vUV).a;
        WaterReflection waterRef = waterComputeReflection(
            viewDir, waterSample.normal, worldPos,
            p, r, ssrCol, ssrHit, lit, waterSample.roughness
        );

        WaterRefraction waterRefr = waterComputeRefraction(
            vUV, waterSample.normal, viewDir,
            waterSample.depth, waterSample.roughness, waterQualityLevel()
        );

        vec3 lightDir = normalize(r.sunDirection);
        WaterScattering waterScatter = waterComputeScattering(
            lightDir, viewDir, waterSample.normal,
            waterSample.albedo, waterSample.depth, p, r, weather.fog
        );

        float shoreDist = 5.0;
        float caustic = waterCaustics(worldPos.xz, waterSample.depth, shoreDist,
                                     waterDefaultParams().causticStrength, frameTimeCounter);

        vec3 waterColor = waterSurfaceBRDF(
            lightDir, viewDir, waterSample.normal, waterSample.albedo,
            waterSample.roughness, waterRef.combined, waterScatter.singleScatter,
            waterSample.fresnel
        );

        float waterAlpha = waterCompositingAlpha(1.0);
        lit = mix(lit, waterColor, waterAlpha * 0.5);

        rendererUpdateResourceLifetime(gRenderer.graph, RESOURCE_ID_WATER, RESOURCE_STATE_WRITTEN);
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