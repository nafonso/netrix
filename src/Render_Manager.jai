#import "Basic";
#import "Math";
#import "GL";

#load "graphics.jai";

Render_Manager :: struct {
    static_meshes : []Static_Mesh;
    max_static_meshes :: 64;

    ui_meshes : []Static_Mesh;
    max_ui_meshes :: 64;

    projection_game : Matrix4;
    projection_ui : Matrix4;

    // projection : Matrix4;
    view : Matrix4;
}

Render_System :: struct {
    is_init : bool;
    projection_game : Matrix4;
    projection_ui : Matrix4;

    view : Matrix4;
}

init_render_system :: ( using rs : *Render_system, window_width : float, window_height : float ) {
    // update opengl viewport
    glViewport(0, 0, window_width, window_height);

    // game projection
    near := -10;
    far := 10;
    projection_game = orthographic_projection_matrix(0, window_width, 0, window_height, near, far);

    // ui projection matrix has Y flipped
    projection_ui = orthographic_projection_matrix(0, window_width, window_height, 0, near, far);
    
    if !is_init {
        is_init = true;
        view = matrix4_identity();

        glEnable(GL_DEPTH_TEST);
    }
}


init_orthographic :: ( using rm : *Render_Manager, left : float, right : float, bottom : float, top : float, near : float, far : float ) {
    projection = orthographic_projection_matrix(left, right, bottom, top, near, far);
    view = matrix4_identity();

    static_meshes = NewArray(max_static_meshes, Static_Mesh);
    static_meshes.count = 0;

    ui_meshes = NewArray(max_ui_meshes, Static_Mesh);
    ui_meshes.count = 0;
}

create_static_mesh :: (using rm : *Render_Manager) -> *Static_Mesh #must {
    assert( static_meshes.count < max_static_meshes );

    static_meshes.count += 1;

    static_mesh := *static_meshes[static_meshes.count-1];
    
    return static_mesh;
}

create_ui_mesh :: (using rm : *Render_Manager) -> *Static_Mesh #must {
    assert( static_meshes.count < max_static_meshes );

    ui_meshes.count += 1;

    ui_mesh := *ui_meshes[ui_meshes.count-1];
    
    return ui_mesh;
}

render_game :: ( using rm : *Render_Manager ) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for * static_meshes {
        render_static_mesh( it, *rm.view, *rm.projection );
    }
}

render_main_menu :: (using rm : *Render_Manager) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for * ui_meshes {
        if it.shader {
            render_static_mesh( it, *rm.view, *rm.projection );
        }
    }
}


render_static_mesh :: ( mesh : *Static_Mesh, view : *Matrix4, projection : *Matrix4 ) {
    glUseProgram(mesh.shader);

    // print("%\n", <<view);
    // view._22 = -1;
    // view._24 = 1;

    // mesh.model._11 = -1;

    modelLoc := glGetUniformLocation(mesh.shader, "model");
    glUniformMatrix4fv(modelLoc, 1, GL_TRUE, *mesh.model._11);
    viewLoc := glGetUniformLocation(mesh.shader, "view");
    glUniformMatrix4fv(viewLoc, 1, GL_TRUE, *view._11);
    projectionLoc := glGetUniformLocation(mesh.shader, "proj");
    glUniformMatrix4fv(projectionLoc, 1, GL_TRUE, *projection._11);

    if mesh.texture {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, mesh.texture);
    }

    glBindVertexArray(mesh.v_a_o);
    glDrawElements(GL_TRIANGLES, cast(u32)mesh.indices.count, GL_UNSIGNED_INT, null);
}