#import "Render"; // for Dynamic_Font

menu_button_font : *Dynamic_Font;
menu_label_font : *Dynamic_Font;

main_menu : *Ui_Element;
multiplayer_menu : *Ui_Element;

#scope_file

game_cached : *Game;

root : *Ui_Element;
background : *Ui_Element;

#load "options_menu.jai";
#load "main_menu.jai";
#load "multiplayer_menu.jai";
#load "dialog.jai";

#scope_export



menu_init :: (game : *Game) {

    game_cached = game;

    menu_button_font = get_font(game.ui, "JetBrainsMono-Regular.ttf", 24);
    menu_label_font = get_font(game.ui, "JetBrainsMono-Regular.ttf", 24);
    
    root = ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));

    background = ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));
    background.brush = brush_stretched( get_ui_texture("logo.png") );

    add_child(root, background);

    main_menu = main_menu_init(game);
    multiplayer_menu = multiplayer_menu_init(game);

    add_child(root, main_menu);
    add_child(root, multiplayer_menu);
}

show_menu :: (show : bool) {
    if show {
        if !is_root(root) {
            ui_add_root_element(game.ui, root);
        }
    } else{
        if is_root(root) {
            ui_remove_root_element(game.ui, root);
        }
    }
}

menu_deinit :: (game : *Game) {
    ui_remove_root_element(game.ui, root);
}

show_exit_game_dialog :: () {

    exit_game_func :: (button : *Ui_Button) {
        exit_game = true;
    };

    cancel_func :: (button : *Ui_Button) {
        parent := button.parent;
        while parent.parent {
            parent = parent.parent;
        }

        ui_remove_root_element(game.ui, parent);
        ui_element_destroy(game.ui, parent);
    };

    exit_dialog := dialog_create(game, "Are you sure you want to exit Netrix?", "Exit", exit_game_func, "Cancel", cancel_func);
    ui_add_root_element(game.ui, exit_dialog);
}


show_quit_to_menu_dialog :: () {
    quit_to_menu_func :: (button : *Ui_Button) {
        ingame_menu_close(true);

        main_menu_load();

        parent := button.parent;
        while parent.parent {
            parent = parent.parent;
        }

        ui_remove_root_element(game.ui, parent);
        ui_element_destroy(game.ui, parent);
    };

    cancel_func :: (button : *Ui_Button) {
        parent := button.parent;
        while parent.parent {
            parent = parent.parent;
        }

        ui_remove_root_element(game.ui, parent);
        ui_element_destroy(game.ui, parent);
    };

    quit_dialog := dialog_create(game, "Are you sure you want to quit to menu?", "Quit To Menu", quit_to_menu_func, "Cancel", cancel_func);
    ui_add_root_element(game.ui, quit_dialog);
}