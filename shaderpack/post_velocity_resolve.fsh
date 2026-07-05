#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

// Input: velocity history or velocity buffer.
uniform sampler2D gVelocity;

void main() {
    // Pass through velocity for now.
    vec2 vel = texture2D(gVelocity, vUV).rg;
    FragColor = vec4(vel, 0.0, 1.0);
}

