#version 150

// Terrain GBuffer pass fragment shader.
// Writes material parameters for deferred PBR.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
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

// Minecraft provides these sampler uniforms in OptiFine/Iris.
// We declare them conservatively.
uniform sampler2D texture;
uniform sampler2D lightmap;

uniform float metallicOverride;
uniform float roughnessOverride;

vec3 getAlbedo() {
    // Sample base texture; fall back to vertex color.
    vec3 tex = texture2D(texture, vUV).rgb;
    vec3 albedo = mix(vColor.rgb, tex, 0.9);
    // Avoid crushed blacks.
    return max(albedo, vec3(0.001));
}

float getAO() {
    // Use lightmap Y as a cheap AO proxy.
    vec2 lm = texture2D(lightmap, vec2(0.5)).rg;
    return saturate(lm.y);
}

float getRoughness() {
    // Approx roughness from luminance variation.
    vec3 al = getAlbedo();
    float l = dot(al, vec3(0.2126, 0.7152, 0.0722));
    float r = mix(0.8, 0.25, saturate((l - 0.2) / 0.8));
    r = mix(r, roughnessOverride, step(0.0, roughnessOverride));
    return saturate(r);
}

float getMetallic() {
    float m = metallicOverride;
    return saturate(m);
}

vec3 packNormal(vec3 n) {
    n = normalize(n);
    return n * 0.5 + 0.5;
}

float getEmissive() {
    // Placeholder: use vertex color alpha as emissive hint.
    return saturate(vColor.a);
}

void main() {
    vec3 albedo = getAlbedo();
    float metallic = getMetallic();
    float roughness = getRoughness();

    vec3 N = normalize(vNormal);

    float ao = getAO();
    float emissive = getEmissive();

    // Depth packing: we store world position and approximate depth using view-space z.
    // In deferred passes, depth will be fetched separately by depth buffer.
    MaterialData material = materialDefault();
    material.albedo = albedo;
    material.normal = N;
    material.roughness = roughness;
    material.metallic = metallic;
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

