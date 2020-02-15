#import "Basic";
#import "File";
#import "Math";
#import "SDL";
#import "GL";
#import "String";

#load "Render_System.jai";
#load "Shader_Manager.jai";
#load "main_menu.jai";

#import "Debug_Helper";
#import "Texture_Manager";
#import "Font_Manager";
#import "Ui_System";

data_directory :: "data/";

default_window_width  : u32 : 1280;
default_window_height : u32 : 720;

window_width  := default_window_width;
window_height := default_window_height;

game_window : *SDL_Window;

render_system : *Render_System;

Game :: struct {
    tm            : *Texture_Manager;
    fm            : *Font_Manager;
    ui            : *Ui_System;
    time_dilation := 1.0;
    delta_time    := 0.0;
}

Editor :: struct {
    tm : *Texture_Manager;
    ui : *Ui_System;
}

game : *Game;
editor : *Editor;

main :: () {

    shader_directory := join(data_directory, "shaders/");
    texture_directory := join(data_directory, "textures/");
    sound_directory := join(data_directory, "sounds/");
    font_directory := join(data_directory, "fonts/");

    quit : bool = false;

    game_window : *SDL_Window = SDL_CreateWindow("NETRIX", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, xx window_width, xx window_height, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(game_window);
    gl_load( *gl, SDL_GL_GetProcAddress );

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);

    SDL_GL_SetSwapInterval(0); // no v-sync

    simple_shader := create_shader( tprint("%1%", shader_directory, "simple.vert"), tprint("%1%", shader_directory,"simple.frag") );
    if( !simple_shader ){
        quit = true;
    }

    game = New(Game);
    game.tm = New(Texture_Manager);
    game.fm = New(Font_Manager);
    game.ui = New(Ui_System);

    ui_shader := create_shader(tprint("%1%", shader_directory, "ui.vert"), tprint("%1%", shader_directory,"ui.frag"));
    ui_debug_shader := create_shader(tprint("%1%", shader_directory, "ui_debug.vert"), tprint("%1%", shader_directory,"ui_debug.frag"));

    init_texture_manager(game.tm, texture_directory);
    init_font_manager(game.fm, font_directory);
    init_ui_system(game.ui, ui_shader, window_width, window_height, ui_debug_shader);

    render_system = New(Render_System);

    init_render_system(render_system, window_width, window_height);

    init_main_menu(game);
    show_main_menu(game, true);
    
    // debug_bar := ui_element(alignment = Ui_Alignment.TOP_RIGHT);

    // add_root_element(game.ui, *debug_bar);
    
    // fps_counter := ui_element();
    // fps_counter.min_size = make_vector2(150,0);
    // fps_counter.margin = 10;
    // fps_counter.brush = brush_text("FPS: ", get_font(game.fm, "KarminaBoldItalic.otf", 32));

    // add_child(*debug_bar, *fps_counter);

    last_time := get_time();

    frame_counter_time_sample :: 1.0;

    frame_counter := 0;
    frame_counter_time := last_time + frame_counter_time_sample;

    frame_time_target : float64 = 1.0 / 61;

    while( !quit )
    {
        curr_time := get_time();
        delta_time := cast(float32)(curr_time - last_time);
        last_time = curr_time;

        quit = handle_generic_input();
        if( quit ) {
            print("Quitting...\n");
            break;
        }

        frame_counter += 1;

        if curr_time >= frame_counter_time {
            fps := frame_counter;

            // ui_set_text(*fps_counter, tprint("FPS: %", fps));

            frame_counter_time = curr_time + frame_counter_time_sample;
            frame_counter = 0;
        }

        game.delta_time = delta_time*game.time_dilation;
        
        render_main_menu(render_system);

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

handle_generic_input :: () -> bool {
    requestQuit := false;

    evt : SDL_Event = ---;
    if( SDL_PollEvent( *evt ) )
    {
        if evt.type == {
            case SDL_QUIT;
            requestQuit = true;
            
            case SDL_WINDOWEVENT;
            if evt.window.event == {
                case SDL_WINDOWEVENT_RESIZED; #through;
                case SDL_WINDOWEVENT_SIZE_CHANGED;
                window_width = evt.window.data1;
                window_height = evt.window.data2;
                on_window_size_changed(render_system, window_width, window_height);
                on_window_size_changed(game.ui, window_width, window_height);
                case SDL_WINDOWEVENT_ENTER;
                // print("Enter\n");
                case SDL_WINDOWEVENT_LEAVE;
                // print("Leave\n");
                case SDL_WINDOWEVENT_FOCUS_GAINED;
                // print("focus gained!\n");
            }

            case SDL_MOUSEMOTION;
            set_mouse_pos(game.ui, make_vector2(xx evt.motion.x, xx evt.motion.y));
            // print("Mouse Pos: %\n", game.ui.mouse_pos);

            case SDL_KEYDOWN;
            if evt.key.keysym.scancode == {
                case SDL_SCANCODE_ESCAPE;
                requestQuit = true;

                // render modes
                case SDL_SCANCODE_F1;
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL); // poly
                case SDL_SCANCODE_F2;
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE); // wireframe
            }
        }
    }

    return requestQuit;
}

get_ui_texture :: (texture : string) -> GLuint {
    return get_texture( game.tm, texture, game.ui );
}
