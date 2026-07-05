#version 150

// Volumetric clouds pass - produces cloud shadow factor in RGB and alpha.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/noise.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

uniform float cloudsEnabled;
uniform float cloudsQuality;

uniform vec3 sunDirection;

// Cloud shaping parameters (original)
float cloudField(vec3 p) {
    // Multi-octave noise gives cloud-like structures.
    float f = fbm(p * 0.7);
    f = smoothstep(0.45, 0.75, f);
    return f;
}

void main() {
    float depth = texture2D(gDepth, vUV).r;

    // Screen-space to pseudo world for cloud sampling.
    vec2 uv = vUV * 2.0 - 1.0;
    vec3 p = vec3(uv * 10.0, depth * 40.0);

    // Animate clouds via wind.
    vec3 wind = vec3(0.08, 0.0, 0.05);
    vec3 q = p + wind * time;

    float c = cloudField(q);
    // Soft coverage
    float coverage = pow(c, 1.7);

    // Cloud shadows: darken when coverage high.
    float shadow = saturate(1.0 - coverage * 0.6);

    float enable = step(0.5, cloudsEnabled);
    FragColor = vec4(vec3(shadow), shadow * enable);
}

