#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/depth.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

// Near/far provided by pipeline; default values for robustness.
uniform float zNear;
uniform float zFar;

void main() {
    float d = texture2D(gDepth, vUV).r;

    // If zNear/zFar are not bound, defaults should keep the pass functional.
    float zn = (zNear > 0.0) ? zNear : 0.05;
    float zf = (zFar > zn + 1e-3) ? zFar : 256.0;

    float linear = linearizeDepth(d, zn, zf);
    // Normalize for storage.
    float outDepth = linear / zf;
    FragColor = vec4(outDepth, outDepth, outDepth, 1.0);
}

