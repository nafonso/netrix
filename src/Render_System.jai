#import "Basic";
#import "Math";
#import "GL";

Render_System :: struct {
    projection_game : Matrix4;
    projection_ui : Matrix4;

    view : Matrix4;

    game_shader : GLuint;
    game_shader_ubo : u32; // uniform buffer object
}

render_system_init :: ( using rs : *Render_System, window_width : u32, window_height : u32 ) {
    view = matrix4_identity();

    game_shader = create_shader( tprint("%1%", shader_directory, "netrix_block.vert"), tprint("%1%", shader_directory,"netrix_block.frag"));

    glGenBuffers(1, *game_shader_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, game_shader_ubo);
    glBufferData(GL_UNIFORM_BUFFER, size_of(Matrix4), null, GL_STATIC_DRAW);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    glBindBufferRange(GL_UNIFORM_BUFFER, 0, game_shader_ubo, 0, size_of(Matrix4));

    on_window_size_changed(rs, window_width, window_height);

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

on_window_size_changed :: (using rs : *Render_System, window_width : u32, window_height : u32) {
    // update opengl viewport
    glViewport(0, 0, window_width, window_height);

    // game projection
    near := -10.0;
    far := 10.0;
    projection_game = orthographic_projection_matrix(0, xx default_window_width, 0, xx default_window_height, near, far);

    // transpose since ogl is column major
    game_proj_view := transpose(projection_game * view);

    glBindBuffer(GL_UNIFORM_BUFFER, game_shader_ubo);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, size_of(Matrix4), *game_proj_view._11);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);

    // ui projection matrix has Y flipped
    projection_ui = orthographic_projection_matrix(0, xx window_width, xx window_height, 0, near, far);
    // projection_ui = orthographic_projection_matrix(0, xx window_width, 0, xx window_height, near, far);
}

render :: (using rs : *Render_System) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    netrix_render(*game.netrix);

    glClear(GL_DEPTH_BUFFER_BIT);
    ui_system_render(game.ui, projection_ui, view);
}
