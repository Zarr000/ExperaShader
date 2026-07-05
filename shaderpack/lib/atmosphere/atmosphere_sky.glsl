#version 150
#ifndef ATMOSPHERE_SKY_GLSL
#define ATMOSPHERE_SKY_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_ozone.glsl"
#include "atmosphere_transmittance.glsl"
#include "atmosphere_multiscatter.glsl"
#include "atmosphere_lighting.glsl"

vec3 atmosphereSkyColor(AtmosphereParameters p, vec3 viewDir, vec3 sunDir, float height, float quality) {
    float cosTheta = clamp(dot(viewDir, sunDir), -1.0, 1.0);
    vec3 scatter = atmosphereRayleighScatter(p, cosTheta) + atmosphereMieScatter(p, cosTheta);
    vec3 ozone = atmosphereOzoneAbsorption(height, p.ozoneAbsorption, p.ozoneScaleHeight);
    vec3 trans = atmosphereTransmittance(height, vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight), 2.0 + quality);
    vec3 multi = atmosphereMultiScatter(p, cosTheta, quality);
    vec3 sunLight = atmosphereSunLighting(p, cosTheta, height, quality);
    return (scatter + ozone + multi + sunLight) * trans;
}

#endif
