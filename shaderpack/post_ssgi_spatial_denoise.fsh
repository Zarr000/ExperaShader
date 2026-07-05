#version 150

#include "lib/common.glsl"
#include "lib/uniforms.glsl"

in vec2 vUV;
out vec4 FragColor;

// Inputs
uniform sampler2D gSSGI;            // diffuse GI buffer (linear)
uniform sampler2D gLinearDepthTex;
uniform sampler2D gNormalRoughTex;

// Optional temporal GI history buffer; if missing, sampler returns 0.
uniform sampler2D gPrevSSGI;
uniform float giTemporal;


// Output is filtered GI

vec3 decodeNormal(vec3 packed) {
    return normalize(packed * 2.0 - 1.0);
}

float depthAt(vec2 uv){
    return texture2D(gLinearDepthTex, uv).r;
}

vec3 normalAt(vec2 uv){
    return decodeNormal(texture2D(gNormalRoughTex, uv).rgb);
}

void main() {
    vec2 texel = 1.0 / max(screenSize, vec2(1.0));

    float centerD = depthAt(vUV);
    vec3 centerN = normalAt(vUV);

    vec3 sum = vec3(0.0);
    float wsum = 0.0;

    // 5-tap cross bilateral (spatial denoise)
    vec2 offsets[5] = vec2[5](
        vec2(0.0, 0.0),
        vec2(texel.x, 0.0),
        vec2(-texel.x, 0.0),
        vec2(0.0, texel.y),
        vec2(0.0, -texel.y)
    );

    for (int i = 0; i < 5; i++) {
        vec2 uv = vUV + offsets[i];
        float d = depthAt(uv);
        vec3 n = normalAt(uv);

        float dd = d - centerD;
        float dn = 1.0 - saturate(dot(centerN, n));

        float w = exp(-(dd * dd) * 180.0) * exp(-(dn * dn) * 60.0);
        vec3 gi = texture2D(gSSGI, uv).rgb;
        sum += gi * w;
        wsum += w;
    }

    vec3 outGi = sum / max(wsum, 1e-5);

    // Temporal reinforcement: blend with previous GI lightly to reduce noise.
    vec3 prev = texture2D(gPrevSSGI, vUV).rgb;
    outGi = mix(outGi, prev, clamp(giTemporal, 0.0, 1.0) * 0.25);

    FragColor = vec4(outGi, 1.0);

}

