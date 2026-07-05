#version 150

#ifndef LIGHTING_PBR_GLSL
#define LIGHTING_PBR_GLSL

float D_GGX(float NoH, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float denom = (NoH * NoH) * (a2 - 1.0) + 1.0;
    return a2 / (3.14159265 * denom * denom + 1e-7);
}

float G_SchlickGGX(float NoV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    float denom = NoV * (1.0 - k) + k;
    return NoV / (denom + 1e-7);
}

float G_Smith(float NoV, float NoL, float roughness) {
    float g1 = G_SchlickGGX(NoV, roughness);
    float g2 = G_SchlickGGX(NoL, roughness);
    return g1 * g2;
}

vec3 F_Schlick(vec3 F0, float VoH) {
    float p = pow(1.0 - VoH, 5.0);
    return F0 + (1.0 - F0) * p;
}

vec3 BRDF_SpecularGGX(vec3 F0, float roughness, vec3 N, vec3 V, vec3 L) {
    vec3 H = normalize(V + L);
    float NoV = saturate(dot(N, V));
    float NoL = saturate(dot(N, L));
    float NoH = saturate(dot(N, H));
    float VoH = saturate(dot(V, H));

    float D = D_GGX(NoH, roughness);
    float G = G_Smith(NoV, NoL, roughness);
    vec3 F = F_Schlick(F0, VoH);

    vec3 numerator = D * G * F;
    float denom = max(4.0 * NoV * NoL, 1e-7);
    return numerator / denom;
}

vec3 BRDF_DiffuseLambert(vec3 albedo) {
    return albedo / 3.14159265;
}

vec3 PBR_Lit(vec3 albedo, float metallic, float roughness, float ao, vec3 N, vec3 V, vec3 L, vec3 lightColor, float lightIntensity) {
    vec3 F0 = mix(vec3(0.04), albedo, metallic);
    vec3 spec = BRDF_SpecularGGX(F0, roughness, N, V, L);
    vec3 diff = BRDF_DiffuseLambert(albedo) * (vec3(1.0) - F0) * (1.0 - metallic);
    float NoL = saturate(dot(N, L));
    vec3 radiance = lightColor * lightIntensity;
    vec3 color = (diff + spec) * radiance * NoL;
    color *= mix(1.0, ao, 0.7);
    return color;
}

#endif
