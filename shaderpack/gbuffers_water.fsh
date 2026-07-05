#version 150

// Water GBuffer fragment shader.
// Outputs deferred PBR buffers for photorealistic water rendering.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/water_physics.glsl"
#include "lib/material/material_data.glsl"
#include "lib/material/material_encode.glsl"

in vec3 vWorldPos;
in vec3 vNormal;
in vec2 vUV;
in vec4 vColor;

out vec4 gAlbedoMetal;
out vec4 gNormalRough;
out vec4 gEmissiveAO;
out vec4 gWorldPosDepth;

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform float time;

// Material controls (will be wired via shaderpack options/presets in later stages).
uniform float waterMetallic;
uniform float waterRoughness;

// Depth-based coloring & absorption.
uniform float waterDepthScale;
uniform vec3 waterAbsorptionCoeff; // sigma_a
uniform float waterFoamStrength;
uniform float waterFoamPower;

uniform float underwaterFogDensity;
uniform float underwaterFogAmount;

// Rain intensity proxy (0..1). Later tied to weather.
uniform float rainStrength;

vec3 waterBaseAlbedo() {
    // Use the block texture as color modulation.
    vec3 tex = texture2D(texture, vUV).rgb;

    // Physically plausible base water albedo: mostly blue-green with texture micro-variation.
    vec3 tint = vec3(0.03, 0.18, 0.28);
    float t = 0.25;
    return mix(tint, tex, t);
}

float getAO() {
    // Lightmap Y as AO proxy.
    vec2 lm = texture2D(lightmap, vec2(0.5)).rg;
    return saturate(lm.y);
}

vec3 packNormal(vec3 n) {
    n = normalize(n);
    return n * 0.5 + 0.5;
}

void main() {
    vec3 N = normalize(vNormal);

    // Approximate view direction from world position.
    // In many pipelines, gbufferModelViewInverse/projection are provided; we avoid dependence.
    // Use a conservative camera assumption: view from origin in world.
    vec3 V = safeNormalize(-vWorldPos);

    float ao = getAO();

    // Roughness driven by wave normal variance: more glancing -> rougher.
    float ndv = saturate(dot(N, V));
    float rough = waterRoughness + (1.0 - ndv) * 0.10;
    rough = saturate(rough);

    // Fresnel energy tint into spec handled later in lighting; here we approximate albedo.
    vec3 albedo = waterBaseAlbedo();

    // Depth coloring approximation: use world height above assumed water bed.
    // Minecraft water is mostly planar; we approximate shallow vs deep with Y.
    // This is stable even without depth buffer access.
    float depth = max(0.0, -vWorldPos.y) * waterDepthScale;

    // Absorption by distance.
    vec3 absorption = beerLambert(waterAbsorptionCoeff, depth);
    albedo *= absorption;

    // Foam via normal deviation: sharper -> less foam.
    float foamBase = foamFromSteepness(ndv);

    // Rain ripples add extra micro foam.
    foamBase *= (1.0 + rainRipple(vWorldPos.xz * 0.5, time, rainStrength) * 0.75);

    float foam = saturate(pow(foamBase, waterFoamPower) * waterFoamStrength);

    // Foam increases perceived albedo.
    vec3 foamAlbedo = vec3(0.85, 0.90, 0.95);
    albedo = mix(albedo, foamAlbedo, foam);

    // Emissive: underwater caustics and bioluminescence would require extra buffers.
    // Use emissive as minimal hint, controlled by foam to avoid artifacts.
    float emissive = foam * 0.04;

    MaterialData material = materialDefault();
    material.albedo = albedo;
    material.normal = N;
    material.roughness = rough;
    material.metallic = waterMetallic;
    material.ao = ao;
    material.emission = emissive;

    gWorldPosDepth = vec4(vWorldPos, 1.0);

    vec4 albedoMetal;
    vec4 normalRough;
    vec4 emissiveAO;
    materialEncodeToGBuffer(material, albedoMetal, normalRough, emissiveAO);
    gAlbedoMetal = albedoMetal;
    gNormalRough = normalRough;
    gEmissiveAO = emissiveAO;
}

