Grid_Pos :: struct {
    x : s8;
    y : s8;
}

operator + :: (a : Grid_Pos, b : Grid_Pos) -> Grid_Pos {
    result : Grid_Pos = ---;
    result.x = a.x + b.x;
    result.y = a.y + b.y;
    return result;
}

operator - :: (a : Grid_Pos, b : Grid_Pos) -> Grid_Pos {
    result : Grid_Pos = ---;
    result.x = a.x - b.x;
    result.y = a.y - b.y;
    return result;
}


make_grid_pos :: (x : s8, y : s8) -> Grid_Pos {
    grid_pos : Grid_Pos;
    grid_pos.x = x;
    grid_pos.y = y;
    return grid_pos;
}

Board :: struct {
    width   :: 10;
    height  :: 20;
    horizontal_ratio : float : cast(float)width / height;
    
    grid : [width][height]*Block; // whole grid
    
    lines_to_clear : [..]int; // full lines we want to clear

    world_pos : Vector3;
    world_size : Vector3;

    inner_world_pos : Vector3;
    inner_world_size : Vector3;

    grid_world_pos : Vector3;

    all_blocks : [..]*Block;
    available_blocks : [..]*Block;
    
    block_size : float;

    mesh : Mesh;

    fill_block_texture : GLuint;

    next_block_textures : [xx Netrix_Block_Type.Z+1]GLuint;
}

grid_spawn_pos :: (using board : *Board) -> Grid_Pos {
    return make_grid_pos(width/2-1, height-2);
}

grid_to_world :: (board : *Board, grid_pos : Grid_Pos) -> Vector3 {
    assert(grid_pos.x >= 0 && grid_pos.x < board.width && grid_pos.y >= 0 && grid_pos.y < board.height);
    world_pos : Vector3 = ---;
    world_pos.z = 0.0;

    world_pos.x = board.grid_world_pos.x + board.block_size*grid_pos.x;
    world_pos.y = board.grid_world_pos.y + board.block_size*grid_pos.y;

    return world_pos;
}

Block_State :: enum u8 {
    NOT_USED :: 0;
    USED;
}

Block :: struct {
    state : Block_State = .NOT_USED;
    mesh : Mesh;
    grid_pos : Grid_Pos;
}

block_create :: (using board : *Board) -> *Block {
    block : *Block = null;
    if available_blocks.count > 0 {
        block = available_blocks[available_blocks.count-1];
        available_blocks.count -= 1;
    }
    else {
        block = New(Block);
        block.mesh = create_block_mesh(block_size, render_system.game_shader, 0);
        array_add(*all_blocks, block);
    }

    block.state = .USED;

    return block;
}

block_destroy :: (using board : *Board, block : *Block) {
    assert(block.state == .USED);
    block.state = .NOT_USED;
    array_add(*available_blocks, block);
}

Netrix_Block_Type :: enum u8 {
    INVALID :: 0;
    O :: 1;
    I :: 2;
    T :: 3;
    L :: 4;
    J :: 5;
    S :: 6;
    Z :: 7;
}

Netrix_Block :: struct {
    type    : Netrix_Block_Type;
    blocks  : [4]*Block;
    grid_pos: Grid_Pos;
}

netrix_block_create :: (type : Netrix_Block_Type, block_size : float) -> Netrix_Block {
    netrix_block : Netrix_Block;
    netrix_block.type = type;

    block_texture_path : string;
    if #complete type == {
        case .INVALID;
        assert(false);
        case .O;
        block_texture_path = "blocks/block_red.png";
        case .I;
        block_texture_path = "blocks/block_white.png";
        case .T;
        block_texture_path = "blocks/block_purple.png";
        case .L;
        block_texture_path = "blocks/block_orange.png";
        case .J;
        block_texture_path = "blocks/block_green.png";
        case .S;
        block_texture_path = "blocks/block_yellow.png";
        case .Z;
        block_texture_path = "blocks/block_blue.png";
    }

    block_texture := get_texture(game.tm, block_texture_path, null);

    for i : 0..netrix_block.blocks.count-1 {
        block := block_create(*game.netrix.board);
        block.mesh.texture = block_texture;
        netrix_block.blocks[i] = block;
    }

    if #complete type == {
        case .INVALID;
        assert(false);

        case .O;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(1, 1);
        netrix_block.blocks[3].grid_pos = make_grid_pos(0, 1);
        
        case .I;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(-1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[3].grid_pos = make_grid_pos(2, 0);

        case .T;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(0, 1);
        netrix_block.blocks[3].grid_pos = make_grid_pos(-1, 0);

        case .L;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(-1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[3].grid_pos = make_grid_pos(1, 1);

        case .J;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(-1, 0);
        netrix_block.blocks[3].grid_pos = make_grid_pos(-1, 1);
        case .S;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(-1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(0, 1);
        netrix_block.blocks[3].grid_pos = make_grid_pos(1, 1);
        case .Z;
        netrix_block.blocks[0].grid_pos = make_grid_pos(0, 0);
        netrix_block.blocks[1].grid_pos = make_grid_pos(1, 0);
        netrix_block.blocks[2].grid_pos = make_grid_pos(0, 1);
        netrix_block.blocks[3].grid_pos = make_grid_pos(-1, 1);
    }

    return netrix_block;
}

netrix_block_destroy :: (using netrix_block : *Netrix_Block) {
    assert(type != .INVALID);
    for *block : blocks {
        if <<block && (<<block).state == .USED {
            block_destroy(*game.netrix.board, <<block);
        }
        block = null;
    }
    type = .INVALID;
}

board_init :: (board : *Board) {
    vertical_margin := 50.0;
    board_border := 5.0;
    board_uv_slice := 0.45;

    array_reserve(*board.lines_to_clear, board.height);

    board.inner_world_size.y = window_height - vertical_margin;
    board.inner_world_size.x = board.horizontal_ratio * board.inner_world_size.y;

    board.world_size.y = board.inner_world_size.y + board_border + board_border;
    board.world_size.x = board.inner_world_size.x + board_border + board_border;

    board.block_size = board.inner_world_size.x / board.width;

    board.world_pos = make_vector3((window_width-board.world_size.x)*0.5, (window_height-board.world_size.y)*0.5, 0.0);

    board.inner_world_pos = board.world_pos + make_vector3(board_border, board_border, 0.0);

    board.grid_world_pos = board.inner_world_pos + make_vector3(board.block_size*0.5, board.block_size*0.5, 0);

    initialize_mesh := board.mesh.num_indices == 0;

    if initialize_mesh {
        init_mesh(*board.mesh, render_system.game_shader);
        board.mesh.texture = get_texture(game.tm, "puzzle_area_selected.png", null);

        board.next_block_textures[Netrix_Block_Type.I] = get_texture(game.tm, "netrix_blocks/i.png", null);
        board.next_block_textures[Netrix_Block_Type.O] = get_texture(game.tm, "netrix_blocks/o.png", null);
        board.next_block_textures[Netrix_Block_Type.T] = get_texture(game.tm, "netrix_blocks/t.png", null);
        board.next_block_textures[Netrix_Block_Type.S] = get_texture(game.tm, "netrix_blocks/s.png", null);
        board.next_block_textures[Netrix_Block_Type.Z] = get_texture(game.tm, "netrix_blocks/z.png", null);
        board.next_block_textures[Netrix_Block_Type.J] = get_texture(game.tm, "netrix_blocks/j.png", null);
        board.next_block_textures[Netrix_Block_Type.L] = get_texture(game.tm, "netrix_blocks/l.png", null);

        board.fill_block_texture = get_texture(game.tm, "blocks/block_black.png", null);
    }

    vertices, uvs, indices := make_xy_quad_9_slice(board.world_pos.xy, board.inner_world_size.xy, board_border, board_uv_slice);

    board.mesh.num_indices = indices.count;

    array_reserve(*board.mesh.buffer, (vertices.count+uvs.count)*5);
    board.mesh.buffer.count = board.mesh.buffer.allocated;

    for i : 0..vertices.count-1 {
        memcpy(*board.mesh.buffer[i*5], *vertices[i], size_of(Vector3));
        memcpy(*board.mesh.buffer[i*5+3], *uvs[i], size_of(Vector2));
    }

    glBindVertexArray(board.mesh.v_a_o);

    glBindBuffer(GL_ARRAY_BUFFER, board.mesh.v_b_o);
    glBufferData(GL_ARRAY_BUFFER, size_of(float)*board.mesh.buffer.count, board.mesh.buffer.data, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, board.mesh.e_b_o);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32)*indices.count, indices.data, GL_STATIC_DRAW);

    vertex_stride : u32 = size_of(Vector3)+size_of(Vector2);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, vertex_stride, cast(*void)0);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, vertex_stride, cast(*void)size_of(Vector3));

    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
}

board_is_full :: (board : *Board) -> bool {
    last_row := board.height-1;
    for col : 0..board.width-1 {
        if board.grid[col][last_row] == null {
            return false;
        }
    }
    return true;
}

board_fill_next_row :: (board : *Board) -> bool {
    for row : 0..board.height-1 {
        if board.grid[0][row] == null || board.grid[0][row].mesh.texture != board.fill_block_texture {
            for col : 0..board.width-1 {
                block : *Block = board.grid[col][row];
                if block == null {
                    block = block_create(board);
                    board.grid[col][row] = block;
                    block.mesh.model = make_translation_matrix4(grid_to_world(board, make_grid_pos(xx col, xx row)));
                }
                block.mesh.texture = board.fill_block_texture;
            }
            return true;
        }
    }
    return false;
}

board_render :: (board : *Board) {

    mesh_render(*board.mesh);

    for col : 0..board.width-1 {
        for row : 0..board.height-1 {
            block := board.grid[col][row];
            if block != null {
                mesh_render(*block.mesh);
            }
        }
    }
}

Move_Direction :: enum u8 {
    NONE    :: 0;
    DOWN    :: 1;
    LEFT    :: 2;
    RIGHT   :: 3;
    UP      :: 4;
}

Rotate_Direction :: enum u8 {
    NONE    :: 0;
    RIGHT   :: 1;
    LEFT    :: 2;
}

direction_to_grid_pos :: (direction : Move_Direction) -> Grid_Pos {
    grid_pos : Grid_Pos;
    if #complete direction == {
        case .NONE;
        assert(false); // need valid direction
        case .DOWN;
        grid_pos.y = -1;
        case .LEFT;
        grid_pos.x = -1;
        case .RIGHT;
        grid_pos.x = 1;
        case .UP;
        grid_pos.y = 1;
    }

    return grid_pos;
}

can_move_block :: (using board : *Board, netrix_block : *Netrix_Block, grid_pos : Grid_Pos) -> bool {
    remove_block(board, netrix_block);
    
    defer add_block(board, netrix_block);
    
    for netrix_block.blocks {
        test_pos := grid_pos + it.grid_pos;
        if !is_available(board, test_pos) {
            return false;
        }
    }

    return true;
}

is_available :: (using board : *Board, grid_pos : Grid_Pos) -> bool {
    if grid_pos.x < 0 || grid_pos.x >= board.width || grid_pos.y < 0 || grid_pos.y >= board.height {
        return false;
    }
    return board.grid[grid_pos.x][grid_pos.y] == null;
}

add_block :: (using board : *Board, netrix_block : *Netrix_Block) -> bool {
    success := true;

    for netrix_block.blocks {
        block_pos := netrix_block.grid_pos + it.grid_pos;
        if is_available(board, block_pos) {
            grid[block_pos.x][block_pos.y] = it;
            it.mesh.model = make_translation_matrix4(grid_to_world(board, block_pos));
        }
        else {
            success = false;
        }
    }

    return success;
}

remove_block :: (using board : *Board, netrix_block : *Netrix_Block) {
    for netrix_block.blocks {
        block_pos := netrix_block.grid_pos + it.grid_pos;
        assert(it == grid[block_pos.x][block_pos.y]);
        grid[block_pos.x][block_pos.y] = null;
    }
}

move_block :: (using board : *Board, netrix_block : *Netrix_Block, grid_pos : Grid_Pos) {
    remove_block(board, netrix_block);

    netrix_block.grid_pos = grid_pos;

    add_block(board, netrix_block);
}

place_block :: (using board : *Board, netrix_block : *Netrix_Block) {
    for *it : netrix_block.blocks {
        <<it = null;
    }

    netrix_block.type = .INVALID;

    // check for lines
    for row : 0..height-1 {
        for col : 0..width-1 {
            if grid[col][row] == null {
                continue row;
            }
        }

        array_add(*lines_to_clear, row);
    }
}

has_lines_to_clear :: (using board : *Board) -> bool {
    return lines_to_clear.count > 0;
}

destroy_lines_to_clear :: (using board : *Board) {
    for row : lines_to_clear {
        for col : 0..width-1 {
            deinit_mesh(*grid[col][row].mesh);
            free(grid[col][row]);
            grid[col][row] = null;
        }
    }

    for col : 0..width-1 {
        for < row : lines_to_clear {
            aux_row := row;

            while aux_row < height-1 {
                grid[col][aux_row] = grid[col][aux_row+1];
                if grid[col][aux_row] {
                    grid[col][aux_row].grid_pos = make_grid_pos(xx col, xx aux_row);
                    grid[col][aux_row].mesh.model = make_translation_matrix4(grid_to_world(board, grid[col][aux_row].grid_pos));
                }

                grid[col][aux_row+1] = null;
                aux_row += 1;

            }
        }
    }

    lines_to_clear.count = 0;
}

rotate_block :: (using board : *Board, netrix_block : *Netrix_Block, clockwise : bool) -> bool {

    rotate_blocks :: (netrix_block : *Netrix_Block, clockwise : bool) {
        if netrix_block.type == {
            case .I;
            // figure out if vertical
            if netrix_block.blocks[1].grid_pos.y != 0 {
                netrix_block.blocks[1].grid_pos = make_grid_pos(-1, 0);
                netrix_block.blocks[2].grid_pos = make_grid_pos(1, 0);
                netrix_block.blocks[3].grid_pos = make_grid_pos(2, 0);
            }
            else {
                netrix_block.blocks[1].grid_pos = make_grid_pos(0, 1);
                netrix_block.blocks[2].grid_pos = make_grid_pos(0, -1);
                netrix_block.blocks[3].grid_pos = make_grid_pos(0, -2);
            }

            case .S;
            // figure out if vertical
            if netrix_block.blocks[1].grid_pos.y != 0 {
                netrix_block.blocks[1].grid_pos = make_grid_pos(-1, 0);
                netrix_block.blocks[2].grid_pos = make_grid_pos(0, 1);
                netrix_block.blocks[3].grid_pos = make_grid_pos(1, 1);
            }
            else {
                netrix_block.blocks[1].grid_pos = make_grid_pos(0, -1);
                netrix_block.blocks[2].grid_pos = make_grid_pos(-1, 0);
                netrix_block.blocks[3].grid_pos = make_grid_pos(-1, 1);
            }

            case .Z;
            // figure out if vertical
            if netrix_block.blocks[1].grid_pos.y != 0 {
                netrix_block.blocks[1].grid_pos = make_grid_pos(1, 0);
                netrix_block.blocks[2].grid_pos = make_grid_pos(0, 1);
                netrix_block.blocks[3].grid_pos = make_grid_pos(-1, 1);
            }
            else {
                netrix_block.blocks[1].grid_pos = make_grid_pos(0, -1);
                netrix_block.blocks[2].grid_pos = make_grid_pos(1, 0);
                netrix_block.blocks[3].grid_pos = make_grid_pos(1, 1);
            }
        
            case;
            if(clockwise) {
                for netrix_block.blocks {
                    new_pos : Grid_Pos = ---;
                    new_pos.x = it.grid_pos.y;
                    new_pos.y = -it.grid_pos.x;
                    it.grid_pos = new_pos;
                }
            }
            else {
                for netrix_block.blocks {
                    new_pos : Grid_Pos = ---;
                    new_pos.x = -it.grid_pos.y;
                    new_pos.y = it.grid_pos.x;
                    it.grid_pos = new_pos;
                }
            }
        }
    }

    if netrix_block.type == .O {
        return false; // doesn't rotate
    }

    remove_block(board, netrix_block);

    rotate_blocks(netrix_block, clockwise);

    can_rotate := true;

    for netrix_block.blocks {
        block_pos := netrix_block.grid_pos + it.grid_pos;
        if !is_available(board, block_pos) {
            can_rotate = false;
            break;
        }
    }

    if !can_rotate {
        rotate_blocks(netrix_block, !clockwise);
    }

    add_block(board, netrix_block);

    return can_rotate;
}