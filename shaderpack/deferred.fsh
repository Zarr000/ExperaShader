#version 150

// Deferred lighting pass: combines GBuffer with physically-based direct lighting.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/brdf_pbr.glsl"
#include "lib/tonemap.glsl"
#include "lib/space_transforms.glsl"
#include "lib/screen_space.glsl"

in vec2 vUV;
out vec4 FragColor;

// GBuffer samplers (OptiFine/Iris naming varies; these are common).
uniform sampler2D gAlbedoMetal;
uniform sampler2D gNormalRough;
uniform sampler2D gEmissiveAO;
uniform sampler2D gWorldPosDepth;
uniform sampler2D gDepth;

// Lighting: sun/moon
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

vec3 unpackNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

float computeDayFactor(vec3 dir) {
    // dir.y ~ 1 => day. Smooth for sunrise/sunset.
    float y = saturate(dir.y);
    return y;
}

void main() {
    // Read GBuffer
    vec4 albm = texture2D(gAlbedoMetal, vUV);
    vec4 nr = texture2D(gNormalRough, vUV);
    vec4 ea = texture2D(gEmissiveAO, vUV);
    vec4 wp = texture2D(gWorldPosDepth, vUV);

    vec3 albedo = albm.rgb;
    float metallic = albm.a;

    vec3 N = unpackNormal(nr.rgb);
    float roughness = clamp(nr.a, 0.02, 1.0);

    float ao = clamp(ea.a, 0.0, 1.0);
    float emissive = ea.r;

    // World position reconstruction
    vec3 worldPos = wp.xyz;
    vec3 V = normalize(cameraPosition - worldPos);

    // Determine sun/moon blend based on sun direction.
    float day = computeDayFactor(sunDirection);
    float night = 1.0 - day;

    vec3 Lsun = normalize(-sunDirection);
    vec3 Lmoon = normalize(-moonDirection);

    float NoLsun = saturate(dot(N, Lsun));
    float NoLmoon = saturate(dot(N, Lmoon));

    // Direct lighting using PBR helper.
    vec3 colSun = PBR_Lit(albedo, metallic, roughness, ao, N, V, Lsun, sunColor, sunIntensity);
    vec3 colMoon = PBR_Lit(albedo, metallic, roughness, ao, N, V, Lmoon, moonColor, moonIntensity);

    vec3 direct = mix(colMoon * (0.25 + 0.75 * day), colSun, day);

    // Ambient / skylight approximation.
    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    vec3 diffuse = BRDF_DiffuseLambert(albedo);

    // Hemisphere ambient: sky for N.y>0, ground for below.
    vec3 hemi = mix(vec3(0.02, 0.02, 0.03), skyColor, saturate(N.y * 0.5 + 0.5));

    vec3 ambient = diffuse * hemi * ambientIntensity;
    // Specular ambient term (cheap): treat as image-based lighting strength.
    float NoV = saturate(dot(N, V));
    vec3 specAmbient = F0 * (0.04 + 0.96 * pow(1.0 - NoV, 5.0));
    ambient += specAmbient * 0.1 * ambientIntensity;

    vec3 emiss = albedo * emissive;

    vec3 radiance = direct + ambient + emiss;

    FragColor = vec4(radiance, 1.0);
}

