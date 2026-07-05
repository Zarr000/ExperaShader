#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/space_transforms.glsl"
#include "lib/motion_vectors.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gWorldPosDepth;
uniform sampler2D gPrevWorldPosDepth;

// If the pipeline does not provide prev-worldpos, bind gPrevViewProjection and reprojection will be partial.

void main() {
    vec3 worldPos = texture2D(gWorldPosDepth, vUV).xyz;

    // Project to clip for current frame.
    vec4 currClip = currentViewProjection * vec4(worldPos, 1.0);
    vec4 prevClip = previousViewProjection * vec4(worldPos, 1.0);

    vec2 vel = velocityFromClip(currClip, prevClip);

    // Store motion in RG, and an approximate magnitude in B.
    float mag = length(vel);
    FragColor = vec4(vel, mag, 1.0);
}

