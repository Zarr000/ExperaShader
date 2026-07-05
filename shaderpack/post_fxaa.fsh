#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;

vec3 luma(vec3 c) {
    float Y = dot(c, vec3(0.2126, 0.7152, 0.0722));
    return vec3(Y);
}

void main() {
    float enable = step(0.5, taaEnabled); // reuse enable for toggling if no separate uniform
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    vec3 rgbM = texture2D(gColor, vUV).rgb;
    vec3 rgbNW = texture2D(gColor, vUV + vec2(-texel.x, -texel.y)).rgb;
    vec3 rgbNE = texture2D(gColor, vUV + vec2(texel.x, -texel.y)).rgb;
    vec3 rgbSW = texture2D(gColor, vUV + vec2(-texel.x, texel.y)).rgb;
    vec3 rgbSE = texture2D(gColor, vUV + vec2(texel.x, texel.y)).rgb;

    vec3 lumaM = luma(rgbM);
    vec3 lumaNW = luma(rgbNW);
    vec3 lumaNE = luma(rgbNE);
    vec3 lumaSW = luma(rgbSW);
    vec3 lumaSE = luma(rgbSE);

    float lumaMin = min(lumaM.r, min(min(lumaNW.r, lumaNE.r), min(lumaSW.r, lumaSE.r)));
    float lumaMax = max(lumaM.r, max(max(lumaNW.r, lumaNE.r), max(lumaSW.r, lumaSE.r)));

    // Edge direction.
    float dirX = -((lumaNW.r + lumaNE.r) - (lumaSW.r + lumaSE.r));
    float dirY =  ((lumaNW.r + lumaSW.r) - (lumaNE.r + lumaSE.r));

    float dirReduce = max((lumaNW.r + lumaNE.r + lumaSW.r + lumaSE.r) * 0.25 * 0.03125, 1e-6);
    float rcpDirMin = 1.0 / (min(abs(dirX), abs(dirY)) + dirReduce);
    vec2 dir = clamp(vec2(dirX, dirY) * rcpDirMin, vec2(-8.0), vec2(8.0)) * texel;

    // Sample along edge.
    vec3 rgbA = 0.5 * (texture2D(gColor, vUV + dir * (1.0 / 3.0 - 0.5)).rgb + texture2D(gColor, vUV + dir * (2.0 / 3.0 - 0.5)).rgb);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (texture2D(gColor, vUV + dir * -0.5).rgb + texture2D(gColor, vUV + dir * 0.5).rgb);

    float lumaB = dot(rgbB, vec3(0.2126, 0.7152, 0.0722));
    vec3 outCol = (lumaB < lumaMin || lumaB > lumaMax) ? rgbA : rgbB;

    // If enable is 0, bypass.
    outCol = mix(rgbM, outCol, enable);
    FragColor = vec4(outCol, 1.0);
}

