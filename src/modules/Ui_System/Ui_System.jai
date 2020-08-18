#import "Texture_Manager";
#import "Font_Manager";

Ui_System :: struct {
    using tm : *Texture_Manager;
    using fm : *Font_Manager;

    root_elements : [..]*Ui_Element;

    elements : [..]*Ui_Element;

    is_dirty : Ui_Dirty;

    window_size : Vector2;

    mouse_pos    : Vector2;

    // leaf hovered element
    selected_element : *Ui_Element;

    // selected element that requested being active, ie consumming input, eg button pressed down
    active_element : *Ui_Element;

    // rendering
    shader       : GLuint;
    v_a_o        : GLuint; // vertex array object
    v_b_o        : GLuint; // vertex buffer object
    e_b_o        : GLuint; // element buffer object
    
    // shader uniform locations
    proj_loc       : s32;
    view_loc       : s32;
    model_loc      : s32;
    tint_color_loc : s32;

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

ui_system_init :: (using ui_system : *Ui_System, texture_manager : *Texture_Manager, font_manager : *Font_Manager, shader_id : GLuint, window_width : u32, window_height : u32, debug_shader_id : GLuint = 0) {

    tm = texture_manager;
    fm = font_manager;

    array_reserve(*elements, 128);

    shader = shader_id;
    debug_shader = debug_shader_id;

    is_debug_on = false;

    proj_loc = glGetUniformLocation(shader, "proj");
    view_loc = glGetUniformLocation(shader, "view");
    model_loc = glGetUniformLocation(shader, "model");
    tint_color_loc = glGetUniformLocation(shader, "tint_color");
  
    glGenVertexArrays(1, *v_a_o);
    glGenBuffers(1, *v_b_o);
    glGenBuffers(1, *e_b_o);

    if debug_shader_id != 0 { // only if can debug
        glGenVertexArrays(1, *debug_v_a_o);
        glGenBuffers(1, *debug_v_b_o);
        debug_proj_loc = glGetUniformLocation(debug_shader, "proj");
        debug_view_loc = glGetUniformLocation(debug_shader, "view");
        debug_model_loc = glGetUniformLocation(debug_shader, "model");
    }

    ui_on_window_size_changed(ui_system, window_width, window_height);
}

ui_enable_debug :: (using ui_system : *Ui_System, enable : bool) {
    if debug_shader == 0 || is_debug_on == enable {
        return;
    }
    
    is_debug_on = enable;
    ui_set_dirty(ui_system);
}

ui_set_mouse_pos :: (using ui_system : *Ui_System, pos : Vector2){
    mouse_pos = pos;
    is_dirty |= Ui_Dirty.INPUT;
}

ui_on_window_size_changed :: (using ui_system : *Ui_System, window_width : u32, window_height : u32) {
    is_dirty = Ui_Dirty.ALL;
    window_size = make_vector2(xx window_width, xx window_height);
    for root_elements {
        it.size = window_size;
    }
}

// @TODO needs notion of local position of elements, otherwise it is pretty annoying to do inner
// absolute positions
ui_system_layout :: (using ui_system : *Ui_System) {

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

    previous_selected_element := selected_element;
    selected_element = null;
    
    for root_elements {
        aux_selected_element := it.layout_func(it, ui_system.mouse_pos, is_dirty);

        if !is_dirty {
            selected_element = previous_selected_element;
        }
        else{
            // always take last root element?
            if aux_selected_element {
                selected_element = aux_selected_element;
            }
        }

        if rebuild_layout {
            ui_fill_buffers(it, *vertex_buffer, *element_buffer, debug_vertex_buffer_pointer);
        }
    }

    if previous_selected_element != selected_element {
        if previous_selected_element {
            previous_state := previous_selected_element.state;
            unset_state( previous_selected_element, Ui_Element_State.SELECTED );
            // previous_selected_element.state &= ~Ui_Element_State.SELECTED;
            if previous_selected_element.on_state_changed {
                previous_selected_element.on_state_changed(previous_selected_element, previous_state);
            }
        }
        if selected_element {
            previous_state := selected_element.state;
            set_state(selected_element, Ui_Element_State.SELECTED);
            // selected_element.state |= Ui_Element_State.SELECTED;
            if selected_element.on_state_changed {
                selected_element.on_state_changed(selected_element, previous_state);
            }
        }
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

ui_fill_buffers :: (e : *Ui_Element, vertex_buffer : *[..]float, element_buffer : *[..]u32, debug_vertex_buffer : *[..]float) {

    if e.state & Ui_Element_State.VISIBLE == 0 {
        return;
    }

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
        if e.parent == null {
            e.brush.calc_desired_size(e); // calc_desires_size will properly handle text, but if no parent there's nobody calling this
        }
        vertices = ui_text_vertex_buffer(e.pos, *e.brush);
        vertex_offset : u32 = ifx vertices.count > 0 then cast(u32)vertex_buffer.count / 4 else 0;
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
        ui_fill_buffers(it, vertex_buffer, element_buffer, debug_vertex_buffer);
    }
}

ui_system_render :: (using ui_system : *Ui_System, projection : Matrix4, view : Matrix4) {
    glEnable(GL_BLEND);
    glEnable(GL_SCISSOR_TEST);

    ui_system_layout(ui_system);

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
        ui_element_render(ui_system, it, *indices_offset);
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
            ui_element_render_debug(it, *element_index);
        }
    }

    glDisable(GL_BLEND);
}

ui_element_render :: (ui_system : *Ui_System, e : *Ui_Element, indices_offset : *u32) {

    if e.state & Ui_Element_State.VISIBLE == 0 {
        return;
    }

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
        // debug_here();
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
                // @note use this one whenever we undo the flipped Y axis
                // glScissor(xx e.parent.pos.x, xx e.parent.pos.y, xx e.parent.size.x, xx e.parent.size.y);
                glScissor(xx e.parent.pos.x, xx (e.ui_system.window_size.y - e.parent.pos.y - e.parent.size.y), xx e.parent.size.x, xx e.parent.size.y);
            }
            else{
                glScissor(0, 0, U32_MAX, U32_MAX);
            }
            case Ui_Clipping.SELF;
                // @note use this one whenever we undo the flipped Y axis
                // glScissor(xx e.pos.x, xx e.pos.y, xx e.size.x, xx e.size.y);
                glScissor(xx e.pos.x, xx (e.ui_system.window_size.y - e.pos.y - e.size.y), xx e.size.x, xx e.size.y);
            case Ui_Clipping.NONE;
                glScissor(0, 0, U32_MAX, U32_MAX);
        }

        glUniform4fv(ui_system.tint_color_loc, 1, *e.brush.tint_color.x);

        glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, offset_pointer );
        <<indices_offset += num_indices;
    }


    for e.children {
        ui_element_render(ui_system, it, indices_offset);
    }
}

ui_element_render_debug :: (e : *Ui_Element, element_index : *u32) {
    if e.state & Ui_Element_State.VISIBLE == 0 {
        return;
    }

    glDrawArrays(GL_LINE_LOOP, xx <<element_index, 4);
    <<element_index += 4;

    for e.children {
        ui_element_render_debug(it, element_index);
    }
}

ui_add_root_element :: (using ui_system : *Ui_System, element : *Ui_Element) {
    assert(element.ui_system == null);
    array_add( *root_elements, element );
    set_ui_system( element, ui_system );
    element.size = window_size;
    is_dirty = Ui_Dirty.ALL;
}

ui_remove_root_element :: (using ui_system : *Ui_System, element : *Ui_Element) {
    array_unordered_remove_by_value( *root_elements, element );
    set_ui_system( element, null );
    is_dirty = Ui_Dirty.ALL;
}

ui_set_dirty :: (using ui_system : *Ui_System, dirty_flag : Ui_Dirty = Ui_Dirty.ALL) {
    is_dirty |= dirty_flag;
}

ui_element_create :: (using ui_system : *Ui_System, element : $T/Ui_Element ) -> *T {
    e := New(T);
    <<e = element;
    array_add(*elements, e);
    return e;
}

ui_element_destroy :: (using ui_system : *Ui_System, element : *Ui_Element ) {
    if !element {
        return;
    }
    
    if is_root(element) {
        ui_remove_root_element(ui_system, element);
    }

    array_unordered_remove_by_value(*elements, element);

    for element.children {
        ui_element_destroy(ui_system, it);
    }

    free(element);
}

ui_handle_event :: (using ui_system : *Ui_System, evt : *Ui_Event) {
    
    ui_handle_event_internal :: (ui_system : *Ui_System, e : *Ui_Element, evt : *Ui_Event, recursive : bool ) {
        if !e || e.state & Ui_Element_State.DISABLED || evt.used { 
            return; 
        }

        previous_state := e.state;

        if e.handle_event {
            e.handle_event(e, evt);
        }

        if e.state != previous_state {
            if e.state & Ui_Element_State.ACTIVE {
                assert(ui_system.active_element == null || ui_system.active_element == e);
                ui_system.active_element = e;
            }

            if e.on_state_changed {
                e.on_state_changed(e, previous_state);
            }
        }

        if recursive {
            ui_handle_event_internal(ui_system, e.parent, evt, recursive);
        }
    };

    // first handle active element
    if active_element && active_element.handle_event {
        ui_handle_event_internal(ui_system, active_element, evt, false);
    }

    if !evt.used {
        ui_handle_event_internal(ui_system, selected_element, evt, true);
    }

    if active_element && active_element.state & Ui_Element_State.ACTIVE == 0 {
        active_element = null;
    }
}



get_texture :: ( ui_system : *Ui_System, texture_path : string ) -> GLuint {
    return get_texture(ui_system.tm, texture_path, ui_system);
}

get_font :: (ui_system : *Ui_System, font_path : string, font_size : u8) -> *Dynamic_Font {
    return get_font(ui_system.fm, font_path, font_size);
}

ui_button_create :: (ui_system : *Ui_System, text : string, font : *Dynamic_Font, on_clicked_callback : (*Ui_Button), disabled : bool = false) -> *Ui_Button {
    button := ui_element_create(ui_system, ui_button(ui_system, on_clicked_callback, disabled));
    button.padding = 10;

    button_text : *Ui_Element = ui_element_create(ui_system, ui_element());
    button_text.fill = false;
    button_text.brush = brush_text(text, font);

    add_child(button, button_text);

    return button;
}

ui_label_create :: (ui_system : *Ui_System, text : string, font : *Dynamic_Font) -> *Ui_Element {
    label := ui_element_create(ui_system, ui_element());
    label.brush = brush_text(text, font);

    return label;
}

ui_fixed_space_create :: (ui_system : *Ui_System, width : float, height : float) -> *Ui_Element {
    space := ui_element_create(ui_system, ui_element());
    space.min_size = make_vector2(width, height);
    space.max_size = space.min_size;
    return space;
}

ui_fixed_space_create :: (ui_system : *Ui_System, size : float) -> *Ui_Element {
    return ui_fixed_space_create(ui_system, size, size);
}

ui_flexible_space_create :: (ui_system : *Ui_System, min_width : float = 0, min_height : float = 0, fill_ratio : float = 1.0) -> *Ui_Element {
    space := ui_element_create(ui_system, ui_element());
    space.min_size = make_vector2(min_width, min_height);
    space.fill_ratio = fill_ratio;
    return space;
}

ui_horizontal_box_create :: (ui_system : *Ui_System, alignment : Ui_Alignment = Ui_Alignment.MID_CENTER) -> *Ui_Element {
    element := ui_element_create(ui_system, ui_element(layout_horizontal, alignment = alignment));
    return element;
}

ui_vertical_box_create :: (ui_system : *Ui_System, alignment : Ui_Alignment = Ui_Alignment.TOP_CENTER) -> *Ui_Element {
    element := ui_element_create(ui_system, ui_element(layout_vertical, alignment = alignment));
    return element;
}
