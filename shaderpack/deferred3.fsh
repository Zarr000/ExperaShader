#version 150

// Volumetric fog pass (depth-based height fog + noise) - outputs fog factor in alpha.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gDepth;

uniform float volumetricFogEnabled;
uniform float volumetricFogQuality;
uniform vec3 cameraPosition;

// Height fog params (original)
uniform float fogDensity;
uniform float fogHeight;
uniform float fogFalloff;

float hash2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main() {
    float depth = texture2D(gDepth, vUV).r;
    float dist = depth * 120.0;

    // Height term using camera y as proxy.
    float h = cameraPosition.y;

    float heightAtten = exp(-max(0.0, (h - fogHeight)) * fogFalloff);

    // Procedural noise to avoid banding.
    vec2 p = vUV * screenSize * 0.25;
    float n = hash2(p + vec2(time * 0.03, time * 0.02));
    float jitter = (n - 0.5) * 0.02;

    float density = fogDensity * (0.8 + jitter);

    // Extinction
    float fogFactor = 1.0 - exp(-dist * density * heightAtten);
    fogFactor = saturate(fogFactor);

    float enable = step(0.5, volumetricFogEnabled);
    fogFactor *= enable;

    FragColor = vec4(vec3(fogFactor), fogFactor);
}

