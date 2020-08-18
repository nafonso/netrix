#scope_file
vertical_box    : *Ui_Element;
sp_game_button : *Ui_Button;
mp_game_button : *Ui_Button;
options_button  : *Ui_Button;
exit_button     : *Ui_Button;
#scope_export

main_menu_init :: (game : *Game) -> *Ui_Element {
    vertical_box = ui_element_create( game.ui, ui_element(layout_vertical, alignment = Ui_Alignment.MID_CENTER));
    vertical_box.max_size = make_vector2(window_width*0.33, 200);
    vertical_box.padding = 10;

    sp_game_button = ui_button_create(game.ui, "Single PLayer Game", menu_button_font, (button : *Ui_Button) {
        start_single_player_game();
    });

    mp_game_button = ui_button_create(game.ui, "Multiplayer Game", menu_button_font, (button : *Ui_Button) {
        print("Multiplayer Game\n");
        multiplayer_menu_open();
    }, true);

    options_button = ui_button_create(game.ui, "Options", menu_button_font, (button : *Ui_Button) {
        options_menu_show(true);
    });

    exit_button = ui_button_create( game.ui, "Exit Netrix", menu_button_font, (button : *Ui_Button) {
        show_exit_game_dialog();
    });

    add_child(vertical_box, sp_game_button);
    add_child(vertical_box, mp_game_button);
    add_child(vertical_box, options_button);
    add_child(vertical_box, exit_button);

    return vertical_box;
}

main_menu_open :: () {
    show_menu(true);
    set_state(main_menu, Ui_Element_State.VISIBLE);
    unset_state(multiplayer_menu, Ui_Element_State.VISIBLE);
}

multiplayer_menu_open :: () {
    show_menu(true);
    unset_state(main_menu, Ui_Element_State.VISIBLE);
    set_state(multiplayer_menu, Ui_Element_State.VISIBLE);
}