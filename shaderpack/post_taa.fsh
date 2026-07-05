#version 150

// Minimal yet stable TAA implementation.
// Uses previous color and a simple neighborhood clamp.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/space_transforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gPrevColor;
uniform sampler2D gDepth;
uniform sampler2D gMotion;

uniform float taaEnabled;
uniform float taaFeedback;
uniform float taaSharpen;

vec3 neighborhoodMin(vec2 uv, vec2 texel) {
    vec3 m = texture2D(gColor, uv + vec2(-texel.x, -texel.y)).rgb;
    m = min(m, texture2D(gColor, uv + vec2( texel.x, -texel.y)).rgb);
    m = min(m, texture2D(gColor, uv + vec2(-texel.x,  texel.y)).rgb);
    m = min(m, texture2D(gColor, uv + vec2( texel.x,  texel.y)).rgb);
    m = min(m, texture2D(gColor, uv).rgb);
    return m;
}

vec3 neighborhoodMax(vec2 uv, vec2 texel) {
    vec3 m = texture2D(gColor, uv + vec2(-texel.x, -texel.y)).rgb;
    m = max(m, texture2D(gColor, uv + vec2( texel.x, -texel.y)).rgb);
    m = max(m, texture2D(gColor, uv + vec2(-texel.x,  texel.y)).rgb);
    m = max(m, texture2D(gColor, uv + vec2( texel.x,  texel.y)).rgb);
    m = max(m, texture2D(gColor, uv).rgb);
    return m;
}

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    vec3 curr = texture2D(gColor, vUV).rgb;

    vec2 motion = texture2D(gMotion, vUV).xy;
    // motion expected in pixels normalized to [0..1] scale; adapt conservatively.
    vec2 prevUV = vUV - motion;

    vec3 prev = texture2D(gPrevColor, prevUV).rgb;

    // Depth-based rejection to avoid ghosting.
    float dCurr = texture2D(gDepth, vUV).r;
    float dPrev = texture2D(gDepth, prevUV).r;
    float depthDiff = abs(dCurr - dPrev);

    vec3 mn = neighborhoodMin(vUV, texel);
    vec3 mx = neighborhoodMax(vUV, texel);
    vec3 prevClamped = clamp(prev, mn, mx);

    float enable = step(0.5, taaEnabled);
    float depthOk = 1.0 - step(0.02, depthDiff);

    float feedback = taaFeedback * enable * depthOk;
    vec3 blended = mix(curr, prevClamped, feedback);

    // Sharpen: contrast adaptive.
    vec3 lap = blended - (texture2D(gColor, vUV + vec2(texel.x, 0.0)).rgb + texture2D(gColor, vUV - vec2(texel.x, 0.0)).rgb
                         + texture2D(gColor, vUV + vec2(0.0, texel.y)).rgb + texture2D(gColor, vUV - vec2(0.0, texel.y)).rgb) * 0.25;

    blended += lap * taaSharpen * enable;

    FragColor = vec4(blended, 1.0);
}

