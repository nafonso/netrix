Mesh :: struct {
    vertices : []Vector3;
    uvs : []Vector2;
    indices : []u32;

    model : Matrix4 = ---;

    // rendering
    shader : GLuint;
    v_a_o : GLuint; // vertex array object
    v_b_o : GLuint; // vertex buffer object
    e_b_o : GLuint; // element buffer object
    
    texture : GLuint; // texture id
}