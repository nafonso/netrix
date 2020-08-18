#scope_file

root : *Ui_Element;

music_volume : *Ui_Element;
music_volume_down: *Ui_Button;
music_volume_up: *Ui_Button;


sfx_volume : *Ui_Element;
sfx_volume_down : *Ui_Button;
sfx_volume_up : *Ui_Button;

max_volume              : s32 : 10;
current_music_volume    : s32;
current_sfx_volume      : s32;
#scope_export


options_menu_init :: (g : *Game) {
    root = ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));

    options_panel := ui_element_create(game.ui, ui_element());
    options_panel.brush = brush_sliced( get_ui_texture("menus/window.png"), .{8, 8, 35, 8}, .{0.5, 0.5, 0.78, 0.22} );
    options_panel.max_size = make_vector2(window_width*0.33, 250);

    add_child(root, options_panel);

    vertical_box := ui_element_create(game.ui, ui_element(layout_vertical, alignment = Ui_Alignment.MID_CENTER));
    vertical_box.padding = 10;

    options_label := ui_label_create(game.ui, "OPTIONS", menu_button_font);
    options_label.fill = false;
    options_label.max_size.y = 40;

    // music volume

    current_music_volume = cast(s32)(game.audio.music_volume * max_volume);
    
    music_volume_hor_box := ui_element_create(game.ui, ui_element(layout_horizontal));
    music_volume_hor_box.max_size.y = 50;

    music_volume_label := ui_label_create(game.ui, "Music Volume", menu_button_font);
    music_volume_label.margin = 15;
    
    music_volume = ui_label_create(game.ui, sprint("%", current_music_volume), menu_button_font);
    music_volume.margin = 15;
    music_volume.max_size.x = 60;
    music_volume_down = ui_button_create(game.ui, "-", menu_button_font, (button : *Ui_Button) {
        if current_music_volume > 0 {
            current_music_volume -= 1;
            ui_set_text(music_volume, sprint("%", current_music_volume));
            audio_set_music_volume(game.audio, cast(float)current_music_volume / max_volume);
        }
    });
    music_volume_down.max_size.x = 50;
    music_volume_up = ui_button_create(game.ui, "+", menu_button_font, (button : *Ui_Button) {
        if current_music_volume < max_volume {
            current_music_volume += 1;
            ui_set_text(music_volume, sprint("%", current_music_volume));
            audio_set_music_volume(game.audio, cast(float)current_music_volume / max_volume);
        }
    });
    music_volume_up.max_size.x = 50;

    add_child(music_volume_hor_box, music_volume_label);
    add_child(music_volume_hor_box, music_volume);
    add_child(music_volume_hor_box, music_volume_down);
    add_child(music_volume_hor_box, music_volume_up);

    // sfx volume

    current_sfx_volume = cast(s32)(game.audio.sfx_volume*max_volume);

    sfx_volume_hor_box := ui_element_create(game.ui, ui_element(layout_horizontal));
    sfx_volume_hor_box.max_size.y = 50;

    sfx_volume_label := ui_label_create(game.ui, "Sfx Volume", menu_button_font);
    sfx_volume_label.margin = 15;
    
    sfx_volume = ui_label_create(game.ui, sprint("%", current_sfx_volume), menu_button_font);
    sfx_volume.margin = 15;
    sfx_volume.max_size.x = 60;
    sfx_volume_down = ui_button_create(game.ui, "-", menu_button_font, (button : *Ui_Button) {
        if current_sfx_volume > 0 {
            current_sfx_volume -= 1;
            ui_set_text(sfx_volume, sprint("%", current_sfx_volume));
            audio_set_sfx_volume(game.audio, cast(float)current_sfx_volume / max_volume);
        }
    });
    sfx_volume_down.max_size.x = 50;
    sfx_volume_up = ui_button_create(game.ui, "+", menu_button_font, (button : *Ui_Button) {
        if current_sfx_volume < max_volume {
            current_sfx_volume += 1;
            ui_set_text(sfx_volume, sprint("%", current_sfx_volume));
            audio_set_sfx_volume(game.audio, cast(float)current_sfx_volume / max_volume);
        }
    });
    sfx_volume_up.max_size.x = 50;

    back_button := ui_button_create(game.ui, "Back", menu_button_font, (button : *Ui_Button){
        options_menu_show(false);
    });
    back_button.min_size.y = 50;

    add_child(sfx_volume_hor_box, sfx_volume_label);
    add_child(sfx_volume_hor_box, sfx_volume);
    add_child(sfx_volume_hor_box, sfx_volume_down);
    add_child(sfx_volume_hor_box, sfx_volume_up);

    add_child(vertical_box, options_label);
    add_child(vertical_box, music_volume_hor_box);
    add_child(vertical_box, sfx_volume_hor_box);
    add_child(vertical_box, ui_flexible_space_create(game.ui));
    add_child(vertical_box, back_button);

    add_child(options_panel, vertical_box);
}


options_menu_show :: (show : bool) {
    if show {
        ui_add_root_element(game.ui, root);
    }
    else {
        ui_remove_root_element(game.ui, root);
    }
}
