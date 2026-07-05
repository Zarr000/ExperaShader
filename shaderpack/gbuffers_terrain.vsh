#version 150

// Terrain GBuffer pass vertex shader.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec3 Position;
in vec3 Normal;
in vec2 UV0;
in vec4 Color;

// Optional tangent space inputs depending on pack.
in vec3 Tangent;
in vec3 Bitangent;

out vec3 vWorldPos;
out vec3 vNormal;
out vec2 vUV;
out vec4 vColor;
out vec3 vTangent;
out vec3 vBitangent;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;

void main() {
    vec4 world = gbufferModelViewInverse * vec4(Position, 1.0);
    vWorldPos = world.xyz;

    // Model-space normal transform (approx via normalMatrix)
    mat3 N = mat3(transpose(inverse(gbufferModelView)));
    vNormal = normalize(N * Normal);

    vUV = UV0;
    vColor = Color;

    vTangent = Tangent;
    vBitangent = Bitangent;

    vec4 clip = gbufferProjection * gbufferModelView * vec4(Position, 1.0);
    gl_Position = clip;
}

