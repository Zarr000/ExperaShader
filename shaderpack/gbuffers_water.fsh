#version 150

// Water GBuffer fragment shader.
// Outputs PBR-ish parameters and emissive/ao placeholders.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

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

uniform float waterMetallic;
uniform float waterRoughness;

// Water absorption and Fresnel parameters.
uniform float time;

vec3 waterAlbedo() {
    // Base from texture with underwater tint.
    vec3 base = texture2D(texture, vUV).rgb;
    vec3 tint = vec3(0.04, 0.20, 0.30);
    // Shift slightly with vertex color
    return mix(tint, base, 0.25);
}

float getAO() {
    vec2 lm = texture2D(lightmap, vec2(0.5)).rg;
    return saturate(lm.y);
}

vec3 packNormal(vec3 n) {
    n = normalize(n);
    return n * 0.5 + 0.5;
}

void main() {
    vec3 N = normalize(vNormal);

    vec3 albedo = waterAlbedo();
    float metallic = waterMetallic;

    // Roughness varies slightly with wave angle.
    float ndv = saturate(dot(N, vec3(0.0, 1.0, 0.0)));
    float rough = waterRoughness + (1.0 - ndv) * 0.08;

    float ao = getAO();

    // Emissive used for caustic hint (kept minimal here).
    float emissive = 0.0;

    gWorldPosDepth = vec4(vWorldPos, 1.0);
    gAlbedoMetal = vec4(albedo, metallic);
    gNormalRough = vec4(packNormal(N), rough);
    gEmissiveAO = vec4(vec3(emissive), ao);
}

