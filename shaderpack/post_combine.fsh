#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"
#include "lib/tonemap.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;
uniform sampler2D gBloomBlur;

uniform float lensDirtIntensity;
uniform float bloomIntensity;

vec3 lensDirt(vec2 uv) {
    // Procedural lens dirt (original): vignette + noise streaks.
    vec2 p = uv * 2.0 - 1.0;
    float r2 = dot(p, p);
    float vig = exp(-r2 * 1.5);
    float n = hash12(uv * screenSize * 0.02 + time * 0.01);
    float streak = smoothstep(0.85, 1.0, n) * (1.0 - saturate(abs(p.x) * 0.8));
    return vec3(vig * streak);
}

void main() {
    vec3 hdr = texture2D(gColor, vUV).rgb;
    vec3 bloom = texture2D(gBloomBlur, vUV).rgb;

    vec3 combined = hdr + bloom;

    // Tonemap
    vec3 mapped = acesFilmic(combined * exposure);

    // Lens dirt
    vec3 dirt = lensDirt(vUV);
    mapped += dirt * lensDirtIntensity;

    // Gamma
    vec3 srgb = linearToSRGB(mapped);
    FragColor = vec4(srgb, 1.0);
}

