#version 150
#ifndef DEPTH_GLSL
#define DEPTH_GLSL

#include "common/math.glsl"

float linearizeDepth(float depthNonLinear, float zNear, float zFar) {
    float z = depthNonLinear * 2.0 - 1.0;
    return (2.0 * zNear * zFar) / (zFar + zNear - z * (zFar - zNear));
}

float viewDepthFromNDCZ(float ndcZ, float zNear, float zFar) {
    return (2.0 * zNear * zFar) / (zFar + zNear - ndcZ * (zFar - zNear));
}

#endif

