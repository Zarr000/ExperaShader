#version 150

// Material ID pass vertex shader.

in vec3 Position;
in vec3 Normal;
in vec2 UV0;
in vec4 Color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;

out vec2 vUV;
out vec3 vNormal;
out vec4 vColor;

void main() {
    vUV = UV0;
    vNormal = Normal;
    vColor = Color;
    gl_Position = gbufferProjection * gbufferModelView * vec4(Position, 1.0);
}

