#import "Render"; // for Dynamic_Font
#import "Hash_Table";
#import "Basic";

Font_Manager :: struct {
    font_directory : string;
    font_table     : Table(string, *Dynamic_Font);
}

font_manager_init :: (fm : *Font_Manager, font_directory : string) {
    init( *fm.font_table, 32 );
    fm.font_directory = font_directory;
}

make_font_key :: (font_name : string, font_size : u8) -> string {
    t_str := talloc_string(font_name.count+1);
    memcpy(t_str.data, font_name.data, font_name.count);
    t_str[font_name.count] = font_size;
    return t_str;
}

get_font :: (using fm : *Font_Manager, font_name : string, font_size : u8) -> *Dynamic_Font {
    temp_font_key := make_font_key(font_name, font_size); // temp only for querying
    font_pointer := table_find_pointer(font_table, temp_font_key);

    if !font_pointer {
        font := load_font(font_directory, font_name, xx font_size);
        if font {
            font_key := copy_string(temp_font_key); // needs to keep this string alive now
            font_pointer = table_add(*font_table, font_key, font);
        }
    }

    assert(font_pointer != null);

    return <<font_pointer;
}
