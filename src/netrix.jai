#import "Random";

#load "menus/ingame_menu.jai";
#load "menus/ingame_ui.jai";

MIN_LEVEL :: 1;
MAX_LEVEL :: 20;

GRAVITY_MIN_SPEED :: 1.0;
GRAVITY_MAX_SPEED :: 15.0;

SCORE_PER_LINE :: 100;

GAME_OVER_FILL_SPEED :: 1.0 / 10;

Netrix_State :: enum u8 {
    NOT_RUNNING :: 0;
    LOADING;
    SPAWNING;
    RUNNING;
    CLEARING_LINES;
    GAME_OVER_START;
    GAME_OVER_IDLE;
}

Netrix_Input :: struct {
    move_direction   : Move_Direction;
    move_time_accum  : float;
    move_counter     : int;
    rotate_direction : Rotate_Direction;
}

Netrix_Input_Actions :: struct {
    ok      : bool;
    cancel  : bool;
}

Netrix_Sfx :: struct {
    move_block      : *Sfx;
    place_block     : *Sfx;
    rotate_left     : *Sfx;
    rotate_right    : *Sfx;
    lines_complete  : *Sfx;
    game_over       : *Sfx;
}

Netrix :: struct {
    state       : Netrix_State;
    state_timer : float;

    board       : Board;
    level       : int;
    score       : int;
    num_lines   : int;

    next_block_type : Netrix_Block_Type;

    current_block : Netrix_Block;
    next_gravity_time : float;

    // input / control
    input : Netrix_Input;
    input_actions : Netrix_Input_Actions;

    sfxs : Netrix_Sfx;
}

netrix_init :: (using netrix : *Netrix) {
    board_init(*board);

    netrix_set_state(netrix, .NOT_RUNNING);

    audio_load_music(game.audio, "tetrisb.mp3");

    sfxs.move_block = audio_load_sfx(game.audio, "move_block.wav");
    sfxs.place_block = audio_load_sfx(game.audio, "place_block.wav");
    sfxs.rotate_left = audio_load_sfx(game.audio, "rotate_left.wav");
    sfxs.rotate_right = audio_load_sfx(game.audio, "rotate_right.wav");
    sfxs.lines_complete = audio_load_sfx(game.audio, "lines_complete.wav");
    sfxs.game_over   = audio_load_sfx(game.audio, "game_over.wav");
}

netrix_set_state :: (using netrix : *Netrix, new_state : Netrix_State ) {

    update_next_block_type :: (using netrix : *Netrix) {
        next_block_type = cast(Netrix_Block_Type) ((random_get() % cast(u32)Netrix_Block_Type.Z) + 1);
    }

    state = new_state;
    state_timer = 0.0;

    if #complete state == {
        case .NOT_RUNNING;
        ingame_ui_show(false);
        
        for col : 0..board.width-1 {
            for row : 0..board.height-1 {
                if board.grid[col][row] {
                    block_destroy(*board, board.grid[col][row]);
                    board.grid[col][row] = null;
                }
            }
        }

        if current_block.type != .INVALID {
            netrix_block_destroy(*current_block);
        }

        case .LOADING;
        score = 0;
        level = MIN_LEVEL;
        num_lines = 0;

        ingame_ui_show(true);

        update_next_block_type(netrix);

        netrix_set_state(netrix, .SPAWNING);

        audio_play_music(game.audio, 200);

        netrix_clear_move_input(netrix);

        input_actions = .{};

        case .SPAWNING;

        netrix_set_current_block(netrix, netrix_block_create(next_block_type, board.block_size));
        current_block.grid_pos = grid_spawn_pos(*board);

        update_next_block_type(netrix);

        if add_block(*board, *current_block) {
            netrix_set_state(netrix, .RUNNING);
        }
        else {
            netrix_set_state(netrix, .GAME_OVER_START);
        }
        
        case .RUNNING;
        next_gravity_time = game.time + 1.0 / netrix_get_speed(level);
        
        case .CLEARING_LINES;
        
        case .GAME_OVER_START;

        next_gravity_time = game.time + GAME_OVER_FILL_SPEED;

        audio_stop_music(game.audio, 200);

        audio_play_sfx(game.audio, sfxs.game_over);

        case .GAME_OVER_IDLE;

    }

    ingame_ui_update(netrix);
}

netrix_set_current_block :: (using netrix : *Netrix, netrix_block : Netrix_Block) {
    assert(current_block.type == .INVALID);

    current_block = netrix_block;
}

netrix_get_speed :: (level : int) -> float {
    assert(level >= MIN_LEVEL && level <= MAX_LEVEL);

    t : float = cast(float)(level-MIN_LEVEL) / (MAX_LEVEL-MIN_LEVEL);

    return GRAVITY_MIN_SPEED + (GRAVITY_MAX_SPEED - GRAVITY_MIN_SPEED)*t;
}

netrix_tick :: (using netrix : *Netrix) {

    if state == .NOT_RUNNING {
        input_actions = .{};
        return;
    }

    state_timer += game.delta_time;

    if state == {
        case .RUNNING;
        if netrix.input_actions.cancel {
            if game.time_dilation > 0 {
                ingame_menu_open();
            }
        }

        if game.time_dilation > 0 {
            if current_block.type != .INVALID {
                // handle gravity
                while game.time >= next_gravity_time {
                    next_gravity_time += 1.0 / netrix_get_speed(level);
                    handle_move_current_block(netrix, .DOWN);
                }

                // handle input
                if input.move_direction != .NONE {
                    if input.move_direction == .UP { // auto place
                        netrix_clear_move_input(netrix);
                        while handle_move_current_block(netrix, .DOWN) {
                            ;
                        }
                    }
                    else {
                        input.move_time_accum -= game.delta_time;
                        while input.move_time_accum <= 0 {
                            handle_move_current_block(netrix, input.move_direction);
                            input.move_time_accum += netrix_get_input_move_speed(input.move_counter);
                            input.move_counter += 1;
                        }
                    }
                }

                if input.rotate_direction != .NONE {
                    rotate_right := ifx input.rotate_direction == .RIGHT then true else false;

                    if rotate_block(*board, *current_block, rotate_right) {
                        audio_play_sfx(game.audio, ifx rotate_right then sfxs.rotate_right else sfxs.rotate_left);
                    }
                    input.rotate_direction = .NONE;
                }
            }
        }
    
        case .CLEARING_LINES;
        if state_timer >= 1.0 {
            netrix_add_lines(netrix, board.lines_to_clear.count);
            destroy_lines_to_clear(*board);
            netrix_set_state(netrix, .SPAWNING);
        }

        case .GAME_OVER_START;
        if board_is_full(*board) {
            netrix_set_state(netrix, .GAME_OVER_IDLE);
        }

        if next_gravity_time >= game.time {
            next_gravity_time += GAME_OVER_FILL_SPEED;
            board_fill_next_row(*board);
        }
        
        case .GAME_OVER_IDLE;

        if input_actions.ok {
            ingame_menu_close(true);

            main_menu_load();

            start_single_player_game();
        }

        if input_actions.cancel {
            ingame_menu_open();
        }
    }

    // reset action inputs
    input_actions = .{};
}

netrix_set_move_input :: (using netrix : *Netrix, move_direction : Move_Direction) {
    input.move_direction = move_direction;
    input.move_time_accum = 0.0;
    input.move_counter = 0;
}

netrix_clear_move_input :: (using netrix : *Netrix) {
    input.move_direction = .NONE;
    input.move_time_accum = 0.0;
    input.move_counter = 0;
    input.rotate_direction = .NONE;
}

netrix_set_rotate_input :: (using netrix : *Netrix, rotate_direction : Rotate_Direction) {
    input.rotate_direction = rotate_direction;
}

netrix_get_input_move_speed :: (input_level : int) -> float {
    if input_level == {
        case 0;
        return 0.25;
        case 1;
        return 0.125;
        case;
        return 0.0625;
    }
}

netrix_add_lines :: (netrix : *Netrix, num_lines : int) {
    assert(num_lines >= 1 && num_lines <= 4);

    get_score_per_num_lines :: (num_lines : int) -> int {
        if num_lines == {
            case 1;
            return 100;
            case 2;
            return 225;
            case 3; 
            return 375;
            case 4;
            return 500;
        }

        return 0;
    }

    netrix.num_lines += num_lines;

    netrix.level = netrix.num_lines / 10;
    if netrix.level < MIN_LEVEL {
        netrix.level = MIN_LEVEL;
    }
    else if netrix.level > MAX_LEVEL {
        netrix.level = MAX_LEVEL;
    }

    netrix.score += get_score_per_num_lines(num_lines);

    ingame_ui_update(netrix);
}

handle_move_current_block :: (using netrix : *Netrix, move_direction : Move_Direction) -> bool {
    new_pos := current_block.grid_pos + direction_to_grid_pos(move_direction);
    if can_move_block(*board, *current_block, new_pos) {
        move_block(*board, *current_block, new_pos);
        if move_direction == .LEFT || move_direction == .RIGHT {
            audio_play_sfx(game.audio, sfxs.move_block);
        }
        return true;
    }
    else {
        if move_direction == .DOWN {
            place_block(*board, *current_block);
            score += 5;
            ingame_ui_update(netrix);
            if has_lines_to_clear(*board) {
                netrix_set_state(netrix, .CLEARING_LINES);
                audio_play_sfx(game.audio, sfxs.lines_complete);
            }
            else {
                netrix_set_state(netrix, .SPAWNING);
                audio_play_sfx(game.audio, sfxs.place_block);
            }
        }
    }
    return false;
}

netrix_render :: (using netrix : *Netrix) {
    if state == .NOT_RUNNING {
        return;
    }
    board_render(*board);
}

netrix_pause :: (netrix : *Netrix) {
    game.time_dilation = 0.0;
    netrix_clear_move_input(netrix);
    netrix.input_actions = .{};
}

netrix_unpause :: (netrix : *Netrix) {
    game.time_dilation = 1.0;
    netrix_clear_move_input(netrix);
    netrix.input_actions = .{};
}