#version 150
#ifndef CLOUD_UTIL_GLSL
#define CLOUD_UTIL_GLSL

#include "cloud_common.glsl"
#include "../space_transforms.glsl"

// Cloud utility functions
// Shared helpers for cloud rendering pipeline

// Compute ray-cloud intersection distances
vec2 cloudRayIntersection(vec3 rayOrigin, vec3 rayDir, float cloudBase, float cloudTop) {
    vec2 intersection = vec2(-1.0, -1.0);

    if (abs(rayDir.y) < 0.001) {
        // Ray is horizontal - check if within cloud layer
        if (rayOrigin.y >= cloudBase && rayOrigin.y <= cloudTop) {
            intersection = vec2(0.0, 1e6);
        }
        return intersection;
    }

    float tBase = (cloudBase - rayOrigin.y) / rayDir.y;
    float tTop = (cloudTop - rayOrigin.y) / rayDir.y;

    intersection.x = min(tBase, tTop);
    intersection.y = max(tBase, tTop);

    return intersection;
}

// Compute cloud sample position from ray
vec3 cloudSamplePosition(vec3 rayOrigin, vec3 rayDir, float t) {
    return rayOrigin + rayDir * t;
}

// Cloud depth for compositing
float cloudCompositingDepth(float cloudDepth, float sceneDepth, float transmittance) {
    // Blend cloud depth with scene depth based on transmittance
    return mix(cloudDepth, sceneDepth, transmittance);
}

// Cloud alpha for compositing
float cloudCompositingAlpha(float transmittance) {
    return 1.0 - transmittance;
}

// Cloud overlay on scene color
vec3 cloudComposite(vec3 sceneColor, vec3 cloudRadiance, float cloudAlpha) {
    return sceneColor * (1.0 - cloudAlpha) + cloudRadiance;
}

// Distance-based cloud fade (far distance)
float cloudDistanceFade(float distance, float fadeStart, float fadeEnd) {
    return 1.0 - smoothstep(fadeStart, fadeEnd, distance);
}

// Altitude-based cloud fade (near cloud layer edges)
float cloudAltitudeFade(float height, float base, float top, float fadeDist) {
    float bottomFade = smoothstep(base - fadeDist, base + fadeDist, height);
    float topFade = 1.0 - smoothstep(top - fadeDist, top + fadeDist, height);
    return bottomFade * topFade;
}

#endif