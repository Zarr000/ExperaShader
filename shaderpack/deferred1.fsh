#version 150

// SSAO pass (screen-space ambient occlusion) - writes occlusion in alpha.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

// AO controls
uniform float ssaoEnabled;
uniform float ssaoRadius;
uniform float ssaoBias;

uniform mat4 gbufferProjection;

vec3 reconstructView(vec2 uv, float depth) {
    // depth assumed non-linear. Conservative reconstruction using inverse projection.
    vec2 ndc = uv * 2.0 - 1.0;
    vec4 clip = vec4(ndc, depth * 2.0 - 1.0, 1.0);
    vec4 view = inverse(gbufferProjection) * clip;
    return view.xyz / max(view.w, 1e-6);
}

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    float depth0 = texture2D(gDepth, vUV).r;
    vec3 v0 = reconstructView(vUV, depth0);

    float occlusion = 0.0;

    // 8-sample spiral pattern (stable low noise).
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float angle = fi * 2.39996323;
        vec2 dir = vec2(cos(angle), sin(angle));
        float rad = ssaoRadius * (0.15 + 0.85 * fi / 7.0);
        vec2 uv1 = vUV + dir * rad * texel;
        float depth1 = texture2D(gDepth, uv1).r;
        vec3 v1 = reconstructView(uv1, depth1);

        float delta = (v0.z - v1.z);
        float rangeCheck = smoothstep(0.0, 1.0, ssaoRadius / (abs(delta) + 1e-4));
        occlusion += (delta > ssaoBias ? 1.0 : 0.0) * rangeCheck;
    }

    occlusion = 1.0 - occlusion / 8.0;
    occlusion = mix(1.0, occlusion, step(0.5, ssaoEnabled));

    FragColor = vec4(vec3(occlusion), occlusion);
}

