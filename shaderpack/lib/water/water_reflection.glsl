#version 150
#ifndef WATER_REFLECTION_GLSL
#define WATER_REFLECTION_GLSL

#include "water_common.glsl"
#include "water_fresnel.glsl"
#include "../atmosphere/atmosphere_lut.glsl"
#include "../atmosphere/atmosphere_sun.glsl"
#include "../atmosphere/atmosphere_moon.glsl"

// Water reflection pipeline
// Integrates SSR, Sky LUT, atmosphere, clouds, sun, moon with fallback hierarchy

struct WaterReflection {
    vec3 ssr;
    vec3 sky;
    vec3 sun;
    vec3 moon;
    vec3 clouds;
    float ssrHit;
    vec3 combined;
    float fresnel;
};

// Compute water reflection with fallback hierarchy
WaterReflection waterComputeReflection(
    vec3 V, vec3 N, vec3 worldPos,
    AtmosphereParameters p, AtmosphereRuntime r,
    vec3 ssrColor, float ssrHit,
    vec3 cloudRadiance,
    float roughness
) {
    WaterReflection ref;
    ref.ssr = ssrColor;
    ref.sky = vec3(0.0);
    ref.sun = vec3(0.0);
    ref.moon = vec3(0.0);
    ref.clouds = cloudRadiance;
    ref.ssrHit = ssrHit;
    ref.combined = vec3(0.0);

    // Reflection direction
    vec3 R = reflect(-V, N);
    float height = max(worldPos.y - 64.0, 0.0);

    // Sky reflection from atmosphere LUT
    ref.sky = atmosphereSkyLUT(p, r, R, height);

    // Sun reflection
    ref.sun = atmosphereSunRadiance(p, r, R, height);

    // Moon reflection
    ref.moon = atmosphereMoonRadiance(p, r, R, height);

    // Fresnel
    float NoV = saturate(dot(N, V));
    ref.fresnel = waterFresnelRough(NoV, roughness);

    // Reflection fallback hierarchy:
    // 1. SSR (if hit)
    // 2. Cloud reflection
    // 3. Sky LUT
    // 4. Sun/moon
    vec3 fallback = ref.sky + ref.sun + ref.moon;
    if (length(cloudRadiance) > 0.01) {
        fallback = mix(fallback, cloudRadiance, 0.5);
    }

    ref.combined = mix(fallback, ref.ssr, ref.ssrHit);
    ref.combined *= ref.fresnel;

    return ref;
}

#endif