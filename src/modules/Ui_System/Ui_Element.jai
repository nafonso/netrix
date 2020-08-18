Ui_Clipping :: enum u8 {
    PARENT :: 0;
    SELF;
    NONE;
}

Ui_Element_State :: enum_flags u8 {
    VISIBLE;    // is it visible, if it isn't visible all layout / rendering will be skipped (including children)
    DISABLED;   // doesn't react to input
    HOVERED;    // mouse is inside this element
    SELECTED;   // when the item has selection (ie leaf hovered)
    ACTIVE;     // it has input, e.g. button being pressed, text field with keyboard focus
}

Ui_Element :: struct {
    // calculated on layout
    pos     : Vector2;
    size    : Vector2;

    // runtime state
    state : Ui_Element_State = Ui_Element_State.VISIBLE;

    // properties
    margin  : float;
    padding : float;

    min_width   : float = 0;
    min_height  : float = 0;
    max_width   : float = FLOAT32_MAX;
    max_height  : float = FLOAT32_MAX;
    
    fill : bool = true;
    fill_ratio : float = 1;

    brush : Ui_Brush;

    ui_system : *Ui_System;

    parent : *Ui_Element;
    children : [..] *Ui_Element;
    
    alignment : Ui_Alignment = Ui_Alignment.TOP_LEFT;

    clipping : Ui_Clipping;

    layout_func : (*Ui_Element, Vector2, Ui_Dirty) -> (*Ui_Element);

    handle_event : (*Ui_Element, *Ui_Event);

    on_state_changed : (*Ui_Element, Ui_Element_State);

    // @todo remove the floats when we can just initialize vectors
    #place min_width;
    min_size : Vector2 = ---;
    #place max_width;
    max_size : Vector2 = ---;
}

set_ui_system :: (element : *Ui_Element, ui_system : *Ui_System) {

    set_ui_system_recursive :: (e : *Ui_Element, ui_system : *Ui_System) {
        e.ui_system = ui_system;
        for e.children {
            set_ui_system_recursive(it, ui_system);
        }
    }

    if element.ui_system 
        ui_set_dirty(element.ui_system);
    if ui_system 
        ui_set_dirty(ui_system);

    set_ui_system_recursive(element, ui_system);
}

ui_set_dirty :: (using e : *Ui_Element) {
    if ui_system {
        ui_set_dirty(ui_system);
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
    set_ui_system(child, parent.ui_system);
}

remove_child :: (parent : *Ui_Element, child : *Ui_Element) {
    assert(parent && child && child.parent == parent);
    array_ordered_remove_by_value(*parent.children, child);
    child.parent = null;
    set_ui_system(child, null);
}


ui_set_text :: (using e : *Ui_Element, str : string) {
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
        ui_set_dirty(e);
    }
}

is_root :: (using e : *Ui_Element) -> bool {
    return ui_system && !parent;
}

set_state :: (using e : *Ui_Element, state_flag : Ui_Element_State) {
    state |= state_flag;
    if state_flag & Ui_Element_State.VISIBLE != 0 {
        ui_set_dirty(e);
    }
}

unset_state :: (using e : *Ui_Element, state_flag : Ui_Element_State) {
    state &= ~state_flag;
    if state_flag & Ui_Element_State.VISIBLE != 0 {
        ui_set_dirty(e);
    }
}

has_state :: (using e : *Ui_Element, state_flag : Ui_Element_State) -> bool {
    return state & state_flag != 0;
}

Ui_Button :: struct {
    using element : Ui_Element;

    disabled_texture    : GLuint;
    normal_texture      : GLuint;
    hovered_texture     : GLuint;
    active_texture      : GLuint;

    on_clicked : (*Ui_Button);
}

ui_button :: (ui : *Ui_System, on_clicked_callback : (*Ui_Button), disabled : bool = false) -> Ui_Button {
    button : Ui_Button;
    button.on_clicked = on_clicked_callback;

    button.disabled_texture = get_texture(ui, "menus/button_active.png");
    button.normal_texture = get_texture(ui, "menus/button_on.png");
    button.hovered_texture = get_texture(ui, "menus/button_hover.png");
    button.active_texture = get_texture(ui, "menus/button_active.png");

    button.element = ui_element(alignment = Ui_Alignment.MID_CENTER);

    default_texture := button.normal_texture;

    if disabled {
        set_state(*button, Ui_Element_State.DISABLED);
        default_texture = button.disabled_texture;
    }

    button.brush = brush_sliced( default_texture, 3);

    button.on_state_changed = (e : *Ui_Element, previous_state : Ui_Element_State) {
        b := cast(*Ui_Button)e;
        if b.state & Ui_Element_State.DISABLED {
            b.brush.texture = b.disabled_texture;
        }
        else if b.state & Ui_Element_State.SELECTED {
            if b.state & Ui_Element_State.ACTIVE {
                b.brush.texture = b.active_texture;
            }
            else {
                b.brush.texture = b.hovered_texture;
            }
        }
        else {
            b.brush.texture = b.normal_texture;
        }
    };
        
    button.handle_event = (e : *Ui_Element, evt : *Ui_Event) {
        button_cast := cast(*Ui_Button)e;
        if evt.type == {
            case Ui_Event_Type.BUTTON_DOWN;
            set_state(button_cast, Ui_Element_State.ACTIVE);
            evt.used = true;
            
            case Ui_Event_Type.BUTTON_UP;
            // only click if it's hovered, letting go outside ignores button press
            if (button_cast.state & Ui_Element_State.HOVERED) && button_cast.on_clicked {
                button_cast.on_clicked(button_cast);
            }
            unset_state(button_cast, Ui_Element_State.ACTIVE); // remove ACTIVE
            evt.used = true;
        }
    };

    return button;
}
