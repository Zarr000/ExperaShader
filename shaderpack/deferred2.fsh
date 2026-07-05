#version 150

// Atmospheric scattering approximation pass (Rayleigh + Mie) - outputs fog color in RGB.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

uniform vec3 sunDirection;
uniform vec3 skyColor;
uniform vec3 moonColor;
uniform float time;

// Fog
uniform float volumetricFogEnabled;
uniform float volumetricFogQuality;

vec3 rayleigh(vec3 betaR, float cosTheta) {
    return betaR * (1.0 + cosTheta * cosTheta);
}

float phaseMie(float g, float cosTheta) {
    float denom = 1.0 + g * g - 2.0 * g * cosTheta;
    return (1.0 - g * g) / (4.0 * 3.14159265 * denom * sqrt(denom));
}

void main() {
    float depth = texture2D(gDepth, vUV).r;

    // Convert depth to approximate view distance.
    // Without exact linearization, use depth as proxy.
    float dist = depth * 120.0;

    vec3 dirToSun = normalize(-sunDirection);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    float cosTheta = clamp(dot(viewDir, dirToSun), -1.0, 1.0);

    // Beta coefficients (approx). Tuned for natural look.
    vec3 betaR = vec3(5.8e-6, 13.5e-6, 33.1e-6);
    vec3 betaM = vec3(2.1e-5);

    vec3 scatterR = rayleigh(betaR, cosTheta);
    float g = 0.76;
    float phaseM = phaseMie(g, cosTheta);
    vec3 scatterM = betaM * phaseM;

    // Extinction: exponential falloff.
    float extinction = exp(-dist * (1.0 / 85.0));
    vec3 fogCol = (scatterR + scatterM) * (1.0 - extinction);

    // Mix toward sky color for artistic control.
    fogCol = mix(fogCol, skyColor, 0.35);

    float enable = step(0.5, volumetricFogEnabled);
    FragColor = vec4(fogCol * enable, enable);
}

