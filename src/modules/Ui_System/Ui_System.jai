Ui_System :: struct {
    root_elements : [..]*Ui_Element;

    is_dirty : Ui_Dirty;

    window_size : Vector2;

    mouse_pos    : Vector2;

    hovered_element : *Ui_Element;

    // rendering
    shader       : GLuint;
    v_a_o        : GLuint; // vertex array object
    v_b_o        : GLuint; // vertex buffer object
    e_b_o        : GLuint; // element buffer object
    
    // shader uniform locations
    proj_loc  : s32;
    view_loc  : s32;
    model_loc : s32;

    // debug
    is_debug_on  : bool;
    debug_shader : GLuint;
    debug_v_a_o  : GLuint; // debug vertex array object
    debug_v_b_o  : GLuint; // debug vertex buffer object

    // shader uniform locations
    debug_proj_loc  : s32;
    debug_view_loc  : s32;
    debug_model_loc : s32;
}

init_ui_system :: (using ui_system : *Ui_System, shader_id : GLuint, window_width : u32, window_height : u32, debug_shader_id : GLuint = 0) {

    shader = shader_id;
    debug_shader = debug_shader_id;

    is_debug_on = debug_shader_id != 0;

    proj_loc = glGetUniformLocation(shader, "proj");
    view_loc = glGetUniformLocation(shader, "view");
    model_loc = glGetUniformLocation(shader, "model");
  
    glGenVertexArrays(1, *v_a_o);
    glGenBuffers(1, *v_b_o);
    glGenBuffers(1, *e_b_o);

    if is_debug_on {
        glGenVertexArrays(1, *debug_v_a_o);
        glGenBuffers(1, *debug_v_b_o);
        debug_proj_loc = glGetUniformLocation(debug_shader, "proj");
        debug_view_loc = glGetUniformLocation(debug_shader, "view");
        debug_model_loc = glGetUniformLocation(debug_shader, "model");
    }

    on_window_size_changed(ui_system, window_width, window_height);

}

set_mouse_pos :: (using ui_system : *Ui_System, pos : Vector2){
    mouse_pos = pos;
    is_dirty |= Ui_Dirty.INPUT;
}

on_window_size_changed :: (using ui_system : *Ui_System, window_width : u32, window_height : u32) {
    is_dirty = Ui_Dirty.ALL;
    window_size = make_vector2(xx window_width, xx window_height);
    for root_elements {
        it.size = window_size;
    }
}

layout_ui_system :: (using ui_system : *Ui_System) {

    rebuild_layout := is_dirty & Ui_Dirty.LAYOUT;

    vertex_buffer : [..]float;
    element_buffer : [..]u32;

    debug_vertex_buffer : [..]float;
    debug_vertex_buffer_pointer : *[..]float;

    if rebuild_layout {
        vertex_buffer.allocator = __temporary_allocator;
        array_reserve(*vertex_buffer, 512);
        element_buffer.allocator = __temporary_allocator;
        array_reserve(*element_buffer, 512);
    
        if is_debug_on {
            debug_vertex_buffer.allocator = __temporary_allocator;
            array_reserve(*debug_vertex_buffer, 512);
            debug_vertex_buffer_pointer = *debug_vertex_buffer;
        }
    }

    previous_hovered_element := hovered_element;
    hovered_element = null;
    
    for root_elements {
        aux_hovered_element := it.layout_func(it, ui_system.mouse_pos, is_dirty);

        // always take last root element?
        if aux_hovered_element {
            hovered_element = aux_hovered_element;
        }

        if rebuild_layout {
            fill_buffers(it, *vertex_buffer, *element_buffer, debug_vertex_buffer_pointer);
        }
    }

    if hovered_element {
        print("hovered_element: %\n", hovered_element);
    }

    if rebuild_layout {
        glBindVertexArray(v_a_o);

        glBindBuffer(GL_ARRAY_BUFFER, v_b_o);
        glBufferData(GL_ARRAY_BUFFER, size_of(float)*vertex_buffer.count, vertex_buffer.data, GL_STATIC_DRAW);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, e_b_o);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32)*element_buffer.count, element_buffer.data, GL_STATIC_DRAW);

        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, size_of(Vector4), cast(*void)0 );
        glEnableVertexAttribArray(0);

        if is_debug_on {
            glBindVertexArray(debug_v_a_o);
            glBindBuffer(GL_ARRAY_BUFFER, debug_v_b_o);
            glBufferData(GL_ARRAY_BUFFER, size_of(float)*debug_vertex_buffer.count, debug_vertex_buffer.data, GL_STATIC_DRAW);

            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(Vector2), cast(*void)0 );
            glEnableVertexAttribArray(0);
        }
    }

    is_dirty = 0;
}

fill_buffers :: (e : *Ui_Element, vertex_buffer : *[..]float, element_buffer : *[..]u32, debug_vertex_buffer : *[..]float) {
    using Ui_Brush_Type;
    vertices : []float;
    indices : []u32;

    if #complete e.brush.type == {
        case NONE;
        case SLICED;
        vertices = ui_sliced_vertex_buffer(e.pos, e.size, e.brush.sliced.border, e.brush.sliced.uv_slice);
        vertex_offset : u32 = cast(u32)vertex_buffer.count / 4;
        indices = ui_sliced_indices(vertex_offset);
        case STRETCHED;
        vertices = ui_stretched_vertex_buffer( e.pos, e.size);
        vertex_offset : u32 = cast(u32)vertex_buffer.count / 4;
        indices = ui_stretched_indices(vertex_offset);
        case TILED;
        vertices = ui_tiled_vertex_buffer(e.pos, e.size, e.brush.tiled.x_repeat, e.brush.tiled.y_repeat);
        vertex_offset : u32 = cast(u32)vertex_buffer.count / 4;
        indices = ui_tiled_indices(vertex_offset);
        case TEXT;
        vertices = ui_text_vertex_buffer(e.pos, *e.brush);
        vertex_offset : u32 = cast(u32)vertex_buffer.count / 4;
        indices = ui_text_indices(vertex_offset, *e.brush);
    }

    // @todo memory copy
    for vertices {
        array_add(vertex_buffer, it);
    }

    for indices {
        array_add(element_buffer, it);
    }

    if debug_vertex_buffer {
        debug_vertices : []float = ui_debug_vertex_buffer(e.pos, e.size);
        for debug_vertices {
            array_add(debug_vertex_buffer, it);
        }
    }

    for e.children {
        fill_buffers(it, vertex_buffer, element_buffer, debug_vertex_buffer);
    }
}

render_ui_system :: (using ui_system : *Ui_System, projection : Matrix4, view : Matrix4) {
    glEnable(GL_BLEND);
    glEnable(GL_SCISSOR_TEST);

    layout_ui_system(ui_system);

    model := matrix4_identity();

    glUseProgram(shader);

    glUniformMatrix4fv(proj_loc, 1, GL_TRUE, *projection._11);
    glUniformMatrix4fv(view_loc, 1, GL_TRUE, *view._11);
    glUniformMatrix4fv(model_loc, 1, GL_TRUE, *model._11);

    glBindVertexArray(v_a_o);

    indices_offset : u32 = 0;

    window_width  : GLsizei = xx window_size.x;
    window_height : GLsizei = xx window_size.y;

    for root_elements {
        render_ui_element( it, *indices_offset );
    }

    glDisable(GL_SCISSOR_TEST);

    if is_debug_on {
        glUseProgram(debug_shader);

        glUniformMatrix4fv(debug_proj_loc, 1, GL_TRUE, *projection._11);
        glUniformMatrix4fv(debug_view_loc, 1, GL_TRUE, *view._11);
        glUniformMatrix4fv(debug_model_loc, 1, GL_TRUE, *model._11);

        glBindVertexArray(debug_v_a_o);

        element_index : u32 = 0;
        for root_elements {
            render_ui_element_debug(it, *element_index);
        }
    }

    glDisable(GL_BLEND);
}

render_ui_element :: (e : *Ui_Element, indices_offset : *u32) {
    num_indices : u32 = ---;
    using Ui_Brush_Type;
    if #complete e.brush.type == {
        case NONE;
        num_indices = 0;
        case SLICED;
        num_indices = 54;
        case STRETCHED;
        num_indices = 6;
        case TILED;
        num_indices = 6;
        case TEXT;
        num_indices = xx e.brush.text.indice_buffer.count;
    }

    if num_indices > 0 {
        if e.brush.texture {
            glBindTexture(GL_TEXTURE_2D, e.brush.texture);
        }

        offset_pointer := cast(*void)(<<indices_offset * size_of(u32));

        if #complete e.clipping == {
            case Ui_Clipping.PARENT;
            if e.parent {
                glScissor(xx e.parent.pos.x, xx e.parent.pos.y, xx e.parent.size.x, xx e.parent.size.y);
            }
            else{
                glScissor(0, 0, U32_MAX, U32_MAX);
            }
            case Ui_Clipping.SELF;
                glScissor(xx e.pos.x, xx e.pos.y, xx e.size.x, xx e.size.y);
            case Ui_Clipping.NONE;
                glScissor(0, 0, U32_MAX, U32_MAX);
        }

        glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, offset_pointer );
        <<indices_offset += num_indices;
    }


    for e.children {
        render_ui_element(it, indices_offset);
    }
}

render_ui_element_debug :: (e : *Ui_Element, element_index : *u32) {
    glDrawArrays(GL_LINE_LOOP, xx <<element_index, 4);
    <<element_index += 4;

    for e.children {
        render_ui_element_debug(it, element_index);
    }
}

add_root_element :: (using ui_system : *Ui_System, element : *Ui_Element) {
    array_add( *root_elements, element );
    set_ui_system( element, ui_system );
    element.size = window_size;
    is_dirty = Ui_Dirty.ALL;
}

remove_root_element :: (using ui_system : *Ui_System, element : *Ui_Element) {
    array_unordered_remove_by_value( *root_elements, element );
    set_ui_system( element, null );
    is_dirty = Ui_Dirty.ALL;
}

