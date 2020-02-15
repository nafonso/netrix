Ui_Clipping :: enum u8 {
    PARENT :: 0;
    SELF;
    NONE;
}

Ui_Element :: struct {
    margin  : float;
    padding : float;

    pos     : Vector2;
    size    : Vector2;

    min_width   : float = 0;
    min_height  : float = 0;
    max_width   : float = FLOAT32_MAX;
    max_height  : float = FLOAT32_MAX;
    
    fill_ratio : float = 1;

    brush : Ui_Brush;

    ui_system : *Ui_System;

    parent : *Ui_Element;
    children : [..] *Ui_Element;
    
    alignment : Ui_Alignment = Ui_Alignment.TOP_LEFT;

    clipping : Ui_Clipping;

    layout_func : (*Ui_Element, Vector2, Ui_Dirty) -> (*Ui_Element);

    on_enter : (*Ui_Element);
//    on_leave : (*Ui_Element);
//    on_click : (*Ui_Element);
//    on_hover : (*Ui_Element); // ?

    // @todo remove the floats when we can just initialize vectors
    #place min_width;
    min_size : Vector2 = ---;
    #place max_width;
    max_size : Vector2 = ---;
}

set_ui_system :: (element : *Ui_Element, ui_system : *Ui_System) {
    element.ui_system = ui_system;
    for element.children {
        set_ui_system(it, ui_system);
    }
}

set_dirty :: (using e : *Ui_Element) {
    if ui_system {
        ui_system.is_dirty = Ui_Dirty.ALL;
    }
}

ui_element :: (layout_func : (*Ui_Element, Vector2, Ui_Dirty) -> (*Ui_Element) = layout_stacking, alignment : Ui_Alignment = Ui_Alignment.TOP_LEFT, margin : float = 0, padding : float = 0) -> Ui_Element {
    ui_element : Ui_Element;
    ui_element.margin = margin;
    ui_element.padding = padding;
    ui_element.alignment = alignment;
    ui_element.layout_func = layout_func;

    return ui_element;
}

add_child :: (parent : *Ui_Element, child : *Ui_Element) {
    assert(parent && child);
    array_add(*parent.children, child);
    child.parent = parent;
    child.ui_system = parent.ui_system;
}

ui_set_text :: ( using e : *Ui_Element, str : string ) {
    assert(brush.type == Ui_Brush_Type.TEXT);
    if brush.text.str_buffer_size < str.count {
        if brush.text.str.data {
            free(brush.text.str.data);
        }
        brush.text.str_buffer_size = str.count;
        brush.text.str.data = alloc(brush.text.str_buffer_size);
    }

    if !equal(str, brush.text.str) {
        memcpy(brush.text.str.data, str.data, str.count);
        brush.text.str.count = str.count;
        set_dirty(e);
    }
}
