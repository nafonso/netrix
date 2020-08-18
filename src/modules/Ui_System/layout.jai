Ui_Alignment :: enum u8 {
    TOP_LEFT;
    TOP_CENTER;
    TOP_RIGHT;
    MID_LEFT;
    MID_CENTER;
    MID_RIGHT;
    BOT_LEFT;
    BOT_CENTER;
    BOT_RIGHT;
}

Ui_Dirty :: enum_flags u8 {
    LAYOUT;
    SELF;
    INPUT;
    ALL :: 0xff;
}

layout_stacking :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> selected_element : *Ui_Element  {
    selected_element : *Ui_Element = null;

    if state & Ui_Element_State.VISIBLE == 0 {
        return null;
    }

    previous_state := state;

    if dirty & Ui_Dirty.INPUT {
        if mouse_pos.x >= pos.x && mouse_pos.x <= pos.x + size.x
            && mouse_pos.y >= pos.y && mouse_pos.y <= pos.y + size.y 
            && (parent != null || brush.type != Ui_Brush_Type.NONE) {

            state |= Ui_Element_State.HOVERED;

            // NONE and TEXT cannot be selected.. maybe change it to setting later?
            if brush.type != Ui_Brush_Type.TEXT && brush.type != Ui_Brush_Type.TEXT {
                selected_element = element;
            }
        }
        else {
            state &= ~Ui_Element_State.HOVERED;
        }
     }

    inner_width  : float = ---;
    inner_height : float = ---;
    inner_pos    : Vector2 = ---;

    rebuild := dirty & Ui_Dirty.LAYOUT;

    if rebuild {
        inner_width = max(0.0, size.x-padding-padding);
        inner_height = max(0.0, size.y-padding-padding);
        inner_pos = pos + make_vector2(padding, padding);
    }

    for child : children {
        if rebuild {
            child_margin := child.margin + child.margin;
            child_desired_size := child.brush.calc_desired_size(child);

            child_width := min(inner_width, child_desired_size.x);
            child_height := min(inner_height, child_desired_size.y);
            
            child_width = max(0.0, child_width-child_margin);
            child_height = max(0.0, child_height-child_margin);

            child.size.x = child_width;
            child.size.y = child_height;

            child.pos = inner_pos;

            using Ui_Alignment;

            if #complete alignment == {
                case TOP_LEFT;
                // do nothing
                case TOP_CENTER;
                child.pos.x += (inner_width - child_width)*0.5;
                case TOP_RIGHT;
                child.pos.x += inner_width - child_width;
                case MID_LEFT;
                child.pos.y += (inner_height - child_height)*0.5;
                case MID_CENTER;
                child.pos.x += (inner_width - child_width)*0.5;
                child.pos.y += (inner_height - child_height)*0.5;
                case MID_RIGHT;
                child.pos.x += inner_width - child_width;
                child.pos.y += (inner_height - child_height)*0.5;
                case BOT_LEFT;
                child.pos.y += inner_height - child_height;
                case BOT_CENTER;
                child.pos.x += (inner_width - child_width)*0.5;
                child.pos.y += inner_height - child_height;
                case BOT_RIGHT;
                child.pos.x += inner_width - child_width;
                child.pos.y += inner_height - child_height;
            }
        }

        child_hovered_element := child.layout_func( child, mouse_pos, dirty );
        if child_hovered_element {
            selected_element = child_hovered_element;
        }
    }

    if previous_state != state && element.on_state_changed {
        element.on_state_changed(element, previous_state);
    }

    return selected_element;
}

layout_vertical :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> selected_element : *Ui_Element {
    selected_element : *Ui_Element = null;

    if state & Ui_Element_State.VISIBLE == 0 {
        return selected_element;
    }

    previous_state := state;

    if dirty & Ui_Dirty.INPUT {
        if mouse_pos.x >= pos.x && mouse_pos.x <= pos.x + size.x
            && mouse_pos.y >= pos.y && mouse_pos.y <= pos.y + size.y 
            && (parent != null || brush.type != Ui_Brush_Type.NONE) {

            selected_element = element;
            state |= Ui_Element_State.HOVERED;
        }
        else {
            state &= ~Ui_Element_State.HOVERED;
        }
     }

    inner_width  : float = ---;
    inner_height : float = ---;
    inner_height_left : float = ---;
    inner_pos    : Vector2 = ---;

    total_fill_ratio : float = ---;
    total_min_height : float = ---;
    inner_height_after_min : float = ---;

    rebuild := dirty & Ui_Dirty.LAYOUT;

    if rebuild {
        inner_width = max(0.0, size.x-padding-padding);
        inner_height = max(0.0, size.y-padding-padding);
        inner_pos = pos + make_vector2(padding, padding);
        inner_height_left = inner_height;

        total_fill_ratio = 0.0;
        total_min_height = 0.0;
    
        // first we need to know how much is the total fill ratio and
        // the total min height, so we need to go over all of them
        for child : children {
            total_fill_ratio += child.fill_ratio;
            total_min_height += child.min_size.y;
            inner_height_after_min = max(0.0, inner_height - total_min_height);
        }

        using Ui_Alignment;

        for child : children {
            child_margin := child.margin + child.margin;
            child_min_size := child.min_size;
            
            child_desired_size := child.brush.calc_desired_size(child);

            child_width := min(inner_width, child_desired_size.x);
            child_width = max(0.0, child_width-child_margin);

            child_ratio_height := inner_height_after_min * (child.fill_ratio / total_fill_ratio);

            child_height := min(inner_height_left,max(child_min_size.y, child_ratio_height));

            if child_height > child.max_size.y {
                child_height = child.max_size.y;
                total_fill_ratio -= child.fill_ratio;
            }
            
            child.size.x = child_width;
            child.size.y = child_height;

            child.pos = inner_pos;

            inner_pos.y += child.size.y;
            inner_height_left -= child.size.y;

            if alignment == {
                case TOP_CENTER; #through;
                case BOT_CENTER; #through;
                case MID_CENTER;
                child.pos.x = inner_pos.x + inner_width * 0.5 - child.size.x * 0.5;
                case TOP_RIGHT; #through;
                case BOT_RIGHT; #through;
                case MID_RIGHT;
                child.pos.x = inner_pos.x + inner_width - child.size.x;
            }
        }

        while inner_height_left > 0.1 {
            total_child_extra_height := 0.0;
            for child : children {
                child.pos.y += total_child_extra_height;
                // can still add height?
                if child.size.y + 0.1 < child.max_size.y {
                    child_extra_height := inner_height_left * (child.fill_ratio / total_fill_ratio);
                    child_height := child.size.y + child_extra_height;
                    if child_height > child.max_size.y {
                        child_extra_height = child.max_size.y - child.size.y;
                        child_height = child.max_size.y;
                    }
                    child.size.y = child_height;
                    total_child_extra_height += child_extra_height;
                    inner_height_left -= child_extra_height;
                }
            }

            if total_child_extra_height == 0.0 { // no children took extra space, we're done!
                break;
            }
        }
    }

    // we need to do a pass in the end because only at this point their pos and size are final
    for child : children {
        child_hovered_element := child.layout_func( child, mouse_pos, dirty );
        if child_hovered_element {
            selected_element = child_hovered_element;
        }
    }

    if previous_state != state && element.on_state_changed {
        element.on_state_changed(element, previous_state);
    }

    return selected_element;
}

// horizontal is rework of vertical one, just flipping axis
layout_horizontal :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> selected_element : *Ui_Element {
    selected_element : *Ui_Element = null;

    if state & Ui_Element_State.VISIBLE == 0 {
        return selected_element;
    }

    previous_state := state;

    if dirty & Ui_Dirty.INPUT {
        if mouse_pos.x >= pos.x && mouse_pos.x <= pos.x + size.x
            && mouse_pos.y >= pos.y && mouse_pos.y <= pos.y + size.y 
            && (parent != null || brush.type != Ui_Brush_Type.NONE) {

            selected_element = element;
            state |= Ui_Element_State.HOVERED;
        }
        else {
            state &= ~Ui_Element_State.HOVERED;
        }
     }

    inner_width  : float = ---;
    inner_height : float = ---;
    inner_pos    : Vector2 = ---;

    inner_width_left : float = ---;
    total_fill_ratio : float = ---;
    total_min_width : float = ---;
    inner_width_after_min : float = ---;

    rebuild := dirty & Ui_Dirty.LAYOUT;

    if rebuild {
        inner_width = max(0.0, size.x-padding-padding);
        inner_height = max(0.0, size.y-padding-padding);
        inner_pos = pos + make_vector2(padding, padding);
        
        inner_width_left = inner_width;

        total_fill_ratio = 0.0;
        total_min_width = 0.0;
    
        // first we need to know how much is the total fill ratio and
        // the total min height, so we need to go over all of them
        for child : children {
            total_fill_ratio += child.fill_ratio;
            total_min_width += child.min_size.x;
        }

        // this will be used to determine the child ratio width
        inner_width_after_min = max(0.0, inner_width - total_min_width);

        using Ui_Alignment;

        for child : children {
            child_margin := child.margin + child.margin;
            child_min_size := child.min_size;
            
            child_desired_size := child.brush.calc_desired_size(child);

            child_height := min(inner_height, child_desired_size.y);
            child_height = max(0.0, child_height-child_margin);

            child_ratio_width := inner_width_after_min * (child.fill_ratio / total_fill_ratio);

            child_width := min(inner_width_left,max(child_min_size.x, child_ratio_width));

            if child_width > child.max_size.x {
                child_width = child.max_size.x;
                total_fill_ratio -= child.fill_ratio;
            }
            
            child.size.x = child_width;
            child.size.y = child_height;

            child.pos = inner_pos;

            inner_pos.x += child.size.x;
            inner_width_left -= child.size.x;

            if alignment == {
                case MID_LEFT;  #through;
                case MID_RIGHT; #through;
                case MID_CENTER;
                child.pos.y = inner_pos.y + inner_height * 0.5 - child.size.y * 0.5;
                case BOT_LEFT;  #through;
                case BOT_RIGHT; #through;
                case BOT_CENTER;
                child.pos.y = inner_pos.y + inner_height - child.size.y;
            }
        }

        while inner_width_left > 0.1 {
            total_child_extra_width := 0.0;
            for child : children {
                child.pos.x += total_child_extra_width;
                // can still add height?
                if child.size.x + 0.1 < child.max_size.x {
                    child_extra_width := inner_width_left * (child.fill_ratio / total_fill_ratio);
                    child_width := child.size.x + child_extra_width;
                    if child_width > child.max_size.x {
                        child_extra_width = child.max_size.x - child.size.x;
                        child_width = child.max_size.x;
                    }
                    child.size.x = child_width;
                    total_child_extra_width += child_extra_width;
                    inner_width_left -= child_extra_width;
                }
            }

            if total_child_extra_width == 0.0 { // no children took extra space, we're done!
                break;
            }
        }
    }

    // we need to do a pass in the end because only at this point their pos and size are final
    for child : children {
        child_hovered_element := child.layout_func( child, mouse_pos, dirty );
        if child_hovered_element {
            selected_element = child_hovered_element;
        }
    }

    if previous_state != state && element.on_state_changed {
        element.on_state_changed(element, previous_state);
    }

    return selected_element;
}
