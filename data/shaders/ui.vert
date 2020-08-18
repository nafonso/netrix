#version 330 core
layout (location = 0) in vec4 vert;

out vec4 MainColor;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;
uniform vec4 tint_color;

void main() {
    gl_Position = proj * view * model * vec4(vert.xy, 0.0, 1.0);
    MainColor = tint_color;
    TexCoord = vert.zw;
}
