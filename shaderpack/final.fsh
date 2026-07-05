#version 150

// Final pass: optional contrast/saturation controls and vignette.

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

uniform sampler2D gColor;

uniform float vignetteIntensity;
uniform float saturation;
uniform float contrast;

void main() {
    vec3 c = texture2D(gColor, vUV).rgb;

    // Contrast around 0.5.
    c = (c - 0.5) * contrast + 0.5;

    // Saturation.
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = mix(vec3(l), c, saturation);

    // Vignette.
    vec2 p = vUV * 2.0 - 1.0;
    float r2 = dot(p, p);
    float vig = exp(-r2 * vignetteIntensity);
    c *= vig;

    // Clamp to avoid accidental NaNs/overexposure from intermediate passes.
    c = clamp(c, vec3(0.0), vec3(1.0));
    FragColor = vec4(c, 1.0);
}



