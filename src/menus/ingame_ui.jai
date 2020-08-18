
ingame_ui_header_font : *Dynamic_Font;
ingame_ui_label_font : *Dynamic_Font;

#scope_file
sidebar_root : *Ui_Element;

score_label         : *Ui_Element;
num_lines_label     : *Ui_Element;
next_block_label    : *Ui_Element;

score_value     : int;
num_lines_value : int;

next_block_value : Netrix_Block_Type;

game_over_root  : *Ui_Element;
game_over_label : *Ui_Element;

#scope_export

ingame_ui_init :: (game : *Game) {

    ingame_ui_header_font = get_font(game.ui, "JetBrainsMono-Regular.ttf", 32);
    ingame_ui_label_font = get_font(game.ui, "JetBrainsMono-Regular.ttf", 24);

    sidebar_root = ui_element_create(game.ui, ui_element());

    sidebar_root.pos = make_vector2(window_width * 0.5 + game.netrix.board.world_size.x * 0.5 + 10, window_height - (game.netrix.board.world_pos.y + game.netrix.board.world_size.y));

    vertical_box := ui_vertical_box_create(game.ui, Ui_Alignment.TOP_LEFT);
    
    // score 
    score_header_label := ui_label_create(game.ui, "SCORE", ingame_ui_header_font);
    score_header_label.fill = false;
    score_label = ui_label_create(game.ui, "0", ingame_ui_label_font);
    score_label.fill = false;

    score_box := create_box(game, score_header_label, score_label);

    // number of lines
    num_lines_header_label := ui_label_create(game.ui, "LINES", ingame_ui_header_font);
    num_lines_header_label.fill = false;
    num_lines_label = ui_label_create(game.ui, "0", ingame_ui_label_font);
    num_lines_label.fill = false;

    num_lines_box := create_box(game, num_lines_header_label, num_lines_label);

    // next block
    next_block_header_label := ui_label_create(game.ui, "NEXT", ingame_ui_header_font);
    next_block_header_label.fill = false;

    next_block_label = ui_element_create(game.ui, ui_element());
    next_block_label.brush = brush_stretched(0);
    next_block_label.max_size = make_vector2(80, 40);
    next_block_label.min_size = next_block_label.max_size;

    next_block_box := create_box(game, next_block_header_label, next_block_label, 125);

    add_child(vertical_box, score_box);
    add_child(vertical_box, ui_fixed_space_create(game.ui, 10));
    add_child(vertical_box, num_lines_box);
    add_child(vertical_box, ui_fixed_space_create(game.ui, 10));
    add_child(vertical_box, next_block_box);

    add_child(sidebar_root, vertical_box);

    game_over_root = ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.MID_CENTER));
    game_over_label = ui_label_create(game.ui, "GAME OVER", ingame_ui_header_font);
    game_over_label.fill = false;
    game_over_label.min_size.y = 50;

     add_child(game_over_root, game_over_label);
}

#scope_file

create_box :: (game : *Game, header : *Ui_Element, content : *Ui_Element, height : float = 100) -> *Ui_Element {
    box := ui_element_create(game.ui, ui_element(layout_vertical, alignment = Ui_Alignment.TOP_CENTER));
    box.brush = brush_sliced(get_ui_texture("puzzle_area_selected.png"), 5, 0.45);
    box.max_size = make_vector2(150, height);

    add_child(box, ui_fixed_space_create(game.ui, 25));
    add_child(box, header);
    add_child(box, ui_flexible_space_create(game.ui));
    if content {
        add_child(box, content);
    }
    add_child(box, ui_flexible_space_create(game.ui));

    return box;
}

#scope_export

ingame_ui_show :: (show : bool) {
    if sidebar_root == null {
        return;
    }
    if show {
        if sidebar_root.ui_system == null {
            ui_add_root_element(game.ui, sidebar_root);
        }
    }
    else {
        if sidebar_root.ui_system != null {
            ui_remove_root_element(game.ui, sidebar_root);
        }
    }
}

ingame_ui_update :: (netrix : *Netrix) {
    if score_value != netrix.score {
        score_value = netrix.score;
        ui_set_text(score_label, tprint("%", score_value));
    }
    if num_lines_value != netrix.num_lines {
        num_lines_value = netrix.num_lines;
        ui_set_text(num_lines_label, tprint("%", num_lines_value));
    }
    if next_block_value != netrix.next_block_type {
        next_block_value = netrix.next_block_type;
        next_block_label.brush.texture = netrix.board.next_block_textures[next_block_value];
    }

    if netrix.state == {
        case .GAME_OVER_IDLE;
        if game_over_root.ui_system == null {
            ui_add_root_element(game.ui, game_over_root);
        }

        case;
        if game_over_root && game_over_root.ui_system != null {
            ui_remove_root_element(game.ui, game_over_root);
        }
    }
}