#version 330 core
layout (location = 0) in vec3 vPos;
layout (location = 1) in vec2 vTexCoord;

layout(std140) uniform Game_Uniforms
{
    mat4 proj_view;
};

uniform vec4 color;
uniform mat4 model;

out vec3 MainColor;
out vec2 TexCoord;

void main() {
    gl_Position = proj_view * model * vec4(vPos, 1.0);
    MainColor = color.xyz;
    TexCoord = vTexCoord;
}
