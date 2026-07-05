#version 150

// Atmospheric scattering approximation pass (Rayleigh + Mie) with a stable fog fallback.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/material/material_data.glsl"
#include "lib/material/material_decode.glsl"
#include "lib/atmosphere/atmosphere_common.glsl"
#include "lib/atmosphere/atmosphere_sky.glsl"
#include "lib/atmosphere/atmosphere_sun.glsl"
#include "lib/atmosphere/atmosphere_moon.glsl"
#include "lib/atmosphere/atmosphere_stars.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

uniform vec3 sunDirection;
uniform vec3 skyColor;
uniform vec3 moonColor;
uniform float time;

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
    float dist = depth * 120.0;

    vec3 dirToSun = normalize(-sunDirection);
    vec3 dirToMoon = normalize(-moonColor);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    float cosThetaSun = clamp(dot(viewDir, dirToSun), -1.0, 1.0);
    float cosThetaMoon = clamp(dot(viewDir, dirToMoon), -1.0, 1.0);

    AtmosphereParameters atmosphere;
    atmosphere.planetCenter = vec3(0.0);
    atmosphere.planetRadius = 6360.0;
    atmosphere.atmosphereRadius = 6460.0;
    atmosphere.rayleighScattering = vec3(5.8e-6, 13.5e-6, 33.1e-6);
    atmosphere.mieScattering = vec3(2.1e-5);
    atmosphere.mieExtinction = vec3(2.1e-5);
    atmosphere.ozoneAbsorption = vec3(0.0000015, 0.0000020, 0.0000025);
    atmosphere.rayleighScaleHeight = 8.0;
    atmosphere.mieScaleHeight = 1.2;
    atmosphere.ozoneScaleHeight = 0.8;
    atmosphere.mieG = 0.76;
    atmosphere.sunIntensity = 1.0;
    atmosphere.moonIntensity = 0.25;

    vec3 skyCol = atmosphereSkyColor(atmosphere, normalize(vec3(0.0, 1.0, 0.0)), normalize(-sunDirection), dist * 0.01, volumetricFogQuality);
    vec3 sunCol = atmosphereSunRadiance(normalize(-sunDirection), normalize(vec3(0.0, 0.0, 1.0)), cosThetaSun, 0.002);
    vec3 moonCol = atmosphereMoonRadiance(normalize(-moonColor), normalize(vec3(0.0, 0.0, 1.0)), cosThetaMoon, 0.35);
    vec3 starsCol = atmosphereStars(cosThetaMoon, 0.25);

    float extinction = exp(-dist * (1.0 / 85.0));
    vec3 fogCol = mix(skyCol + sunCol + moonCol + starsCol, skyColor, 0.35) * (1.0 - extinction);

    float enable = step(0.5, volumetricFogEnabled);
    FragColor = vec4(fogCol * enable, enable);
}

