#version 150

// Atmospheric scattering pass with runtime-driven sun, moon, altitude, and weather response.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/material/material_data.glsl"
#include "lib/material/material_decode.glsl"
#include "lib/atmosphere/atmosphere_common.glsl"
#include "lib/atmosphere/atmosphere_sky.glsl"
#include "lib/atmosphere/atmosphere_sun.glsl"
#include "lib/atmosphere/atmosphere_moon.glsl"
#include "lib/atmosphere/atmosphere_stars.glsl"
#include "lib/atmosphere/atmosphere_lut.glsl"
#include "lib/atmosphere/atmosphere_debug.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

uniform vec3 sunDirection;
uniform vec3 moonDirection;
uniform vec3 skyColor;
uniform float rainStrength;
uniform float debugMode;

void main() {
    float depth = texture2D(gDepth, vUV).r;
    float dist = depth * 120.0;

    vec3 viewDir = normalize(vec3(0.0, 1.0, 0.0));
    vec3 dirToSun = normalize(-sunDirection);
    vec3 dirToMoon = normalize(-moonDirection);
    float sunElevation = atmosphereSunElevation(dirToSun);
    float moonElevation = atmosphereMoonElevation(dirToMoon);
    float weather = saturate(rainStrength * 0.65 + volumetricFogQuality * 0.04);
    float altitude = max(cameraPosition.y, 0.0);
    float quality = clamp(volumetricFogQuality, 0.0, 4.0);

    AtmosphereParameters atmosphere;
    atmosphere.planetCenter = vec3(0.0);
    atmosphere.planetRadius = 6360.0;
    atmosphere.atmosphereRadius = 6460.0;
    atmosphere.rayleighScattering = vec3(5.8e-6, 13.5e-6, 33.1e-6) * (1.0 + 0.15 * weather);
    atmosphere.mieScattering = vec3(2.1e-5) * (0.7 + 0.3 * (1.0 - weather));
    atmosphere.mieExtinction = atmosphere.mieScattering;
    atmosphere.ozoneAbsorption = vec3(0.0000015, 0.0000020, 0.0000025);
    atmosphere.rayleighScaleHeight = 8.0;
    atmosphere.mieScaleHeight = 1.2;
    atmosphere.ozoneScaleHeight = 0.8;
    atmosphere.mieG = 0.76;
    atmosphere.sunIntensity = 1.0 + 0.35 * saturate(sunElevation + 0.1);
    atmosphere.moonIntensity = 0.16 + 0.1 * saturate(0.35 - moonElevation);
    atmosphere.weatherIntensity = weather;
    atmosphere.fogDensity = 0.008 + 0.005 * weather + 0.002 * atmosphereLocalDensityFactor(altitude, 64.0, 63.0, max(cameraPosition.y - 96.0, 0.0));

    vec3 skyCol = atmosphereSkyColor(atmosphere, viewDir, dirToSun, dirToMoon, altitude, quality, weather);
    vec3 sunCol = atmosphereSunRadiance(atmosphere, dirToSun, viewDir, altitude, quality);
    vec3 moonCol = atmosphereMoonRadiance(atmosphere, dirToMoon, dirToSun, viewDir, altitude, quality);
    vec3 starsCol = atmosphereStars(sunElevation, moonElevation, quality);

    float fogDensity = atmosphere.fogDensity * (0.75 + 0.25 * dist * 0.01);
    float extinction = exp(-dist * fogDensity);
    vec3 fogCol = mix(skyCol + sunCol + moonCol + starsCol, skyColor, 0.25 + 0.15 * weather) * (1.0 - extinction);

    float enable = step(0.5, volumetricFogEnabled);
    vec3 debugCol = atmosphereDebugColor(clamp(debugMode, 0.0, 6.0), fogCol);
    FragColor = vec4(mix(fogCol, debugCol, step(0.5, debugMode)) * enable, enable);
}

