#version 150
#ifndef ATMOSPHERE_LIGHTING_GLSL
#define ATMOSPHERE_LIGHTING_GLSL

#include "atmosphere_common.glsl"
#include "atmosphere_rayleigh.glsl"
#include "atmosphere_mie.glsl"
#include "atmosphere_transmittance.glsl"

vec3 atmosphereSunLighting(AtmosphereParameters p, float cosTheta, float height, float quality) {
    vec3 rayleigh = atmosphereRayleighScatter(p, cosTheta) * p.sunIntensity;
    vec3 mie = atmosphereMieScatter(p, cosTheta) * p.sunIntensity;
    vec3 trans = atmosphereTransmittance(height, vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight), 2.0 + quality);
    return (rayleigh + mie) * trans;
}

vec3 atmosphereMoonLighting(AtmosphereParameters p, float cosTheta, float height, float quality) {
    vec3 rayleigh = atmosphereRayleighScatter(p, cosTheta) * p.moonIntensity * 0.15;
    vec3 mie = atmosphereMieScatter(p, cosTheta) * p.moonIntensity * 0.08;
    vec3 trans = atmosphereTransmittance(height, vec3(p.rayleighScaleHeight, p.mieScaleHeight, p.ozoneScaleHeight), 1.5 + quality * 0.5);
    return (rayleigh + mie) * trans;
}

#endif
