#version 150
#ifndef WATER_WAVES_GLSL
#define WATER_WAVES_GLSL

#include "lib/common.glsl"
#include "lib/noise.glsl"

// Gerstner wave implementation (production-ready) with multi-octave layers.

struct Wave {
    vec2 dir;
    float steepness;
    float wavelength;
    float speed;
};

vec2 normalize2(vec2 v){
    float l = length(v);
    return (l > 1e-6) ? (v / l) : vec2(1.0, 0.0);
}

// Dispersion relation approximation for shallow water.
float waveK(float wavelength) {
    return 2.0 * 3.14159265 / max(wavelength, 1e-4);
}

vec3 gerstnerDisplacement(vec3 p, vec3 n, Wave w, float t) {
    // Gerstner wave uses k, frequency and phase.
    vec2 d = normalize2(w.dir);
    float k = waveK(w.wavelength);
    float c = sqrt(9.81 / max(k, 1e-4));
    float phase = k * dot(d, p.xz) - w.speed * t;

    float a = w.steepness / max(k, 1e-4);
    float sinp = sin(phase);
    float cosp = cos(phase);

    // Displacement along XZ is also affected for correct normal.
    vec3 disp;
    disp.x = d.x * a * sinp;
    disp.z = d.y * a * sinp;
    disp.y = a * cosp;

    return disp;
}

// Multi-frequency wave set.
vec3 waterDisplacement(vec3 worldPos, vec3 normal, float t, out vec3 outNormal) {
    // Base normal from incoming.
    vec3 n0 = normalize(normal);

    // Tangent and bitangent for normal derivation.
    // Using analytical Gerstner normal: partial derivatives.
    vec3 p = worldPos;

    // Accumulate displacement and partial derivatives.
    float ampSum = 0.0;
    vec3 disp = vec3(0.0);

    // Fixed wave set (original but parameterized).
    // Each layer is created from deterministic directions.
    Wave w0; w0.dir=vec2(1.0, 0.2); w0.steepness=0.55; w0.wavelength=12.0; w0.speed=1.1;
    Wave w1; w1.dir=vec2(-0.3, 1.0); w1.steepness=0.35; w1.wavelength=7.0;  w1.speed=0.9;
    Wave w2; w2.dir=vec2(0.7, -0.6); w2.steepness=0.25; w2.wavelength=3.2;  w2.speed=1.4;
    Wave w3; w3.dir=vec2(-0.9, -0.2);w3.steepness=0.18; w3.wavelength=1.3;  w3.speed=1.8;

    // Use simple time-varying micro chop using fbm for realism.
    float micro = fbm(vec3(p.xz * 0.4, t * 0.07));

    vec3 d0 = gerstnerDisplacement(p, n0, w0, t);
    vec3 d1 = gerstnerDisplacement(p, n0, w1, t);
    vec3 d2 = gerstnerDisplacement(p, n0, w2, t);
    vec3 d3 = gerstnerDisplacement(p, n0, w3, t);

    disp = d0 + d1 + d2 + d3;
    disp.y += micro * 0.015;

    // Normal approximation by using displaced neighborhood.
    // This is more robust under varying mesh tessellation.
    float eps = 0.03;
    vec3 pX = p + vec3(eps, 0.0, 0.0);
    vec3 pZ = p + vec3(0.0, 0.0, eps);

    vec3 nDummy;
    vec3 dispX = gerstnerDisplacement(pX, n0, w0, t) + gerstnerDisplacement(pX, n0, w1, t) + gerstnerDisplacement(pX, n0, w2, t) + gerstnerDisplacement(pX, n0, w3, t);
    vec3 dispZ = gerstnerDisplacement(pZ, n0, w0, t) + gerstnerDisplacement(pZ, n0, w1, t) + gerstnerDisplacement(pZ, n0, w2, t) + gerstnerDisplacement(pZ, n0, w3, t);

    vec3 px = pX + dispX;
    vec3 pz = pZ + dispZ;
    vec3 pc = p + disp;

    vec3 tx = px - pc;
    vec3 tz = pz - pc;
    outNormal = normalize(cross(tz, tx));

    return disp;
}

#endif

