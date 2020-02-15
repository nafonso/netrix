Shader_Manager :: struct {
    
}

create_shader :: ( vert_file_path : string, frag_file_path : string ) -> GLuint {

    create_shader_type :: ( file_path : string, type : GLenum ) -> GLuint {

        shader_source, read_success := read_entire_file( file_path );
        defer free( shader_source );

        shader_id : GLuint = 0;

        if read_success {
            shader_id = glCreateShader( type );

            shader_length : GLint = xx shader_source.count;

            glShaderSource(shader_id, 1, *shader_source.data, *shader_length);

            glCompileShader(shader_id);

            success : GLint;
            glGetShaderiv( shader_id, GL_COMPILE_STATUS, *success );

            if( !success ){
                errorLog := talloc_string(512);
                glGetShaderInfoLog( shader_id, size_of(type_of(errorLog)), null, errorLog.data );
                print("Creating shader '%' failed: %\n", file_path, errorLog );
                shader_id = 0;
            }
        }

        return shader_id;
    }

    vertex_shader := create_shader_type( vert_file_path, GL_VERTEX_SHADER );
    fragment_shader := create_shader_type( frag_file_path, GL_FRAGMENT_SHADER );

    defer {
        glDeleteShader(vertex_shader);
        glDeleteShader(fragment_shader);
    }

    if( !vertex_shader || !fragment_shader ) {
        assert(false);
        return 0;
    }

    shader := glCreateProgram();
    glAttachShader( shader, vertex_shader );
    glAttachShader( shader, fragment_shader );
    glLinkProgram( shader );

    return shader;
}