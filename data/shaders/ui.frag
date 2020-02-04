#version 330 core
out vec4 FragColor;

in vec3 MainColor;
in vec2 TexCoord;

uniform sampler2D MainTex;

void main() {
    FragColor = texture(MainTex, TexCoord) * vec4(MainColor.xyz, 1);
}
