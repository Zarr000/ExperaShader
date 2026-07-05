#version 150
#ifndef CLOUD_NOISE_GLSL
#define CLOUD_NOISE_GLSL

#include "../common/math.glsl"
#include "../common/noise.glsl"

// Production-quality cloud noise functions
// Supports 3D FBM, Worley, Perlin, curl noise, and multi-octave erosion

// 3D value noise
float cloudNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash12(i.xy + i.z);
    float b = hash12(i.xy + vec2(0.0, 0.0) + i.z + 1.0);
    float c = hash12(i.xy + vec2(1.0, 0.0) + i.z);
    float d = hash12(i.xy + vec2(0.0, 1.0) + i.z);
    float e = hash12(i.xy + vec2(1.0, 1.0) + i.z);

    float mix1 = mix(mix(a, c, f.x), mix(b, d, f.x), f.y);
    float mix2 = mix(mix(a + 0.5, c + 0.5, f.x), mix(b + 0.5, d + 0.5, f.x), f.y);
    return mix(mix1, mix2, f.z);
}

// 3D FBM (Fractal Brownian Motion)
float cloudFBM(vec3 p, float octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxValue = 0.0;

    for (float i = 0.0; i < octaves; i += 1.0) {
        value += amplitude * cloudNoise3D(p * frequency);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value / maxValue;
}

// Worley noise (cellular) for cloud detail
float cloudWorley(vec3 p, float scale) {
    vec3 pScaled = p * scale;
    vec3 i = floor(pScaled);
    vec3 f = fract(pScaled);

    float minDist = 1.0;
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            for (float z = -1.0; z <= 1.0; z += 1.0) {
                vec3 neighbor = vec3(x, y, z);
                vec3 point = vec3(
                    hash12(i.xy + neighbor.xy + i.z + neighbor.z),
                    hash12(i.xy + neighbor.xy + i.z + neighbor.z + 31.0),
                    hash12(i.xy + neighbor.xy + i.z + neighbor.z + 67.0)
                );
                vec3 diff = neighbor + point - f;
                float dist = dot(diff, diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return saturate(1.0 - sqrt(minDist));
}

// Perlin-style noise for cloud coverage
float cloudPerlin(vec3 p, float scale) {
    vec3 pScaled = p * scale;
    vec3 i = floor(pScaled);
    vec3 f = fract(pScaled);
    f = f * f * (3.0 - 2.0 * f);

    float n = dot(i, vec3(1.0, 57.0, 113.0));
    float a = hash12(vec2(n, n + 1.0));
    float b = hash12(vec2(n + 1.0, n));
    float c = hash12(vec2(n, n + 2.0));
    float d = hash12(vec2(n + 1.0, n + 2.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Curl noise for edge distortion
vec2 cloudCurlNoise(vec3 p, float scale) {
    float eps = 0.1;
    vec3 pScaled = p * scale;

    float x0 = cloudNoise3D(pScaled + vec3(eps, 0.0, 0.0));
    float x1 = cloudNoise3D(pScaled - vec3(eps, 0.0, 0.0));
    float y0 = cloudNoise3D(pScaled + vec3(0.0, eps, 0.0));
    float y1 = cloudNoise3D(pScaled - vec3(0.0, eps, 0.0));
    float z0 = cloudNoise3D(pScaled + vec3(0.0, 0.0, eps));
    float z1 = cloudNoise3D(pScaled - vec3(0.0, 0.0, eps));

    vec3 curl = vec3(
        (y0 - y1) - (z0 - z1),
        (z0 - z1) - (x0 - x1),
        (x0 - x1) - (y0 - y1)
    );

    return curl.xy * 0.5;
}

// Multi-octave erosion noise
float cloudErosionNoise(vec3 p, float octaves, float detailOctaves) {
    // Base shape
    float base = cloudFBM(p, octaves);

    // Detail erosion
    float detail = 0.0;
    float amp = 0.5;
    float freq = 4.0;
    float maxDetail = 0.0;

    for (float i = 0.0; i < detailOctaves; i += 1.0) {
        detail += amp * cloudWorley(p * freq, 1.0);
        maxDetail += amp;
        amp *= 0.5;
        freq *= 2.0;
    }
    detail /= maxDetail;

    // Erode base shape with detail
    float eroded = base - detail * 0.3;
    return saturate(eroded);
}

// Coverage noise (large-scale cloud patterns)
float cloudCoverageNoise(vec2 pos, float scale, float time) {
    vec2 windOffset = vec2(time * 0.01, time * 0.005);
    vec3 p = vec3(pos * scale + windOffset, 0.0);
    return cloudFBM(p, 3.0);
}

// Tiling optimization: hash-based offset for seamless tiling
vec3 cloudTilingOffset(float seed) {
    return vec3(
        hash11(seed + 0.1) * 1000.0,
        hash11(seed + 0.2) * 1000.0,
        hash11(seed + 0.3) * 1000.0
    );
}

#endif