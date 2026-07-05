#version 150

// Shadow map fragment shader (depth-only).

void main() {
    // Depth writing is handled by the pipeline. Explicit depth is conservative.
    gl_FragDepth = gl_FragCoord.z;
}

