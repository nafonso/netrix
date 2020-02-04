#import "Basic";
#import "File";
#import "Math";
#import "SDL";
#import "GL";
#import "String";

#load "Render_Manager.jai";
#load "Texture_Manager.jai";
#load "ui.jai";

data_directory :: "data/";

window_width :: 1280;
window_height :: 720;
game_window : *SDL_Window;

render_system : Render_System;
texture_manager : Texture_Manager;

debug_here :: () #expand {
    #import "Debug";
    Debug.attach_to_debugger();
    Debug.breakpoint();
}

main :: () {

    shader_directory := join(data_directory, "shaders/");
    texture_directory := join(data_directory, "textures/");
    sounds_directory := join(data_directory, "sounds/");

    quit : bool = false;

    game_window : *SDL_Window = SDL_CreateWindow("NETRIX", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, window_width, window_height, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(game_window);
    gl_load( *gl, SDL_GL_GetProcAddress );

    simple_shader := create_shader( tprint("%1%", shader_directory, "simple.vert"), tprint("%1%", shader_directory,"simple.frag") );
    if( !simple_shader ){
        quit = true;
    }

    init_render_system( *render_system, window_widthm window_height );

    init_texture_manager(*texture_manager, texture_directory);

    root := create_ui_element(create_ui_quad_xy(*render_manager, make_vector3(0.5, 0.5, 0.0), 0.5, 0.5 ));
    root.pos = make_vector2(0,0);
    root.size = make_vector2(window_width,window_height);
    root.child_alignment = Ui_Alignment.CENTER;
        
    background : Ui_Element = create_ui_element(create_ui_quad_xy(*render_manager, make_vector3(0, 0, 0), 1, 1 ));
    background.mesh.shader = simple_shader;
    background.mesh.texture = get_texture(*texture_manager, background, "logo.png");
    // background.max_width = window_width*0.5;
    // background.max_height = window_height*0.5;

    array_add(*root.children, *background);

    // debug_here();

    root.layout_func(*root);
    
    bind_static_mesh( background.mesh );

    while( !quit )
    {
        quit = handle_generic_input();
        if( quit ) {
            print("Quitting...\n");
            break;
        }

        render_main_menu( *render_manager );

        SDL_GL_SwapWindow( game_window );
        
        // don't forget to clear temporary allocator between frames
        reset_temporary_storage();
    }

    deinit_static_mesh( background.mesh );

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
                init_render_system(*render_system, evt.window.data1, evt.window.data2);
                case SDL_WINDOWEVENT_ENTER;
                // print("Enter\n");
                case SDL_WINDOWEVENT_LEAVE;
                // print("Leave\n");
                case SDL_WINDOWEVENT_FOCUS_GAINED;
                // print("focus gained!\n");
            }

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
