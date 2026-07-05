#version 150

// Water GBuffer pass vertex shader.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec3 Position;
in vec3 Normal;
in vec2 UV0;
in vec4 Color;

out vec3 vWorldPos;
out vec3 vNormal;
out vec2 vUV;
out vec4 vColor;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;

// Water wave parameters (driven procedurally).
uniform float time;

vec3 waveDisplacement(vec3 worldPos, vec3 n) {
    // Original, deterministic displacement with low frequency + micro ripples.
    float t = time;
    vec2 xz = worldPos.xz;

    float w1 = sin(xz.x * 0.08 + t * 0.35) * 0.04;
    float w2 = cos(xz.y * 0.06 + t * 0.28) * 0.035;
    float w3 = sin((xz.x + xz.y) * 0.05 + t * 0.22) * 0.03;

    // Micro ripples from pseudo-noise
    float micro = fbm(vec3(xz * 0.35, t * 0.15));
    micro = micro * 0.015;

    // Displace along normal and slight up direction for believable surface.
    vec3 up = normalize(vec3(0.0, 1.0, 0.0));
    return (n * (w1 + w2 + w3) + up * micro);
}

void main() {
    vec4 world = gbufferModelViewInverse * vec4(Position, 1.0);
    vec3 n = normalize(Normal);

    vec3 disp = waveDisplacement(world.xyz, n);
    vec3 displacedWorld = world.xyz + disp;

    vWorldPos = displacedWorld;
    vNormal = normalize(n + disp * 0.25);
    vUV = UV0;
    vColor = Color;

    vec4 clip = gbufferProjection * gbufferModelView * vec4(Position + (disp), 1.0);
    // Note: we keep clip using original Position approximated with displacement.
    // For improved fidelity, we'd transform displaced world back to model space.
    gl_Position = clip;
}

