#version 330 core
layout (location = 0) in vec4 vert;

out vec4 TintColor;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
    gl_Position = proj * view * model * vec4(vert.xy, 0.0, 1.0);
    TintColor = vec4(1,1,1,1);
    TexCoord = vert.zw;
}
