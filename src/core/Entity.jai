#import "Hash_Table";

Entity :: struct {
    id : u32;
}

Entity_Manager :: struct {
    entity_table : Table(u32, *Entity);

    next_entity_id : u32 = 1;
}

init :: (em : *Entity_Manager) {
    init(*em.entity_table, 512);
}

create_entity :: (em : *Entity_Manager, t : $T) -> T {
    e = New(T);

    e.id = em.next_entity_id;
    em.next_entity_id += 1;

    return e;
}

get_entity :: (em : *Entity_Manager, id : u32) -> *Entity {
    e, success := table_find(em.entity_table, id);
    if success return e;
    return null;
}

Mesh :: struct {
    buffer      : [..]float; // vertices, normals, uvs intertwined

    texture     : GLuint; // texture id

    color       : Vector4;

    model       : Matrix4;

    num_indices : GLuint;

    // rendering
    shader      : GLuint;
    v_a_o       : GLuint; // vertex array object
    v_b_o       : GLuint; // vertex buffer object
    e_b_o       : GLuint; // element buffer object

    // shader uniform locations
    model_loc   : s32;
    color_loc   : s32;
}

init_mesh :: (using mesh : *Mesh, shader_id : GLuint) {
    shader = shader_id;

    model_loc = glGetUniformLocation(shader, "model");
    color_loc = glGetUniformLocation(shader, "color");

    color = make_vector4(1, 1, 1, 1);

    model = matrix4_identity();

    glGenVertexArrays(1, *v_a_o);
    glGenBuffers(1, *v_b_o);
    glGenBuffers(1, *e_b_o);
}

deinit_mesh :: (using mesh : *Mesh) {
    glDeleteVertexArrays(1, *v_a_o);
    glDeleteBuffers(1, *v_b_o);
    glDeleteBuffers(1, *e_b_o);
}

update_mesh :: (mesh : *Mesh, vertices : []Vector3, uvs : []Vector2) {
    assert(vertices.count == uvs.count);

    mesh.buffer.count = 0;

    num_vertices := vertices.count;

    num_floats_per_vertice := 3 + 2;

    num_total_floats := num_floats_per_vertice * num_vertices;

    array_reserve(*mesh.buffer, num_total_floats);
    mesh.buffer.count = num_total_floats;

    for i : 0..num_vertices-1 {
        buffer_index := i * num_floats_per_vertice;

        memcpy(*mesh.buffer[buffer_index], *vertices[i], size_of(Vector3));
        buffer_index += 3;
        memcpy(*mesh.buffer[buffer_index], *uvs[i], size_of(Vector2));
    }

    num_triangles := num_vertices / 3;

    elements : [..]u32;

    elements.allocator = __temporary_allocator;
    array_reserve(*elements, num_vertices); // num_vertices since it's x3
    elements.count = num_vertices;

    for i : 0..cast(u32)num_vertices-1 {
        elements[i] = i;
    }

    mesh.num_indices = cast(u32)elements.count;

    glBindVertexArray(mesh.v_a_o);

    glBindBuffer(GL_ARRAY_BUFFER, mesh.v_b_o);
    glBufferData(GL_ARRAY_BUFFER, size_of(float)*mesh.buffer.count, mesh.buffer.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.e_b_o);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32)*elements.count, elements.data, GL_STATIC_DRAW);

    vertex_stride : u32 = size_of(Vector3)+size_of(Vector2);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, vertex_stride, cast(*void)0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, vertex_stride, cast(*void)size_of(Vector3));

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
}

create_block_mesh :: (block_size : float, shader : GLuint, texture : GLuint) -> Mesh {
    mesh : Mesh;

    init_mesh(*mesh, shader);

    mesh.texture = texture;

    vertices : [6]Vector3;
    uvs      : [6]Vector2;

    half_block_size := block_size * 0.5;

    vertices[0] = make_vector3(-half_block_size, -half_block_size, 0);
    vertices[1] = make_vector3(half_block_size, -half_block_size, 0);
    vertices[2] = make_vector3(half_block_size, half_block_size, 0);
    vertices[3] = make_vector3(half_block_size, half_block_size, 0);
    vertices[4] = make_vector3(-half_block_size, half_block_size, 0);
    vertices[5] = make_vector3(-half_block_size, -half_block_size, 0);

    uvs[0] = make_vector2(0, 0);
    uvs[1] = make_vector2(-1, 0);
    uvs[2] = make_vector2(-1, -1);
    uvs[3] = make_vector2(-1, -1);
    uvs[4] = make_vector2(0, -1);
    uvs[5] = make_vector2(0, 0);

    update_mesh(*mesh, vertices, uvs);

    return mesh;
}

mesh_render :: (using mesh : *Mesh) {
    glUseProgram(shader);

    glUniform4fv(color_loc, 1, *color.x);
    glUniformMatrix4fv(model_loc, 1, GL_TRUE, *model._11);

    glBindVertexArray(v_a_o);

    glBindTexture(GL_TEXTURE_2D, texture);

    glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, cast(*void)0);
}

// 12_13____14__15
// |   |     |  |
// 8___9____10__11
// |   |     |  | 
// 4___5_____6__7
// |   |     |  |
// 0___1_____2__3
make_xy_quad_9_slice :: (pos : Vector2, size : Vector2, border : float, uv_slice : float) -> [16]Vector3, [16]Vector2, [54]u32 {
    verts   : [16]Vector3;
    uvs     : [16]Vector2;
    indices : [54]u32;



    y_offset := 0.0;
    v_offset := 0.0;
    indice_offset := 0;

    for i : 0..3 {
        vert_index := i*4;
        verts[vert_index+0] = make_vector3(pos.x, pos.y+y_offset, 0);
        verts[vert_index+1] = make_vector3(pos.x+border, pos.y+y_offset, 0);
        verts[vert_index+2] = make_vector3(pos.x+border+size.x, pos.y+y_offset, 0);
        verts[vert_index+3] = make_vector3(pos.x+border+border+size.x, pos.y+y_offset, 0);

        uvs[vert_index+0] = make_vector2(0, v_offset);
        uvs[vert_index+1] = make_vector2(uv_slice, v_offset);
        uvs[vert_index+2] = make_vector2(1-uv_slice, v_offset);
        uvs[vert_index+3] = make_vector2(1, v_offset);

        if i < 3 {
            indice_index : u32 = cast(u32)(i*18);

            indices[indice_index+0] = cast(u32)indice_offset+0;
            indices[indice_index+1] = cast(u32)indice_offset+1;
            indices[indice_index+2] = cast(u32)indice_offset+5;
            indices[indice_index+3] = cast(u32)indice_offset+5;
            indices[indice_index+4] = cast(u32)indice_offset+4;
            indices[indice_index+5] = cast(u32)indice_offset+0;
            
            indices[indice_index+6] = cast(u32)indice_offset+1;
            indices[indice_index+7] = cast(u32)indice_offset+2;
            indices[indice_index+8] = cast(u32)indice_offset+6;
            indices[indice_index+9] = cast(u32)indice_offset+6;
            indices[indice_index+10] = cast(u32)indice_offset+5;
            indices[indice_index+11] = cast(u32)indice_offset+1;

            indices[indice_index+12] = cast(u32)indice_offset+2;
            indices[indice_index+13] = cast(u32)indice_offset+3;
            indices[indice_index+14] = cast(u32)indice_offset+7;
            indices[indice_index+15] = cast(u32)indice_offset+7;
            indices[indice_index+16] = cast(u32)indice_offset+6;
            indices[indice_index+17] = cast(u32)indice_offset+2;
        }

        if i == {
            case 0;
                y_offset += border;
                v_offset = uv_slice;
                indice_offset+=4;
            case 1;
                y_offset += size.y;
                v_offset = 1-uv_slice;
                indice_offset+=4;
            case 2;
                y_offset += border;
                v_offset = 1;
                indice_offset+=4;
        }
    }

    return verts, uvs, indices;
}


