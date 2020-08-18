#import "Basic";
#import "Hash_Table";

#import "SDL_mixer";

MUSIC_VOLUME_MULTIPLIER :: 0.2;
SFX_VOLUME_MULTIPLIER :: 0.5;

Audio_System :: struct {
    directory_path  : string;
    music           : Music;
    sfx_table       : Table(string, *Sfx);

    music_volume    : float = 0.3;
    sfx_volume      : float = 0.3;
}

Music :: struct {
    file_path           : string;
    handle              : *Mix_Music;
    volume_multiplier   : float;
}

Sfx :: struct {
    file_path   : string;
    handle      : *Mix_Chunk;
}

audio_init :: (using audio_system : *Audio_System, sound_directory_path : string) {
    directory_path = sound_directory_path;

    if Mix_Init(.MIX_INIT_MP3) == 0 {
        print("Error Initializing Audio System");
        return;
    }

    open_audio := Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);

    audio_set_music_volume(audio_system, music_volume);
    audio_set_sfx_volume(audio_system, sfx_volume);
}

audio_load_music :: (using audio_system : *Audio_System, music_file_path : string, volume_multiplier : float = MUSIC_VOLUME_MULTIPLIER) {
    if music.handle {
        audio_stop_music(audio_system);
    }

    full_file_path := tprint("%1%", directory_path, music_file_path);

    music.handle = Mix_LoadMUS(full_file_path.data);
    if music.handle {
        music.file_path = music_file_path;
        music.volume_multiplier = volume_multiplier;
    }
    else{
        print("Error: Couldn't open file %", full_file_path);
    }

    audio_set_music_volume(audio_system, music_volume); // so volume_multiplier is taken into account
}

audio_play_music :: (using audio_system : *Audio_System, fade_ms : s32 = 0, loop : s32 = -1) {
    if fade_ms < 0 { fade_ms = 0; }
    if music.handle {
        Mix_FadeInMusic(music.handle, loop, fade_ms);
    }
}

audio_stop_music :: (using audio_system : *Audio_System, fade_ms : s32 = 0) {
    if fade_ms < 0 { fade_ms = 0; }
    Mix_FadeOutMusic(fade_ms);
}

audio_pause_music :: (using audio_system : *Audio_System) {
    Mix_PauseMusic();
}

audio_resume_music :: (using audio_system : *Audio_System) {
    Mix_ResumeMusic();
}

audio_set_music_volume :: (using audio_system : *Audio_System, volume : float) {
    music_volume = volume;
    Mix_VolumeMusic(cast(s32)(music_volume*MIX_MAX_VOLUME*music.volume_multiplier));
}

audio_load_sfx :: (using audio_system : *Audio_System, sfx_file_path : string) -> *Sfx {

    sfx_entry := table_find_pointer(sfx_table, sfx_file_path);
    if sfx_entry == null {
        full_path := tprint("%1%", directory_path, sfx_file_path);
        handle := Mix_LoadWAV(full_path.data);
        if handle {
            new_sfx := New(Sfx);
            new_sfx.file_path = sfx_file_path;
            new_sfx.handle = handle;
            table_add(*sfx_table, sfx_file_path, new_sfx);
            return new_sfx;
        } 
        
        print("Error: Couldn't load sfx %\n", full_path);
        
        return null;
    }

    return <<sfx_entry;
}

audio_play_sfx :: (using audio_system : *Audio_System, sfx : *Sfx) {
    assert(audio_system && sfx && sfx.handle);
    if !sfx || !sfx.handle { return; }

    Mix_PlayChannel(-1, sfx.handle, 0);
}

audio_set_sfx_volume :: (using audio_system : *Audio_System, volume : float) {
    sfx_volume = volume;
    Mix_Volume(-1, cast(s32)(sfx_volume*MIX_MAX_VOLUME*SFX_VOLUME_MULTIPLIER));
}
