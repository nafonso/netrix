#scope_file
root                : *Ui_Element;
vertical_box        : *Ui_Element;
resume_button       : *Ui_Button;
options_button      : *Ui_Button;
quit_to_menu_button : *Ui_Button;
exit_button         : *Ui_Button;
#scope_export

ingame_menu_init :: (game : *Game) {

    root = ui_element_create(game.ui, ui_element(alignment=Ui_Alignment.MID_CENTER));

    background := ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));
    background.brush = brush_stretched( get_ui_texture("white.png") );
    background.brush.tint_color = make_vector4(0, 0, 0, 0.85);
    
    add_child(root, background);

    vertical_box = ui_element_create( game.ui, ui_element(layout_vertical, alignment = Ui_Alignment.MID_CENTER));
    vertical_box.max_size = make_vector2(window_width*0.33, 200);
    vertical_box.padding = 10;

    resume_button = ui_button_create(game.ui, "Resume", menu_button_font, (button : *Ui_Button) {
        ingame_menu_close(false);
    });


    options_button = ui_button_create(game.ui, "Options", menu_button_font, (button : *Ui_Button) {
        options_menu_show(true);
    });

    quit_to_menu_button = ui_button_create(game.ui, "Quit To Menu", menu_button_font, (button : *Ui_Button) {
        show_quit_to_menu_dialog();
    });

    exit_button = ui_button_create( game.ui, "Exit Netrix", menu_button_font, (button : *Ui_Button) {
        print("Exit Netrix\n");
        show_exit_game_dialog();
    });

    add_child(vertical_box, resume_button);
    add_child(vertical_box, options_button);
    add_child(vertical_box, quit_to_menu_button);
    add_child(vertical_box, exit_button);

    add_child(root, vertical_box);

    options_menu_init(game);
}

ingame_menu_open :: () {
    if root.ui_system == null {
        netrix_pause(*game.netrix);
        audio_pause_music(game.audio);
        ui_add_root_element(game.ui, root);
    }
}

ingame_menu_close :: (closing_game : bool) {
    if root.ui_system != null {
        netrix_unpause(*game.netrix);
        ui_remove_root_element(game.ui, root);
        if !closing_game {
            audio_resume_music(game.audio);
        }
    }
}