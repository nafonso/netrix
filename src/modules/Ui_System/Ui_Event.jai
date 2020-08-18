Ui_Event :: struct {
    type : Ui_Event_Type;
    used : bool;
    union {
        pointer_move  : Ui_Pointer_Move_Event;
        button        : Ui_Button_Event;
    }
} 

Ui_Event_Type :: enum {
    POINTER_MOVE;
    BUTTON_DOWN;
    BUTTON_UP;
    SELECTION;
}

Ui_Pointer_Move_Event :: struct {
    pos     : Vector2; // absolute position
    delta   : Vector2; // delta movement
}

Ui_Button_Event :: struct {
    id          : u8;
    num_clicks  : u8;
}

Ui_Selection_Event :: struct {
    dir : Vector2;
}