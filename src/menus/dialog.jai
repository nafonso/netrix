
dialog_create :: (game : *Game, msg : string, yes : string, yes_func : (*Ui_Button), no : string, no_func : (*Ui_Button)) -> *Ui_Element {
    dialog_root := ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));

    dialog := ui_element_create(game.ui, ui_element(layout_vertical));
    dialog.brush = brush_sliced( get_texture(game.ui, "menus/window.png"), .{8, 8, 35, 8}, .{0.5, 0.5, 0.78, 0.22});
    dialog.padding = 10;
    dialog.max_size = make_vector2(window_width*0.45, 250);

    msg_label := ui_label_create(game.ui, msg, menu_label_font);

    vertical_space := ui_element_create(game.ui, ui_element());

    buttons_container := ui_element_create(game.ui, ui_element(layout_horizontal));

    buttons_container.max_size.y = 40;

    no_button := ui_button_create(game.ui, no, menu_button_font, no_func);

    button_spacer := ui_element_create(game.ui, ui_element());

    yes_button := ui_button_create(game.ui, yes, menu_button_font, yes_func);

    add_child(buttons_container, no_button);
    add_child(buttons_container, button_spacer);
    add_child(buttons_container, yes_button);

    add_child(dialog, msg_label);
    add_child(dialog, vertical_space);
    add_child(dialog, buttons_container);

    add_child(dialog_root, dialog);

    return dialog_root;
}
