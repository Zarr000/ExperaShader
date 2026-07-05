#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

// Generic history resolve for temporal pipelines.
// Binds current and previous history buffers and blends with feedback.

uniform sampler2D gCurrent;
uniform sampler2D gHistoryPrev;

uniform float taaFeedback;

void main() {
    vec3 cur = texture2D(gCurrent, vUV).rgb;
    vec3 prev = texture2D(gHistoryPrev, vUV).rgb;

    // Temporal blend weight driven by taaFeedback.
    vec3 outC = mix(cur, prev, taaFeedback);
    FragColor = vec4(outC, 1.0);
}

