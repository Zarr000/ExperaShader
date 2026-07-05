#version 150

#ifndef ATMOSPHERE_SCATTERING_GLSL
#define ATMOSPHERE_SCATTERING_GLSL

vec3 rayleigh(vec3 betaR, float cosTheta) {
    return betaR * (1.0 + cosTheta * cosTheta);
}

float phaseMie(float g, float cosTheta) {
    float denom = 1.0 + g * g - 2.0 * g * cosTheta;
    return (1.0 - g * g) / (4.0 * 3.14159265 * denom * sqrt(denom));
}

#endif
