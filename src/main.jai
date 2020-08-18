#import "Basic";
#import "File";
#import "Math";
#import "SDL";
#import "GL";
#import "String";
#import "Thread";

data_directory :: "data/";
shader_directory : string; 
texture_directory : string;
sound_directory : string;
font_directory : string;

#load "Render_System.jai";
#load "Shader_Manager.jai";

#import "Debug_Helper";
#import "Texture_Manager";
#import "Font_Manager";
#import "Ui_System";
#import "Audio_System";

#load "menus/menu.jai";

#load "core/Entity.jai";

#load "Block.jai";
#load "Netrix.jai";


default_window_width  : u32 : 1280;
default_window_height : u32 : 720;

window_width  := default_window_width;
window_height := default_window_height;

game_window : *SDL_Window;

render_system : *Render_System;

debug_bar : *Ui_Element;

Game :: struct {
    tm              : *Texture_Manager;
    fm              : *Font_Manager;
    ui              : *Ui_System;
    audio           : *Audio_System;

    time_dilation   := 1.0;

    time            := 0.0;
    delta_time      := 0.0;

    is_running      := false;
        
    netrix : Netrix;
}

Editor :: struct {
    tm : *Texture_Manager;
    ui : *Ui_System;
}

game : *Game;
exit_game : bool = false;

main :: () {

    args := get_command_line_arguments();
    defer array_reset(*args);

    shader_directory = join(data_directory, "shaders/");
    texture_directory = join(data_directory, "textures/");
    sound_directory = join(data_directory, "sounds/");
    font_directory = join(data_directory, "fonts/");

    game_window : *SDL_Window = SDL_CreateWindow("NETRIX", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, xx window_width, xx window_height, SDL_WINDOW_OPENGL);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(game_window);
    gl_load( *gl, SDL_GL_GetProcAddress );

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

    SDL_GL_SetSwapInterval(0); // no v-sync

    game = New(Game);
    game.tm = New(Texture_Manager);
    game.fm = New(Font_Manager);
    game.ui = New(Ui_System);
    game.audio = New(Audio_System);
    
    ui_shader := create_shader(tprint("%1%", shader_directory, "ui.vert"), tprint("%1%", shader_directory,"ui.frag"));
    ui_debug_shader := create_shader(tprint("%1%", shader_directory, "ui_debug.vert"), tprint("%1%", shader_directory,"ui_debug.frag"));

    texture_manager_init(game.tm, texture_directory);
    font_manager_init(game.fm, font_directory);
    ui_system_init(game.ui, game.tm, game.fm, ui_shader, window_width, window_height, ui_debug_shader);

    audio_init(game.audio, sound_directory);

    render_system = New(Render_System);

    render_system_init(render_system, window_width, window_height);

    menu_init(game);

    netrix_init(*game.netrix);

    ingame_menu_init(game);
    ingame_ui_init(game);

    open_options_argument := false;

    show_fps_counter := false;

    for args {
        if it == {
            case "-game";
            game.is_running = true;

            case "-options";
            open_options_argument = true;

            case "-fps";
            show_fps_counter = true;
        }
    }

    if game.is_running {
        start_single_player_game();
    }
    else {
        main_menu_load();
        if open_options_argument {
            options_menu_show(true);
        }
    }

    debug_bar = ui_element_create(game.ui, ui_element(alignment = Ui_Alignment.TOP_RIGHT));

    fps_counter := ui_label_create(game.ui, "", get_font(game.fm, "JetBrainsMono-Regular.ttf", 32));
    fps_counter.fill = false;
    fps_counter.min_size = make_vector2(150, 0);
    fps_counter.padding = 50;

    add_child(debug_bar, fps_counter);

    if show_fps_counter {
        toggle_fps_counter();
    }

    last_time := get_time();

    frame_counter_time_sample :: 1.0;

    frame_counter := 0;
    frame_counter_time := last_time + frame_counter_time_sample;

    frame_time_target : float64 = 1.0 / 61;

    while( !exit_game )
    {
        curr_time := get_time();
        delta_time := cast(float32)(curr_time - last_time);
        last_time = curr_time;

        handle_generic_input();
        if( exit_game ) {
            break;
        }

        frame_counter += 1;

        if curr_time >= frame_counter_time {
            fps := frame_counter;

            ui_set_text(fps_counter, tprint("FPS: %", fps));

            frame_counter_time = curr_time + frame_counter_time_sample;
            frame_counter = 0;
        }

        game.delta_time = delta_time*game.time_dilation;
        game.time += game.delta_time;

        tick(game);
        
        render(render_system);

        SDL_GL_SwapWindow( game_window );
        
        // don't forget to clear temporary allocator between frames
        reset_temporary_storage();

        actual_frame_time := get_time() - curr_time;

        if frame_time_target > actual_frame_time {
            sleep_time := cast,no_check(s32)((frame_time_target - actual_frame_time) * 1000);
            sleep_milliseconds(sleep_time);
        }
    }

    SDL_DestroyWindow( game_window );
    SDL_Quit();
}

handle_generic_input :: () {

    evt : SDL_Event = ---;
    if( SDL_PollEvent( *evt ) )
    {
        if evt.type == {
            case SDL_QUIT;
            exit_game = true;
            
            case SDL_WINDOWEVENT;
            if evt.window.event == {
                case SDL_WINDOWEVENT_SIZE_CHANGED;
                window_width = evt.window.data1;
                window_height = evt.window.data2;
                on_window_size_changed(render_system, window_width, window_height);
                ui_on_window_size_changed(game.ui, window_width, window_height);
            }

            case SDL_MOUSEMOTION;
            ui_set_mouse_pos(game.ui, make_vector2(xx evt.motion.x, xx evt.motion.y));

            case SDL_MOUSEBUTTONDOWN; #through;
            case SDL_MOUSEBUTTONUP;
            handle_mouse_event(game.ui, evt.button);

            case SDL_KEYDOWN;
            if evt.key.keysym.scancode == {
                // gameplay
                case SDL_SCANCODE_W; #through;
                case SDL_SCANCODE_UP;
                netrix_set_move_input(*game.netrix, .UP);

                case SDL_SCANCODE_A; #through;
                case SDL_SCANCODE_LEFT;
                netrix_set_move_input(*game.netrix, .LEFT);

                case SDL_SCANCODE_S; #through;
                case SDL_SCANCODE_DOWN;
                netrix_set_move_input(*game.netrix, .DOWN);

                case SDL_SCANCODE_D; #through;
                case SDL_SCANCODE_RIGHT;
                netrix_set_move_input(*game.netrix, .RIGHT);

                case SDL_SCANCODE_COMMA; #through;
                case SDL_SCANCODE_Z;
                netrix_set_rotate_input(*game.netrix, .LEFT);
                
                case SDL_SCANCODE_PERIOD; #through;
                case SDL_SCANCODE_X;
                netrix_set_rotate_input(*game.netrix, .RIGHT);

                case SDL_SCANCODE_BACKSPACE;
                exit_game = true;

                case SDL_SCANCODE_RETURN; #through;
                case SDL_SCANCODE_RETURN2;
                game.netrix.input_actions.ok = true;

                case SDL_SCANCODE_ESCAPE;
                game.netrix.input_actions.cancel = true;
                
                // render modes
                case SDL_SCANCODE_F1;
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); // poly
                case SDL_SCANCODE_F2;
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); // wireframe
                case SDL_SCANCODE_F3;
                toggle_fps_counter();
                case SDL_SCANCODE_F5;
                ui_enable_debug(game.ui, !game.ui.is_debug_on);
            }

            case SDL_KEYUP;
            if evt.key.keysym.scancode == {
                // gameplay
                case SDL_SCANCODE_W; #through;
                case SDL_SCANCODE_UP; 
                // UP is cleared automatically

                case SDL_SCANCODE_A; #through;
                case SDL_SCANCODE_LEFT;
                if game.netrix.input.move_direction == .LEFT {
                    netrix_clear_move_input(*game.netrix);
                }

                case SDL_SCANCODE_S; #through;
                case SDL_SCANCODE_DOWN;
                if game.netrix.input.move_direction == .DOWN {
                    netrix_clear_move_input(*game.netrix);
                }

                case SDL_SCANCODE_D; #through;
                case SDL_SCANCODE_RIGHT;
                if game.netrix.input.move_direction == .RIGHT {
                    netrix_clear_move_input(*game.netrix);
                }
            }
        }
    }
}

get_ui_texture :: (texture : string) -> GLuint {
    return get_texture( game.tm, texture, game.ui );
}

handle_mouse_event :: (using ui : *Ui_System, evt : SDL_MouseButtonEvent) {
    if !ui.selected_element return;

    ui_evt : Ui_Event;

    if evt.state == 0 {
        ui_evt.type = Ui_Event_Type.BUTTON_UP;
        ui_evt.button.id = 0;
    }
    else {
        ui_evt.type = Ui_Event_Type.BUTTON_DOWN;
        ui_evt.button.id = 0;
    }

    ui_handle_event( ui, *ui_evt );
}

start_single_player_game :: () {
    game.is_running = true;
    show_menu(false);
    netrix_set_state(*game.netrix, .LOADING);
}

main_menu_load :: () {
    game.is_running = false;
    netrix_set_state(*game.netrix, .NOT_RUNNING);
    main_menu_open();
}

tick :: (game : *Game) {
    netrix_tick(*game.netrix);
}

toggle_fps_counter :: () {
    if debug_bar.ui_system {
        ui_remove_root_element(game.ui, debug_bar);
    }
    else {
        ui_add_root_element(game.ui, debug_bar);
    }
}