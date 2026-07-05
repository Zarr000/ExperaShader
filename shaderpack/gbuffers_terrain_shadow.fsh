#version 150

// Shadow map fragment shader.

void main() {
    // No color output needed; depth stored by fixed pipeline.
    gl_FragDepth = gl_FragCoord.z;
}

