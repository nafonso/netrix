#import "stb_image";
#import "Hash_Table";
#import "GL";
#import "Basic";
#import "String";
#import "System";


Texture_Info :: struct {
    id : GLuint;
    width : s32;
    height : s32;
    num_channels : s32;
    requesters : [..]Any;
}

Texture_Manager :: struct {
    texture_table : Table(string, Texture_Info);
    num_textures_used : s32;
    base_path : string;
    // path_buffer : string;

    path_buffer_size :: 512;
}

init_texture_manager :: (tm : *Texture_Manager, base_path : string) {
    init( *tm.texture_table, 32 );
    
    // tm.path_buffer = alloc_string(512); // have base buffer for non-allocing
    // tm.path_buffer.count = 0;
    tm.base_path = base_path;
    // tm.path_buffer = append(tm.path_buffer, tm.base_path, tm.path_buffer_size);
}

deinit_texture_manager :: (tm : *Texture_Manager) {
    uninit(*tm.texture_table);
}

get_texture :: (using tm : *Texture_Manager, texture_path : string, requester : Any) -> GLuint {
    texture_info := table_find_pointer( texture_table, texture_path );

    if texture_info == null {
        // not there, create

        new_texture_info : Texture_Info;
        using new_texture_info;

        full_path := tprint("%1%", base_path, texture_path);

        data : *u8 = stbi_load( temp_c_string(full_path), *width, *height, *num_channels, 0);

        if( data == null ){
            print("%\n", get_path_of_running_executable());
            print("Failed loading texture: %\n", full_path);
            return 0;
        }
        
        glGenTextures(1, *id);

        glBindTexture(GL_TEXTURE_2D, id);

        assert(num_channels >= 3 && num_channels <= 4);

        channels_enum : GLenum = GL_RGB;
        if num_channels == 4 channels_enum = GL_RGBA;

        // glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glTexImage2D(GL_TEXTURE_2D, 0, xx channels_enum, xx width, xx height, 0, channels_enum, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);

        stbi_image_free(data);

        texture_info = table_add( *texture_table, texture_path, new_texture_info );
    }

    // add requester
    array_add(*texture_info.requesters, requester );

    return texture_info.id;
}

get_texture_info :: (using tm : *Texture_Manager, texture_path : string, requester : Any) -> *Texture_Info {
    texture_info : *Texture_Info = table_find_pointer( texture_table, texture_path );
    if texture_info {
        array_add( *texture_info.requesters, requester );
    }
    return texture_info;
}
