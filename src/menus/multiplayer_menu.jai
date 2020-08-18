multiplayer_menu_init :: (game : *Game) -> *Ui_Element{
    multiplayer_panel := ui_element_create(game.ui, ui_element(padding = 10));

    bottom_row := ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.BOT_CENTER));

    bottom_row_container := ui_element_create(game.ui, ui_element(layout_horizontal));
    bottom_row_container.max_size.y = 50;

    horizontal_filler := ui_element_create(game.ui, ui_element());

    back_button := ui_button_create(game.ui, "Back", menu_button_font, (button : *Ui_Button) {
        main_menu_open();
    });
    back_button.max_size.x = 200;

    add_child(bottom_row_container, horizontal_filler);
    add_child(bottom_row_container, back_button);

    add_child(bottom_row, bottom_row_container);
    
    add_child(multiplayer_panel, bottom_row);

    return multiplayer_panel;
}
