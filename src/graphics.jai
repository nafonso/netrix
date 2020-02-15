#import "GL";
#import "Math";
#import "Debug";

Static_Mesh :: struct {

    vertex_buffer : []float;

    vertices : []Vector3;
    colors : []Vector3;
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

init_static_mesh :: ( using mesh : *Static_Mesh, num_vertices : int, num_triangles : int ) {

    if num_vertices == 0 { return; }

    // all data is in a row, so passing all of them and starting points of vertices will work
    vertex_data_size := num_vertices * size_of(Vector3);
    color_data_size := num_vertices * size_of(Vector3);
    uv_data_size := num_vertices * size_of(Vector2);
    buffer_size := vertex_data_size + color_data_size + uv_data_size;

    vertex_buffer = NewArray( buffer_size, float );

    vertices.data = xx vertex_buffer.data;
    vertices.count = num_vertices;

    colors.data = xx (vertices.data + num_vertices);
    colors.count = num_vertices;

    uvs.data = xx (colors.data + num_vertices);
    uvs.count = num_vertices;

    indices = NewArray(num_triangles * 3, u32);

    model = matrix4_identity();
}

deinit_static_mesh :: ( using mesh : *Static_Mesh ) {
    if vertex_buffer.count == 0 { return; }

    free(vertex_buffer.data);
    Delete(indices.data);
}

bind_static_mesh :: ( using mesh : *Static_Mesh ){
    glGenVertexArrays(1, *v_a_o);
    glGenBuffers(1, *v_b_o);
    glGenBuffers(1, *e_b_o);

    glBindVertexArray(v_a_o);

    glBindBuffer(GL_ARRAY_BUFFER, v_b_o);
    glBufferData(GL_ARRAY_BUFFER, vertex_buffer.count, vertex_buffer.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, e_b_o);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32)*indices.count, indices.data, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vector3), cast(*void)0 );
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(Vector3), cast(*void)(vertices.count*size_of(Vector3)));
    glEnableVertexAttribArray(1);

    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(Vector2), cast(*void)((vertices.count + colors.count)*size_of(Vector3)));
    glEnableVertexAttribArray(2);
    
    glBindVertexArray(0);
}



// create_quad_xy :: ( rm : *Render_Manager, center : Vector3, width : float, height : float ) -> *Static_Mesh {

//     quad := create_static_mesh(*render_manager);
//     using quad;

//     init_static_mesh( quad, 4, 2 );

//     half_width := width * 0.5;
//     half_height := height * 0.5;

//     vertices[0] = make_vector3(center.x - half_width, center.y - half_height, center.z);
//     vertices[1] = make_vector3(center.x + half_width, center.y - half_height, center.z);
//     vertices[2] = make_vector3(center.x + half_width, center.y + half_height, center.z);
//     vertices[3] = make_vector3(center.x - half_width, center.y + half_height, center.z);

//     colors[0] = make_vector3(1.0);
//     colors[1] = make_vector3(1.0);
//     colors[2] = make_vector3(1.0);
//     colors[3] = make_vector3(1.0);

//     uvs[0] = make_vector2(0.0, 1.0);
//     uvs[1] = make_vector2(1.0, 1.0);
//     uvs[2] = make_vector2(1.0, 0.0);
//     uvs[3] = make_vector2(0.0, 0.0);

//     indices[0] = 0;
//     indices[1] = 1;
//     indices[2] = 2;
//     indices[3] = 2;
//     indices[4] = 3;
//     indices[5] = 0;

//     return quad;
// }

// create_ui_quad_xy :: ( rm : *Render_Manager, center : Vector3, width : float, height : float ) -> *Static_Mesh {

//     quad := create_ui_mesh(*render_manager);
//     using quad;

//     init_static_mesh( quad, 4, 2 );

//     half_width := width * 0.5;
//     half_height := height * 0.5;

//     vertices[0] = make_vector3(center.x - half_width, center.y - half_height, center.z);
//     vertices[1] = make_vector3(center.x + half_width, center.y - half_height, center.z);
//     vertices[2] = make_vector3(center.x + half_width, center.y + half_height, center.z);
//     vertices[3] = make_vector3(center.x - half_width, center.y + half_height, center.z);

//     colors[0] = make_vector3(1.0);
//     colors[1] = make_vector3(1.0);
//     colors[2] = make_vector3(1.0);
//     colors[3] = make_vector3(1.0);

//     uvs[0] = make_vector2(0.0, 1.0);
//     uvs[1] = make_vector2(1.0, 1.0);
//     uvs[2] = make_vector2(1.0, 0.0);
//     uvs[3] = make_vector2(0.0, 0.0);

//     indices[0] = 0;
//     indices[1] = 1;
//     indices[2] = 2;
//     indices[3] = 2;
//     indices[4] = 3;
//     indices[5] = 0;

//     return quad;
// }