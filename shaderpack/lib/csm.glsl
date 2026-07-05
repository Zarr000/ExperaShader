#version 150
#ifndef CSM_GLSL
#define CSM_GLSL

// Cascaded shadow mapping split helper + stable cascade selection.
// This is an original, compact CSM math helper.

uniform vec3 csmSplitSums; // x: near split, y: mid split, z: far split (proxy)

// Choose cascade index based on view-space depth.
int chooseCascade(float viewDepth) {
    // 0..2 cascades proxy
    if (viewDepth < csmSplitSums.x) return 0;
    if (viewDepth < csmSplitSums.y) return 1;
    return 2;
}

#endif

