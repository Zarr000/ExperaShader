#version 150
#ifndef REPROJECTION_GLSL
#define REPROJECTION_GLSL

// Shared reprojection helpers.

vec2 projectUV(mat4 currViewProj, mat4 prevViewProj, vec3 worldPos) {
    vec4 currClip = currViewProj * vec4(worldPos, 1.0);
    vec4 prevClip = prevViewProj * vec4(worldPos, 1.0);

    vec3 currNDC = currClip.xyz / max(currClip.w, 1e-6);
    vec3 prevNDC = prevClip.xyz / max(prevClip.w, 1e-6);

    vec2 prevUV = prevNDC.xy * 0.5 + 0.5;
    return prevUV;
}

#endif

