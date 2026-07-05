#version 150

#ifndef COMMON_COLOR_GLSL
#define COMMON_COLOR_GLSL

vec3 linearToSRGB(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
}

vec3 SRGBToLinear(vec3 c) {
    return pow(max(c, vec3(0.0)), vec3(2.2));
}

float evaluateLuminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

#endif
