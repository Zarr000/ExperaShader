#version 150

// GTAO-inspired SSAO pass (horizon-based) - writes occlusion in alpha.
// Production goals:
// - Stable temporal behavior via low-discrepancy hemisphere sampling
// - Reduced banding via blue-noise rotation

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/blue_noise.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

// AO controls
uniform float ssaoEnabled;
uniform float ssaoRadius;
uniform float ssaoBias;

uniform mat4 gbufferProjection;

// Camera ray reconstruction
vec3 reconstructView(vec2 uv, float depth) {
    vec2 ndc = uv * 2.0 - 1.0;
    vec4 clip = vec4(ndc, depth * 2.0 - 1.0, 1.0);
    vec4 view = inverse(gbufferProjection) * clip;
    return view.xyz / max(view.w, 1e-6);
}

// Construct an orthonormal basis around view-space normal proxy.
// Without a normal buffer, we approximate normal from depth gradients.
vec3 reconstructNormalFromDepth(vec2 uv) {
    float d0 = texture2D(gDepth, uv).r;
    float dx = texture2D(gDepth, uv + vec2(1.0 / screenSize.x, 0.0)).r;
    float dy = texture2D(gDepth, uv + vec2(0.0, 1.0 / screenSize.y)).r;

    vec3 p = reconstructView(uv, d0);
    vec3 px = reconstructView(uv + vec2(1.0 / screenSize.x, 0.0), dx);
    vec3 py = reconstructView(uv + vec2(0.0, 1.0 / screenSize.y), dy);

    vec3 vx = px - p;
    vec3 vy = py - p;
    return normalize(cross(vy, vx));
}

float visibility(vec3 p0, vec3 n0, vec3 p1) {
    // Horizon-style attenuation.
    vec3 d = p1 - p0;
    float dist2 = max(dot(d, d), 1e-6);
    float nd = dot(n0, d) / sqrt(dist2);

    // Bias prevents self-occlusion.
    float oc = step(ssaoBias, -nd);

    // Range falloff.
    float w = exp(-dist2 / max(ssaoRadius * ssaoRadius, 1e-6));
    return oc * w;
}

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    float depth0 = texture2D(gDepth, vUV).r;
    vec3 p0 = reconstructView(vUV, depth0);

    // Normal proxy in view space.
    vec3 n0 = reconstructNormalFromDepth(vUV);
    n0 = normalize(n0);

    // Blue-noise rotation.
    float bn = blueNoise(vUV * screenSize * 0.25, time * 60.0);
    float rot = bn * 6.2831853;

    // Build tangent frame on n0.
    vec3 up = (abs(n0.y) < 0.999) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
    vec3 t = normalize(cross(up, n0));
    vec3 b = cross(n0, t);

    const int SAMPLE_COUNT = 10;
    float occ = 0.0;

    for (int i = 0; i < SAMPLE_COUNT; i++) {
        float fi = float(i) + 0.5;

        // Low-discrepancy sampling of hemisphere with golden angle.
        float ang = fi * 2.39996323 + rot;
        float r = sqrt(fi / float(SAMPLE_COUNT));
        vec3 dir = normalize((cos(ang) * t + sin(ang) * b) * r + n0 * sqrt(max(0.0, 1.0 - r * r)));

        // One-step horizon estimate along the hemisphere direction.
        float stepT = ssaoRadius * (0.15 + 0.85 * fi / float(SAMPLE_COUNT));
        vec3 p1 = p0 + dir * stepT;

        // Project sample point to screen to compare depth.
        vec4 clip1 = gbufferProjection * vec4(p1, 1.0);
        vec3 ndc1 = clip1.xyz / max(clip1.w, 1e-6);
        vec2 uv1 = ndc1.xy * 0.5 + 0.5;

        // Bounds check.
        float inBounds = step(0.0, uv1.x) * step(0.0, uv1.y) * step(uv1.x, 1.0) * step(uv1.y, 1.0);

        float depthSample = texture2D(gDepth, uv1).r;
        vec3 pDepth = reconstructView(uv1, depthSample);

        // Occlusion if the depth surface is closer than the sample position.
        float closer = step(0.0, pDepth.z - p1.z);
        float v = visibility(p0, n0, pDepth);

        occ += closer * v * inBounds;
    }

    float ao = 1.0 - occ / float(SAMPLE_COUNT);
    ao = clamp(ao, 0.0, 1.0);

    // Enable gating.
    ao = mix(1.0, ao, step(0.5, ssaoEnabled));

    FragColor = vec4(vec3(ao), ao);
}

