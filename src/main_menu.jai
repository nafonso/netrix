root        : Ui_Element;
background  : Ui_Element;
quit_button : Ui_Element;
quit_button_text : Ui_Element;

init_main_menu :: (game : *Game) { 
    root = ui_element(alignment = Ui_Alignment.CENTER);

    background = ui_element(alignment = Ui_Alignment.CENTER);
    background.brush = brush_stretched( get_ui_texture("logo.png") );

    add_child(*root, *background);

    quit_button = ui_element(alignment = Ui_Alignment.CENTER);
    quit_button.max_size = make_vector2(window_width*0.25, 30);
    quit_button.brush = brush_sliced( get_ui_texture("menus/button_active.png"), 3 );
    
    quit_button_text = ui_element();
    quit_button_text.brush = brush_text("Quit", get_font(game.fm, "KarminaBoldItalic.otf", 32));
    add_child(*quit_button, *quit_button_text);

    add_child(*root, *quit_button);
}

show_main_menu :: (game : *Game, show : bool) {
    if show {
        if !root.ui_system {
            add_root_element(game.ui, *root);
        }
    }
    else if root.ui_system {
        remove_root_element(game.ui, *root);
    }
}
