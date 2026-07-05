#version 150

// Final pass: final color grading, vignette, and optional debug output.
// Integrated with Atmosphere Engine V2 debug visualization.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/post/pipeline.glsl"
#include "lib/debug/visualization.glsl"
#include "lib/atmosphere/atmosphere_common.glsl"
#include "lib/atmosphere/atmosphere_debug.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gSSGI;
uniform sampler2D gSSR;
uniform sampler2D gHiZ;
uniform sampler2D gNormalRough;
uniform sampler2D gEmissiveAO;
uniform sampler2D gWorldPosDepth;
uniform sampler2D gVelocity;

uniform float saturation;
uniform float contrast;
uniform float debugMode;

void main() {
    vec3 c = texture2D(gColor, vUV).rgb;
    vec3 gi = texture2D(gSSGI, vUV).rgb;
    float giValid = texture2D(gSSGI, vUV).a;
    c += gi * giValid;

    vec4 nr = texture2D(gNormalRough, vUV);
    vec4 ea = texture2D(gEmissiveAO, vUV);
    vec4 wp = texture2D(gWorldPosDepth, vUV);
    vec4 vel = texture2D(gVelocity, vUV);
    vec4 ssr = texture2D(gSSR, vUV);
    vec3 hiz = texture2D(gHiZ, vUV).rgb;

    // Atmosphere debug visualization (modes 11-23)
    if (debugMode > 10.5 && debugMode < 24.0) {
        // Compute atmosphere runtime for debug
        AtmosphereParameters p;
        p.planetCenter = vec3(0.0, -ATMOSPHERE_PLANET_RADIUS, 0.0);
        p.planetRadius = ATMOSPHERE_PLANET_RADIUS;
        p.atmosphereRadius = ATMOSPHERE_ATMOSPHERE_RADIUS;
        p.rayleighScattering = vec3(5.8e-6, 1.35e-5, 3.31e-5);
        p.mieScattering = vec3(3.0e-6);
        p.mieExtinction = vec3(4.0e-6);
        p.ozoneAbsorption = vec3(0.65e-6, 1.0e-6, 0.1e-6);
        p.rayleighScaleHeight = ATMOSPHERE_RAYLEIGH_SCALE;
        p.mieScaleHeight = ATMOSPHERE_MIE_SCALE;
        p.ozoneScaleHeight = ATMOSPHERE_OZONE_SCALE;
        p.mieG = 0.76;
        p.sunIntensity = 1.0;
        p.moonIntensity = 1.0;
        p.weatherIntensity = rainStrength;
        p.fogDensity = fogDensity;

        AtmosphereRuntime r = atmosphereComputeRuntime();

        // Reconstruct view direction from depth
        float depth = wp.a;
        vec3 viewPos = reconstructViewPosition(depth, vUV, gbufferProjection, screenSize);
        vec3 viewDir = normalize(viewPos);

        // Transform view direction to world space
        vec3 worldViewDir = normalize(mat3(gbufferModelViewInverse) * viewDir);

        float height = r.cameraAltitude;

        // Map debug mode to atmosphere debug modes (offset by 11)
        float atmoMode = debugMode - 11.0;
        c = atmosphereDebugColor(atmoMode, p, r, worldViewDir, height);
    } else {
        // Standard debug modes (0-10)
        vec3 debug = debugColorFromMode(
            c,
            nr.rgb * 2.0 - 1.0,
            nr.a,
            0.0,
            ea.a,
            ea.r,
            vel.rgb,
            wp.a,
            gi,
            ssr.rgb,
            hiz,
            int(debugMode)
        );

        if (debugMode > 0.5) {
            c = debug;
        }
    }

    c = (c - 0.5) * contrast + 0.5;

    float l = evaluateLuminance(c);
    c = mix(vec3(l), c, saturation);

    vec2 p = vUV * 2.0 - 1.0;
    float r2 = dot(p, p);
    float vig = exp(-r2 * vignetteIntensity);
    c *= vig;

    c = clamp(c, vec3(0.0), vec3(1.0));
    FragColor = vec4(c, 1.0);
}