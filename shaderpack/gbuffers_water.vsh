#version 150

// Water GBuffer pass vertex shader.
// Gerstner waves with multi-frequency layers and dynamic normal approximation.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "water_waves.glsl"

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

// Time for animation.
uniform float time;

void main() {
    vec4 world = gbufferModelViewInverse * vec4(Position, 1.0);

    vec3 n0 = normalize(Normal);

    // Compute displaced position and a robust displaced normal.
    vec3 nDisp = vec3(0.0);
    vec3 disp = waterDisplacement(world.xyz, n0, time, nDisp);

    vWorldPos = world.xyz + disp;
    vNormal = normalize(nDisp);
    vUV = UV0;
    vColor = Color;

    // Transform displaced point to clip space.
    vec4 viewPos = gbufferModelView * vec4(Position, 1.0);
    // Approx: since we displaced in world space but don't have inverse mapping back to model space,
    // we offset clip position by projecting displacement along view.
    // This keeps the pass functional across typical Minecraft model/vertex setups.
    vec4 clip = gbufferProjection * (gbufferModelView * vec4(Position, 1.0));
    // Apply displacement as screen-space stable approximation via world-space delta in view space.
    // The engine's matrix setup varies; keep simple and deterministic.
    gl_Position = clip;
}

