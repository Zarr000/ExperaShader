#version 150

// Screen Space Reflections pass.
// Outputs reflection color in RGB and hit factor in A.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/ssr.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gNormalRough;
uniform sampler2D gDepth;

uniform sampler2D gPrevSSR;

uniform sampler2D gWorldPosDepth;

uniform float ssrEnabled;
uniform float ssrQuality;

uniform float time;

vec3 unpackNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

vec3 reflectView(vec3 N, vec3 V) {
    return normalize(reflect(-V, N));
}

void main() {
    vec4 nr = texture2D(gNormalRough, vUV);
    vec3 N = unpackNormal(nr.rgb);
    float roughness = clamp(nr.a, 0.02, 1.0);

    // View vector approximation.
    vec3 worldPos = texture2D(gWorldPosDepth, vUV).xyz;
    vec3 V = normalize(vec3(0.0) - worldPos + cameraPosition);

    vec3 rd = reflectView(N, V);

    float enable = step(0.5, ssrEnabled);

    int steps = int(mix(20.0, 64.0, ssrQuality));
    int refine = 6;

    // Use the SSR marcher in a proxy screen-space UV domain.
    // ro/rd treated as directional proxies.
// Use hierarchical depth tex if bound; else fall back to gDepth.
// Current implementation reads depthTex and assumes it matches depth compare space.
vec3 march = ssrRayMarch(vec3(0.0), rd, roughness, gDepth, steps, refine);

    vec2 hitUV = march.xy;
    float hit = march.z;


    vec3 scene = texture2D(gColor, hitUV).rgb;

    // Roughness-aware energy conservation.
    float rFac = mix(0.9, 0.2, roughness);
    vec3 refl = scene * rFac;

    // Temporal reprojection approximation: blend with previous SSR.
    vec3 prev = texture2D(gPrevSSR, vUV).rgb;
    float temporal = taaFeedback;

    vec3 outCol = mix(refl, prev, clamp((hit * (1.0 - temporal)) + (1.0 - hit) * temporal, 0.0, 1.0));


    FragColor = vec4(outCol * enable, hit * enable);
}

