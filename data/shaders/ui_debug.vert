#version 330 core
layout (location = 0) in vec2 vert;

out vec4 TintColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
    gl_Position = proj * view * model * vec4(vert.xy, 0.0, 1.0);
    TintColor = vec4(0.8,0.1,0.1,1);
}
