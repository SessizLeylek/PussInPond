package game

import rl "vendor:raylib"

// DEFINE YOUR RESOURCES HERE
tex_sprites : rl.Texture2D
snd_bubble : rl.Sound
snd_pop : rl.Sound
snd_eat : rl.Sound
snd_music : rl.Sound
snd_lose : rl.Sound

load_resources :: proc()
{
    raw_image1 := #load("sprites.png")
    tex_sprites = rl.LoadTextureFromImage(rl.LoadImageFromMemory(".png", &raw_image1[0], i32(len(raw_image1))))

    raw_bubble := #load("bubble.ogg")
    snd_bubble = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".ogg", &raw_bubble[0], i32(len(raw_bubble))))

    raw_pop := #load("pop.ogg")
    snd_pop = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".ogg", &raw_pop[0], i32(len(raw_pop))))

    raw_eat := #load("eat.ogg")
    snd_eat = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".ogg", &raw_eat[0], i32(len(raw_eat))))

    raw_music := #load("music.ogg")
    snd_music = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".ogg", &raw_music[0], i32(len(raw_music))))

    raw_lose := #load("lose.ogg")
    snd_lose = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".ogg", &raw_lose[0], i32(len(raw_lose))))

}


// initializes window
init_window :: proc()
{
    rl.InitWindow(960, 960, "PUSS IN POND")
    rl.SetWindowState({.MSAA_4X_HINT, .VSYNC_HINT, .WINDOW_UNDECORATED})
    rl.SetTargetFPS(120)

    rl.InitAudioDevice()

    load_resources()

}

REF_HEIGHT :: 960
rel_pos : f32
update_rel_pos :: proc()
{
    rel_pos = f32(rl.GetScreenHeight()) / REF_HEIGHT
}

CroppedSprite :: struct
{
    source : rl.Rectangle,
    origin : rl.Vector2
}

draw_from_cropped_sprite :: proc(spr : CroppedSprite, pos, _size : rl.Vector2, rot: f32, col : rl.Color)
{
    size := [2]f32 {spr.source.width, spr.source.height} * _size
    dest_rectangle := rl.Rectangle {pos.x * rel_pos, pos.y * rel_pos, size.x * rel_pos, size.y * rel_pos}

    rl.DrawTexturePro(tex_sprites, spr.source, dest_rectangle, spr.origin * size * rel_pos, rot, col)
}

SPR_CATR1 :: CroppedSprite{
    {0, 0, 16, 16},
    {0.5, 0.5}
}

SPR_CATR2 :: CroppedSprite{
    {16, 0, 16, 16},
    {0.5, 0.5}
}

SPR_CATL1 :: CroppedSprite{
    {32, 0, 16, 16},
    {0.5, 0.5}
}

SPR_CATL2 :: CroppedSprite{
    {48, 0, 16, 16},
    {0.5, 0.5}
}

SPR_CAT_BUBBLE1 :: CroppedSprite{
    {0, 16, 16, 16},
    {0.5, 0.5}
}

SPR_CAT_BUBBLE2 :: CroppedSprite{
    {16, 16, 16, 16},
    {0.5, 0.5}
}

SPR_CAT_BUBBLE3 :: CroppedSprite{
    {32, 16, 16, 16},
    {0.5, 0.5}
}

SPR_CAT_BUBBLE4 :: CroppedSprite{
    {48, 16, 16, 16},
    {0.5, 0.5}
}

SPR_PUFFERFISH0 :: CroppedSprite{
    {32, 48, 16, 16},
    {0.5, 0.5}
}

SPR_PUFFERFISH1 :: CroppedSprite{
    {0, 32, 32, 32},
    {0.5, 0.5}
}

SPR_BUBBLE :: CroppedSprite{
    {32, 32, 16, 16},
    {0.5, 0.5}
}

SPR_FISHR :: CroppedSprite{
    {48, 32, 16, 16},
    {0.5, 0.5}
}

SPR_FISHL :: CroppedSprite{
    {48, 48, 16, 16},
    {0.5, 0.5}
}

SPR_GOLDFISHR :: CroppedSprite{
    {64, 32, 16, 16},
    {0.5, 0.5}
}

SPR_GOLDFISHL :: CroppedSprite{
    {64, 48, 16, 16},
    {0.5, 0.5}
}

SPR_PARTICLE1 :: CroppedSprite{
    {64, 0, 16, 16},
    {0.5, 0.5}
}

SPR_PARTICLE2 :: CroppedSprite{
    {64, 16, 16, 16},
    {0.5, 0.5}
}