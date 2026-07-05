#version 150

// Material ID pass fragment shader.

in vec2 vUV;
in vec3 vNormal;
in vec4 vColor;

out vec4 FragColor;

// Use vertex color channels as a material hint if available.
// 0..1 range: map to discrete IDs.
void main() {
    float id = floor(vColor.r * 15.0 + 0.5);
    FragColor = vec4(id / 255.0, 0.0, 0.0, 1.0);
}

