#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gVelocity;
uniform sampler2D gPrevVelocity;
uniform float taaFeedback;

void main() {
    vec4 v = texture2D(gVelocity, vUV);
    vec4 p = texture2D(gPrevVelocity, vUV);

    // Simple temporal stabilization of velocity.
    vec4 outV = mix(v, p, taaFeedback);
    FragColor = outV;
}

