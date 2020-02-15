Ui_Alignment :: enum u8 {
    TOP_LEFT;
    TOP_CENTER;
    TOP_RIGHT;
    LEFT;
    CENTER;
    RIGHT;
    BOTTOM_LEFT;
    BOTTOM_CENTER;
    BOTTOM_RIGHT;
}

Ui_Dirty :: enum_flags u8 {
    LAYOUT;
    SELF;
    INPUT;
    ALL :: 0xff;
}

layout_stacking :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> hovered_element : *Ui_Element  {
    hovered_element : *Ui_Element = null;

    if dirty & Ui_Dirty.INPUT 
     && mouse_pos.x >= pos.x && mouse_pos.x <= pos.x + size.x
     && mouse_pos.y >= pos.y && mouse_pos.y <= pos.y + size.y 
     && (parent != null || brush.type != Ui_Brush_Type.NONE) {
         hovered_element = element;
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
                case LEFT;
                child.pos.y += (inner_height - child_height)*0.5;
                case CENTER;
                child.pos.x += (inner_width - child_width)*0.5;
                child.pos.y += (inner_height - child_height)*0.5;
                case RIGHT;
                child.pos.x += inner_width - child_width;
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
        }

        child_hovered_element := child.layout_func( child, mouse_pos, dirty );
        if child_hovered_element {
            hovered_element = child_hovered_element;
        }
    }

    return hovered_element;
}

layout_horizontal :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> hovered_element : *Ui_Element {
    hovered_element := null;

    return hovered_element;
}

layout_vertical :: (using element : *Ui_Element, mouse_pos : Vector2, dirty : Ui_Dirty) -> hovered_element : *Ui_Element {
    hovered_element := null;

    return hovered_element;
}