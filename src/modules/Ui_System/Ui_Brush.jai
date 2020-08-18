Ui_Brush_Type :: enum u8 {
    NONE; // no render
    SLICED;
    STRETCHED;
    TILED;
    TEXT;
}

Ui_Brush :: struct {
    type        : Ui_Brush_Type;
    texture     : GLuint;
    tint_color  : Vector4;
    
    calc_desired_size := ui_default_calc_desired_size;

    union {
        sliced : Ui_Brush_Sliced;
        tiled  : Ui_Brush_Tiled;
        text   : Ui_Brush_Text;
    }
}

Ui_Border :: struct {
    left    : float;
    right   : float;
    top     : float;
    bottom  : float;
}

Ui_Brush_Sliced :: struct {
    border      : Ui_Border; // border in pixels
    uv_slice    : Ui_Border; // uv border edge
}

Ui_Brush_Tiled :: struct {
    x_repeat : float;
    y_repeat : float;
}

Ui_Brush_Text :: struct {
    str              : string;
    str_buffer_size  : s64;
    font             : *Dynamic_Font;
    vertex_buffer    : [..]Vector4; // @note buffers should use __temporary_allocator
    indice_buffer    : [..]u32;
}

brush_sliced :: (texture : GLuint, border : float = 10, uv_slice : float = 0.25) -> Ui_Brush {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Type.SLICED;
    brush.texture = texture;
    brush.tint_color = make_vector4(1, 1, 1, 1);
    brush.calc_desired_size = ui_default_calc_desired_size;
    brush.sliced.border.left = border;
    brush.sliced.border.right = border;
    brush.sliced.border.top = border;
    brush.sliced.border.bottom = border;
    brush.sliced.uv_slice.left = uv_slice;
    brush.sliced.uv_slice.right = uv_slice;
    brush.sliced.uv_slice.top = uv_slice;
    brush.sliced.uv_slice.bottom = uv_slice;
    return brush;
}

brush_sliced :: (texture : GLuint, border : Ui_Border, uv_slice : Ui_Border) -> Ui_Brush {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Type.SLICED;
    brush.texture = texture;
    brush.tint_color = make_vector4(1, 1, 1, 1);
    brush.calc_desired_size = ui_default_calc_desired_size;
    brush.sliced.border = border;
    brush.sliced.uv_slice = uv_slice;
    return brush;
}

brush_stretched :: (texture : GLuint) -> Ui_Brush {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Type.STRETCHED;
    brush.texture = texture;
    brush.tint_color = make_vector4(1, 1, 1, 1);
    brush.calc_desired_size = ui_default_calc_desired_size;
    return brush;
}

brush_tiled :: (texture : GLuint, x_repeat : float = 32, y_repeat : float = 32 ) -> Ui_Brush {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Type.TILED;
    brush.texture = texture;
    brush.tint_color = make_vector4(1, 1, 1, 1);
    brush.calc_desired_size = ui_default_calc_desired_size;
    brush.tiled.x_repeat = x_repeat;
    brush.tiled.y_repeat = y_repeat;
    return brush;
}

brush_text :: (text : string, font : *Dynamic_Font) -> Ui_Brush {
    UI_BRUSH_TEXT_MIN_BUFFER_SIZE :: 16;

    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Type.TEXT;
    brush.texture = 0;
    brush.tint_color = make_vector4(1, 1, 1, 1);
    brush.calc_desired_size = ui_text_calc_desired_size;
    brush.text.font = font;
    assert(brush.text.font != null);

    brush.text.str_buffer_size = max(UI_BRUSH_TEXT_MIN_BUFFER_SIZE, text.count);
    brush.text.str.data = alloc(brush.text.str_buffer_size);
    brush.text.str.count = text.count;
    memcpy(brush.text.str.data, text.data, text.count);

    brush.text.vertex_buffer.allocator = __temporary_allocator;
    brush.text.indice_buffer.allocator = __temporary_allocator;
    return brush;
}

// 16 = 4 x vec4 (xy = pos, zw = uv);
ui_stretched_vertex_buffer :: (pos : Vector2, size : Vector2) -> [16]float {
    vertex_buffer : [16]float;

    vectors : []Vector4;
    vectors.data = cast(*Vector4)vertex_buffer.data;
    vectors.count = 4;

    vectors[0].xy = pos;
    vectors[0].zw = make_vector2(0.0, 0.0);

    vectors[1].xy = pos + make_vector2(size.x, 0.0);
    vectors[1].zw = make_vector2(1.0, 0.0);

    vectors[2].xy = pos + make_vector2(size.x, size.y);
    vectors[2].zw = make_vector2(1.0, 1.0);

    vectors[3].xy = pos + make_vector2(0.0, size.y);
    vectors[3].zw = make_vector2(0.0, 1.0);

    return vertex_buffer;
}

ui_stretched_indices :: (vertex_offset : u32) -> [6]u32 {
    indices : [6]u32;

    indices[0] = vertex_offset;
    indices[1] = vertex_offset+1;
    indices[2] = vertex_offset+2;
    indices[3] = vertex_offset+2;
    indices[4] = vertex_offset+3;
    indices[5] = vertex_offset;

    return indices;
}

// 16 = 4 x vec4 (xy = pos, zw = uv);
ui_tiled_vertex_buffer :: (pos : Vector2, size : Vector2, x_repeat : float, y_repeat : float) -> [16]float {
    vertex_buffer : [16]float;

    u_max := size.x / x_repeat;
    v_max := size.y / y_repeat;

    vectors : []Vector4;
    vectors.data = cast(*Vector4)vertex_buffer.data;
    vectors.count = 4;

    vectors[0].xy = pos;
    vectors[0].zw = make_vector2(0.0, 0.0);

    vectors[1].xy = pos + make_vector2(size.x, 0.0);
    vectors[1].zw = make_vector2(u_max, 0.0);

    vectors[2].xy = pos + make_vector2(size.x, size.y);
    vectors[2].zw = make_vector2(u_max, v_max);

    vectors[3].xy = pos + make_vector2(0.0, size.y);
    vectors[3].zw = make_vector2(0.0, v_max);

    return vertex_buffer;
}

ui_tiled_indices :: (vertex_offset : u32) -> [6]u32 {
    indices : [6]u32;

    indices[0] = vertex_offset;
    indices[1] = vertex_offset+1;
    indices[2] = vertex_offset+2;
    indices[3] = vertex_offset+2;
    indices[4] = vertex_offset+3;
    indices[5] = vertex_offset;

    return indices;
}

ui_text_vertex_buffer :: (pos : Vector2, brush : *Ui_Brush) -> []float {
    for * brush.text.vertex_buffer {
        it.x += pos.x;
        it.y += pos.y;
    }

    float_buffer : []float;
    if brush.text.vertex_buffer.count > 0 {
        float_buffer.data = *brush.text.vertex_buffer[0].x;
        float_buffer.count = brush.text.vertex_buffer.count * 4;
    }

    return float_buffer;
}

ui_text_indices :: (vertex_offset : u32, brush : *Ui_Brush) -> []u32{

    for * brush.text.indice_buffer {

        <<it = <<it + vertex_offset;
    }

    return brush.text.indice_buffer;
}

ui_debug_vertex_buffer :: (pos : Vector2, size : Vector2 ) -> [8]float {
    vertex_buffer : [8] float;

    vertices : []Vector2;
    vertices.data = xx vertex_buffer.data;
    vertices.count = 4;

    vertices[0] = pos;
    vertices[1] = pos + make_vector2(size.x, 0);
    vertices[2] = pos + make_vector2(size.x, size.y);
    vertices[3] = pos + make_vector2(0, size.y);

    return vertex_buffer;
}

ui_default_calc_desired_size :: (e : *Ui_Element) -> Vector2 {
    if e.fill {
        return e.max_size;
    }

    desired_size : Vector2;

    for child : e.children {
        child_desired_size := child.brush.calc_desired_size(child);
        desired_size.x = max(desired_size.x, child_desired_size.x);
        desired_size.y = max(desired_size.y, child_desired_size.y);
    }

    total_padding := e.padding + e.padding;

    desired_size.x += total_padding;
    desired_size.y += total_padding;

    return desired_size;
}

ui_text_calc_desired_size :: (e : *Ui_Element) -> Vector2 {
    using e.brush;
    prep_text_flipped(text.font, e.margin, e.margin, make_vector4(1.0, 1.0, 1.0, 1.0), text.str, 0);

    // clear storage, temporary storage doesn't actually free
    array_reset(*text.vertex_buffer);
    array_reset(*text.indice_buffer);
    
    array_reserve(*text.vertex_buffer, text.font.current_quads.count * 4);
    array_reserve(*text.indice_buffer, text.font.current_quads.count * 6);
    
    min_x := FLOAT32_MAX;
    max_x := FLOAT32_MIN;

    flip_uvs :: true; // invert them to match our "inverted way" of rendering ui

    for e.brush.text.font.current_quads {
        // handle verts
        #if flip_uvs {
            v0 := make_vector4(it.x0, it.y0, it.u0, it.v0);
            v1 := make_vector4(it.x1, it.y0, it.u1, it.v0);
            v2 := make_vector4(it.x1, it.y1, it.u1, it.v1);
            v3 := make_vector4(it.x0, it.y1, it.u0, it.v1);
        }
        else {
            v0 := make_vector4(it.x0, it.y0, it.u0, it.v0);
            v1 := make_vector4(it.x1, it.y0, it.u1, it.v0);
            v2 := make_vector4(it.x1, it.y1, it.u1, it.v1);
            v3 := make_vector4(it.x0, it.y1, it.u0, it.v1);
        }

        if it.x0 < min_x {
            min_x = it.x0;
        }
        if it.x1 > max_x {
            max_x = it.x1;
        }

        array_add(*text.vertex_buffer, v0);
        array_add(*text.vertex_buffer, v1);
        array_add(*text.vertex_buffer, v2);
        array_add(*text.vertex_buffer, v3);

        // handle indices
        vert_index : u32 = xx (it_index * 4);
        array_add(*text.indice_buffer, vert_index);
        array_add(*text.indice_buffer, vert_index+1);
        array_add(*text.indice_buffer, vert_index+2);
        array_add(*text.indice_buffer, vert_index+2);
        array_add(*text.indice_buffer, vert_index+3);
        array_add(*text.indice_buffer, vert_index);

        // handle texture. @note Does it make sense to do it for each one?!
        if it.map && it.map.platform_specific.gl_handle {
            e.brush.texture = it.map.platform_specific.gl_handle;
        }
    }

    if e.fill return e.max_size;

    desired_size := make_vector2( max(e.min_size.x, max_x - min_x), max(e.min_size.y, xx text.font.typical_ascender));
    desired_size += make_vector2(e.margin);
    return desired_size;
}

// out line, then inner:
// 0_11____10__9
// |  |     |  |
// 1_12____15__8
// |  |     |  | 
// 2_13____14__7
// |  |     |  |
// 3__4_____5__6
// 16 x vec4 (xy = pos, zw = uv)
ui_sliced_vertex_buffer :: (pos : Vector2, size : Vector2, border : Ui_Border, uv_slice : Ui_Border) -> [64]float {
    vertex_buffer : [64]float;

    vectors : []Vector4;
    vectors.data = cast(*Vector4)vertex_buffer.data;
    vectors.count = 16;

    vectors[0].xy = pos;
    vectors[0].zw = make_vector2(0.0,0.0);

    vectors[1].xy = pos + make_vector2(0.0, border.top);
    vectors[1].zw = make_vector2(0.0,uv_slice.top);

    vectors[2].xy = pos + make_vector2(0, size.y-border.bottom);
    vectors[2].zw = make_vector2(0.0,1.0-uv_slice.bottom);

    vectors[3].xy = pos + make_vector2(0, size.y);
    vectors[3].zw = make_vector2(0.0,1.0);

    vectors[4].xy = pos + make_vector2(border.left, size.y);
    vectors[4].zw = make_vector2(uv_slice.left,1.0);

    vectors[5].xy = pos + make_vector2(size.x-border.right, size.y);
    vectors[5].zw = make_vector2(1.0-uv_slice.right,1.0);

    vectors[6].xy = pos + make_vector2(size.x, size.y);
    vectors[6].zw = make_vector2(1.0,1.0);

    vectors[7].xy = pos + make_vector2(size.x, size.y-border.bottom);
    vectors[7].zw = make_vector2(1.0,1.0-uv_slice.bottom);

    vectors[8].xy = pos + make_vector2(size.x, border.top);
    vectors[8].zw = make_vector2(1.0,uv_slice.top);

    vectors[9].xy = pos + make_vector2(size.x, 0.0);
    vectors[9].zw = make_vector2(1.0,0.0);

    vectors[10].xy = pos + make_vector2(size.x-border.right, 0.0);
    vectors[10].zw = make_vector2(1.0-uv_slice.right,0.0);

    vectors[11].xy = pos + make_vector2(border.left, 0.0);
    vectors[11].zw = make_vector2(uv_slice.left,0.0);

    vectors[12].xy = pos + make_vector2(border.left, border.top);
    vectors[12].zw = make_vector2(uv_slice.left,uv_slice.top);

    vectors[13].xy = pos + make_vector2(border.left, size.y-border.bottom);
    vectors[13].zw = make_vector2(uv_slice.left, 1.0-uv_slice.bottom);

    vectors[14].xy = pos + make_vector2(size.x-border.right, size.y-border.bottom);
    vectors[14].zw = make_vector2(1.0-uv_slice.right, 1.0-uv_slice.bottom);

    vectors[15].xy = pos + make_vector2(size.x-border.right, border.top);
    vectors[15].zw = make_vector2(1.0-uv_slice.right, uv_slice.top);

    return vertex_buffer;
}

ui_sliced_indices :: (vertex_offset : u32) -> [54]u32 {
    indices : [54]u32;
    indices[0] = vertex_offset+0;
    indices[1] = vertex_offset+1;
    indices[2] = vertex_offset+12;
    indices[3] = vertex_offset+12;
    indices[4] = vertex_offset+11;
    indices[5] = vertex_offset+0;

    indices[6] = vertex_offset+1;
    indices[7] = vertex_offset+2;
    indices[8] = vertex_offset+13;
    indices[9] = vertex_offset+13;
    indices[10] = vertex_offset+12;
    indices[11] = vertex_offset+1;

    indices[12] = vertex_offset+2;
    indices[13] = vertex_offset+3;
    indices[14] = vertex_offset+4;
    indices[15] = vertex_offset+4;
    indices[16] = vertex_offset+13;
    indices[17] = vertex_offset+2;

    indices[18] = vertex_offset+13;
    indices[19] = vertex_offset+4;
    indices[20] = vertex_offset+5;
    indices[21] = vertex_offset+5;
    indices[22] = vertex_offset+14;
    indices[23] = vertex_offset+13;

    indices[24] = vertex_offset+14;
    indices[25] = vertex_offset+5;
    indices[26] = vertex_offset+6;
    indices[27] = vertex_offset+6;
    indices[28] = vertex_offset+7;
    indices[29] = vertex_offset+14;

    indices[30] = vertex_offset+15;
    indices[31] = vertex_offset+14;
    indices[32] = vertex_offset+7;
    indices[33] = vertex_offset+7;
    indices[34] = vertex_offset+8;
    indices[35] = vertex_offset+15;
    
    indices[36] = vertex_offset+10;
    indices[37] = vertex_offset+15;
    indices[38] = vertex_offset+8;
    indices[39] = vertex_offset+8;
    indices[40] = vertex_offset+9;
    indices[41] = vertex_offset+10;

    indices[42] = vertex_offset+11;
    indices[43] = vertex_offset+12;
    indices[44] = vertex_offset+15;
    indices[45] = vertex_offset+15;
    indices[46] = vertex_offset+10;
    indices[47] = vertex_offset+11;

    indices[48] = vertex_offset+12;
    indices[49] = vertex_offset+13;
    indices[50] = vertex_offset+14;
    indices[51] = vertex_offset+14;
    indices[52] = vertex_offset+15;
    indices[53] = vertex_offset+12;

    return indices;
}

#scope_file
// copied from Render/Font.jai, but to handle flipped Y-axis

prep_text_flipped :: (font: *Dynamic_Font, x: float, y: float,
              color: Vector4, text: string, effect_flags: Font_Effect_Flags = 0) {

    convert_to_temporary_glyphs(font, text, effect_flags);
    generate_quads_flipped(font, x, y, color, effect_flags);
}

generate_quads_flipped :: (font: *Dynamic_Font,
                   x: float, y: float,
                   color: Vector4, effect_flags: Font_Effect_Flags) {
    
    assert(font != null);
    
    array_reset_keeping_memory(*font.current_quads);
    array_reserve(*font.current_quads, font.temporary_glyphs.count);
    
    maybe_offset := false;
    if font.y_offset_for_my_latin_characters maybe_offset = true;
        
    sx := x;
    sy := y + cast(float)(font.typical_ascender); // handling flipped Y <- top
    
    dirty_pages: [..] *Font_Page;
    defer array_reset(*dirty_pages);
    
    // @Speed!
    for i: 0..font.temporary_glyphs.count-1 {
        info := font.temporary_glyphs[i];
        if !info.page continue;
        map := info.page.map;
        if !map continue;

        if info.page.dirty {
            info.page.dirty = false;
            array_add(*dirty_pages, info.page);
        }


        sx1 := sx  + cast(float) info.offset_x;
        sx2 := sx1 + cast(float) info.width;

        sy2 := sy  - cast(float) info.ascent; // handling flipped Y
        sy1 := sy2 + cast(float) info.height; // handling flipped Y
        
        if maybe_offset && is_latin(info.utf32) {
            // e.g. our Chinese font did not seem to make characters
            // line up properly.
            sy1 += font.y_offset_for_my_latin_characters;
            sy2 += font.y_offset_for_my_latin_characters;
        }

        quad: Font_Quad = ---;
        quad.map = map;
        quad.glyph = info;
        quad.color = color;
        quad.x0 = sx1;
        quad.x1 = sx2;
        quad.y0 = sy1;
        quad.y1 = sy2;

        quad.u0 = info.x0 / cast(float) map.width;
        quad.u1 = (info.x0 + info.width) / cast(float) map.width;
        quad.v0 = info.y0 / cast(float) map.height;
        quad.v1 = (info.y0 + info.height) / cast(float) map.height;

        array_add(*font.current_quads, quad);
		sx += cast(float) info.advance;

    }

    for dirty_pages {
        #if RENDER_OPENGL {
            load_texture_from_bitmap(it.map, it.bitmap_data);
        }
    }
}
