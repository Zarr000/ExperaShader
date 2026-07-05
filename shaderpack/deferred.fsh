#version 150

// Deferred lighting pass: combines GBuffer with physically-based direct lighting.
// Integrated with Atmosphere Engine V2 for runtime-driven sun/moon/ambient.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/lighting/pbr.glsl"
#include "lib/space_transforms.glsl"
#include "lib/screen_space.glsl"
#include "lib/material/material_data.glsl"
#include "lib/material/material_decode.glsl"
#include "lib/material/material_surface.glsl"
#include "lib/shadow/shadow_util.glsl"
#include "lib/atmosphere/atmosphere_common.glsl"
#include "lib/atmosphere/atmosphere_lighting.glsl"
#include "lib/atmosphere/atmosphere_multiscatter.glsl"

in vec2 vUV;
out vec4 FragColor;

// GBuffer samplers (OptiFine/Iris naming varies; these are common).
uniform sampler2D gAlbedoMetal;
uniform sampler2D gNormalRough;
uniform sampler2D gEmissiveAO;
uniform sampler2D gWorldPosDepth;
uniform sampler2D gDepth;

// Lighting: sun/moon (Minecraft runtime)
uniform vec3 sunDirection;
uniform vec3 moonDirection;
uniform vec3 sunColor;
uniform vec3 moonColor;
uniform float sunIntensity;
uniform float moonIntensity;

// Skylight / ambient
uniform vec3 skyColor;
uniform float ambientIntensity;

// Camera
uniform vec3 cameraPosition;

float computeDayFactor(vec3 dir) {
    float y = saturate(dir.y);
    return y;
}

void main() {
    // Read GBuffer
    vec4 albm = texture2D(gAlbedoMetal, vUV);
    vec4 nr = texture2D(gNormalRough, vUV);
    vec4 ea = texture2D(gEmissiveAO, vUV);
    vec4 wp = texture2D(gWorldPosDepth, vUV);

    MaterialData material = materialDecodeFromGBuffer(albm, nr, ea);
    vec3 albedo = material.albedo;
    float metallic = material.metallic;
    vec3 N = material.normal;
    float roughness = material.roughness;
    float ao = material.ao;
    float emissive = material.emission;

    // World position reconstruction
    vec3 worldPos = wp.xyz;
    vec3 V = normalize(cameraPosition - worldPos);

    // Compute atmosphere runtime parameters
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
    p.sunIntensity = sunIntensity;
    p.moonIntensity = moonIntensity;
    p.weatherIntensity = rainStrength;
    p.fogDensity = fogDensity;

    AtmosphereRuntime r = atmosphereComputeRuntime();

    // Determine sun/moon blend based on sun direction.
    float day = computeDayFactor(sunDirection);
    float night = 1.0 - day;

    vec3 Lsun = normalize(-sunDirection);
    vec3 Lmoon = normalize(-moonDirection);

    float NoLsun = saturate(dot(N, Lsun));
    float NoLmoon = saturate(dot(N, Lmoon));

    // Direct lighting using PBR helper with atmosphere-aware colors
    vec3 sunAtmoColor = atmosphereSunIllumination(p, r, Lsun, r.cameraAltitude);
    vec3 moonAtmoColor = atmosphereMoonIllumination(p, r, Lmoon, r.cameraAltitude);

    vec3 colSun = PBR_Lit(albedo, metallic, roughness, ao, N, V, Lsun, sunAtmoColor, sunIntensity);
    vec3 colMoon = PBR_Lit(albedo, metallic, roughness, ao, N, V, Lmoon, moonAtmoColor, moonIntensity);

    // Day-night blend
    vec3 direct = mix(colMoon * (0.06 + 0.94 * (1.0 - day)), colSun, day);

    // Ambient / skylight from atmosphere engine
    vec3 F0 = materialF0(material);
    vec3 diffuse = BRDF_DiffuseLambert(albedo);

    // Atmosphere-driven ambient sky
    vec3 atmoAmbient = atmosphereAmbientSky(p, r, r.cameraAltitude);
    vec3 hemi = mix(vec3(0.02, 0.02, 0.03), atmoAmbient, saturate(N.y * 0.5 + 0.5));

    vec3 ambient = diffuse * hemi * ambientIntensity;
    float NoV = saturate(dot(N, V));
    vec3 specAmbient = F0 * (0.04 + 0.96 * pow(1.0 - NoV, 5.0));
    ambient += specAmbient * 0.1 * ambientIntensity;

    vec3 emiss = albedo * emissive;

    float shadowFactor = shadowComputeMask(worldPos, N, roughness, material.shadowMask);

    vec3 radiance = direct * shadowFactor + ambient + emiss;

    FragColor = vec4(radiance, 1.0);
}