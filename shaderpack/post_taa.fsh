#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

// Current frame color + history
uniform sampler2D gColor;
uniform sampler2D gHistoryPrev;
uniform sampler2D gVelocity;

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.0), vec2(1.0));
}

void main() {
    float enable = step(0.5, taaEnabled);

    vec2 vel = texture2D(gVelocity, vUV).rg;
    // Reproject: subtract velocity (screen-space).
    vec2 prevUV = clampUV(vUV - vel * taaFeedback);

    vec3 cur = texture2D(gColor, vUV).rgb;
    vec3 prev = texture2D(gHistoryPrev, prevUV).rgb;

    // Neighborhood clamp to reduce ghosting.
    // Simple stability: blend weight reduces when motion is high.
    float motion = length(vel);
    float blend = clamp(1.0 / (1.0 + motion * 40.0), 0.05, 0.95);

    vec3 outCol = mix(cur, prev, blend * enable);

    // Optional sharpening.
    float sharp = taaSharpen;
    outCol += sharp * (cur - outCol);

    // Output is still in linear HDR; post_combine / tonemap pass may apply later.
    FragColor = vec4(outCol, 1.0);
}

