#version 150

// Space transforms: screen <-> view, depth reconstruction.

#ifndef SPACE_TRANSFORMS_GLSL
#define SPACE_TRANSFORMS_GLSL

vec3 reconstructViewPosition(float depth, vec2 uv, mat4 projection, vec2 viewportSize) {
    // uv in [0,1]
    vec2 ndc = uv * 2.0 - 1.0;
    // Convert depth to clip space z. In OptiFine, depth texture is usually linearized in helper.
    // Here we do a conservative reconstruction using inverse projection.
    // depth is assumed to be non-linear depth in [0,1].
    vec4 clip = vec4(ndc, depth * 2.0 - 1.0, 1.0);
    vec4 view = inverse(projection) * clip;
    return view.xyz / max(view.w, 1e-6);
}

vec3 reconstructWorldPosition(float depth, vec2 uv, mat4 projection, mat4 view, vec2 viewportSize) {
    vec3 viewPos = reconstructViewPosition(depth, uv, projection, viewportSize);
    vec4 world = inverse(view) * vec4(viewPos, 1.0);
    return world.xyz;
}

mat3 normalMatrix(mat4 modelView) {
    return mat3(transpose(inverse(modelView)));
}

#endif

