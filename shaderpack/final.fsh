#version 150

// Final pass: final color grading, vignette, and optional debug output.

#include "lib/common.glsl"
#include "lib/common/uniforms.glsl"
#include "lib/post/pipeline.glsl"
#include "lib/debug/visualization.glsl"

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



