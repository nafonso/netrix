#import "Basic";

// #load "graphics.jai";

layout_stacking :: (using element : *Ui_Element) {

    inner_width := max(0.0, size.x-padding-padding);
    inner_height := max(0.0, size.y-padding-padding);

    inner_pos := pos + make_vector2(padding, padding);

    for child : children {
        child_width := min(inner_width, child.max_width);
        child_height := min(inner_height, child.max_height);
        
        child_width = max(0.0, child_width-margin-margin);
        child_height = max(0.0, child_height-margin-margin);

        child.size.x = child_width;
        child.size.y = child_height;

        child.pos = inner_pos;

        using Ui_Alignment;

        if #complete child_alignment == {
            case TOP_LEFT;
            // do nothing
            case TOP_CENTER;
            child.pos.x += (inner_width - child_width)*0.5;
            case TOP_RIGHT;
            child.pos.x += inner_width - child_width;
            case CENTER;
            child.pos.x += (inner_width - child_width)*0.5;
            child.pos.y += (inner_height - child_height)*0.5;
            case BOTTOM_LEFT;
            child.pos.y += inner_height - child_height;
            case BOTTOM_CENTER;
            child.pos.x += (inner_width - child_width)*0.5;
            child.pos.y += inner_height - child_height;
            case BOTTOM_RIGHT;
            child.pos.x += inner_width - child_width;
            child.pos.y += inner_height - child_height;
        } 

        child.mesh.vertices[0] = make_vector3(child.pos.x, child.pos.y + child.size.y, 0);
        child.mesh.vertices[1] = make_vector3(child.pos.x + child.size.x, child.pos.y + child.size.y, 0);
        child.mesh.vertices[2] = make_vector3(child.pos.x + child.size.x, child.pos.y, 0);
        child.mesh.vertices[3] = make_vector3(child.pos.x, child.pos.y, 0);
    }
}

layout_horizontal :: (using element : *Ui_Element) {

}

layout_vertical :: (using element : *Ui_Element) {

}

// Ui_Alignment :: enum_flags u8 {
//     LEFT;
//     CENTER_H;
//     RIGHT;
//     TOP;
//     CENTER_V;
//     BOTTOM;
//     CENTER :: CENTER_H | CENTER_V;
//     TOP_LEFT :: LEFT | TOP;
//     TOP_CENTER :: CENTER_H | TOP;
//     TOP_RIGHT :: RIGHT | TOP;
//     BOTTOM_LEFT :: LEFT | BOTTOM;
//     BOTTOM_CENTER :: CENTER_H | BOTTOM;
//     BOTTOM_RIGHT :: RIGHT | BOTTOM;
// }

Ui_Alignment :: enum u8 {
    TOP_LEFT;
    TOP_CENTER;
    TOP_RIGHT;
    CENTER;
    BOTTOM_LEFT;
    BOTTOM_CENTER;
    BOTTOM_RIGHT;
}

Ui_Element :: struct {
    using mesh : *Static_Mesh;

    margin : float;
    padding : float;

    pos : Vector2;
    size : Vector2;

    min_width : float = 0;
    min_height : float = 0;
    max_width : float = FLOAT32_MAX;
    max_height : float = FLOAT32_MAX;

    union {
        sliced : Ui_Brush_Sliced;
        tiled : Ui_Brush_Tiled;
        stretched : Ui_Brush_Stretched;
    }

    children : [..] *Ui_Element;
    child_alignment : Ui_Alignment = Ui_Alignment.TOP_LEFT;

    layout_func : (*Ui_Element);

    on_enter : (*Ui_Element);
    on_leave : (*Ui_Element);
    on_click : (*Ui_Element);
    on_hover : (*Ui_Element); // ?
}

create_ui_element :: ( mesh : *Static_Mesh, layout_func : (*Ui_Element) = layout_stacking, margin : float = 0, padding : float = 0 ) -> Ui_Element {
    ui_element : Ui_Element;
    ui_element.mesh = mesh;
    ui_element.margin = margin;
    ui_element.padding = padding;
    ui_element.layout_func = layout_func;

    return ui_element;
}

Ui_Brush_Type :: enum u8 {
    NONE; // no render
    SLICED;
    STRETCHED;
    TILED;
}

Ui_Brush :: struct {
    type : Ui_Brush_Type;
    texture : GLuint;
    union {
        sliced : Ui_Brush_Sliced;
        tiled : Ui_Brush_Tiled;
    }
}

Ui_Brush_Sliced :: struct {
    uv_slice : float; // uv border edge
    border : float; // border in pixels
}

Ui_Brush_Tiled :: struct {
    x_repeat : float;
    y_repeat : float;
}

/**
Ui_Brush :: struct {
    type : Ui_Brush_Type;
    // sliced
    uv_slice : float;
    // tiled
    x_repeat : float;
    y_repeat : float;
}

Ui_Brush_Sliced :: struct {
    texture : GLuint;
    uv_slice : float;
}

Ui_Brush_Tiled :: struct {
    texture : GLuint;
    x_repeat : float;
    y_repeat : float;
}

Ui_Brush_Stretched :: struct {
    texture : GLuint;
}

Ui_Mesh :: struct {
    vertices : []Vector2;
    uvs : []Vector2;
}*/

create_sliced_mesh :: () -> Ui_Mesh {
    mesh : Ui_Mesh;
    mesh.vertices = NewArray(4, )
}

create_brush_none :: () -> Ui_Brush {
    brush : Ui_Brush;
    return brush;
}

create_brush_sliced :: ( texture : GLuint = 0, border : float = 10, uv_slice = 0.25 ) {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Tiled.SLICED;
    brush.texture = texture;
    brush.slice.border = border;
    brush.slice.uv_slice = uv_slice;
    return brush;
}

create_brush_stretched :: ( texture : GLuint = 0 ) {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Tiled.STRETCHED;
    brush.texture = texture;
    return brush;
}

create_brush_tiled :: ( texture : GLuint = 0, x_repeat : float = 32, y_repeat : float = 32 ) {
    brush : Ui_Brush = ---;
    brush.type = Ui_Brush_Tiled.TILED;
    brush.texture = texture;
    brush.tiled.x_repeat = x_repeat;
    brush.tiled.y_repeat = y_repeat;
    return brush;
}
