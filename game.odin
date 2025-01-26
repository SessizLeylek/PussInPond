package game

import rl "vendor:raylib"
import m "core:math"
import rnd "core:math/rand"
import "core:fmt"

Particle :: struct{
    pos : rl.Vector2,
    color : rl.Color,
    lifetime : f32
}
particles : [dynamic]Particle

Fish :: struct{
    pos : rl.Vector2,
    dir : i8,
    is_pufferfish : bool,
    is_golden : bool
}
fishes : [dynamic]Fish
fish_spawn_cooldown : f32

Player :: struct{
    pos, velocity : rl.Vector2,
    dir : i8,
    in_bubble : bool,
    dash_cooldown : f32,
    dash_dir : rl.Vector2
}
player : Player
PLAYER_SPEED :: 256

oxygen_level : f32 = 100
hunger_level : f32 = 100
score : i32 = 0
score_cd : f32 = 0

bubble_positions : [dynamic]rl.Vector2
bubble_spawn_cooldown : f32

game_active : bool = true

spawn_fish :: proc()
{
    fish_dir := i8(rnd.int_max(2)) * 2 - 1
    is_puff := rnd.int_max(3) == 0
    is_gold := rnd.int_max(5) == 0

    new_fish := Fish {{f32(fish_dir) * -480 + 480, rnd.float32_uniform(60, 900)}, fish_dir, is_puff, is_gold}
    append(&fishes, new_fish)
}

restart_game :: proc()
{
    player.pos = {480, 480}
    player.velocity = 0
    player.in_bubble = false
    oxygen_level = 100
    hunger_level = 100
    score = 0
    score_cd = 0

    shrink(&bubble_positions, 0)
    shrink(&fishes, 0)

    game_active = true
}

end_game :: proc()
{
    game_active = false

    rl.StopSound(snd_music)
    rl.PlaySound(snd_lose)
}

update_game :: proc()
{

    // repeat music
    if !rl.IsSoundPlaying(snd_music)
    {
        rl.PlaySound(snd_music)
    }

    // keyboard input
    if player.in_bubble
    {
        // pop out of bubble
        if rl.IsKeyPressed(.SPACE)
        {
            player.in_bubble = false
            player.velocity *= 0.8
            
            // emit particles
            append(&particles, Particle {player.pos, rl.WHITE, 0})

            //play sound
            rl.PlaySound(snd_pop)
        }
    }
    else
    {
        player.velocity *= 1 - rl.GetFrameTime()

        if rl.IsKeyDown(.RIGHT)
        {
            player.velocity += {rl.GetFrameTime() * PLAYER_SPEED, 0}
            player.dir = 1
        }
        
        if rl.IsKeyDown(.LEFT)
        {
            player.velocity -= {rl.GetFrameTime() * PLAYER_SPEED, 0}
            player.dir = -1
        }
    
        if rl.IsKeyDown(.UP)
        {
            player.velocity -= {0, rl.GetFrameTime() * PLAYER_SPEED}
        }
        
        if rl.IsKeyDown(.DOWN)
        {
            player.velocity += {0, rl.GetFrameTime() * PLAYER_SPEED}
        }

        // dashing
        if rl.IsKeyPressed(.LEFT_SHIFT) && player.dash_cooldown == 0
        {
            player.dash_cooldown = 3
            player.dash_dir = 0
            if rl.IsKeyDown(.RIGHT) do player.dash_dir.x = 1
            else if rl.IsKeyDown(.LEFT) do player.dash_dir.x = -1
            if rl.IsKeyDown(.UP) do player.dash_dir.y = -1
            else if rl.IsKeyDown(.DOWN) do player.dash_dir.y = 1

            player.dash_dir = rl.Vector2Normalize(player.dash_dir)
            player.velocity = 0
        }
    }

    // player movement
    player.dash_cooldown -= rl.GetFrameTime()
    if player.dash_cooldown < 0 do player.dash_cooldown = 0
    if player.dash_cooldown > 2.8
    {
        // dashing
        player.pos += player.dash_dir * PLAYER_SPEED * rl.GetFrameTime() * 4
    }

    player.pos += player.velocity * rl.GetFrameTime()
    if player.pos.x > 960 do player.pos.x = 960
    else if player.pos.x < 0 do player.pos.x = 0
    if player.pos.y > 960 do player.pos.y = 960
    else if player.pos.y < 0 do player.pos.y = 0

    // fish spawning
    if fish_spawn_cooldown <= 0
    {
        fish_spawn_cooldown = 1

        spawn_fish()
    }
    else
    {
        fish_spawn_cooldown -= rl.GetFrameTime()
    }

    // fish movement
    fishes_to_delete := make([dynamic]int, context.temp_allocator)
    for &fish, i in fishes
    {
        fish.pos += {f32(fish.dir) * rl.GetFrameTime() * 128, 0}

        // delete outside fishes
        if fish.pos.x < -10 || fish.pos.x > 970 do append(&fishes_to_delete, i)

        // fishes close to cat get eaten, or hurt the cat
        if rl.Vector2Distance(fish.pos, player.pos) < 24
        {
            if fish.is_pufferfish
            {
                end_game()
            }
            else
            {
                append(&fishes_to_delete, i)
                
                hunger_level += 10
                if hunger_level > 100 do hunger_level = 100

                if fish.is_golden do score += 20
                else do score += 5

                // emit particles
                append(&particles, Particle {fish.pos, rl.RED, 0})

                //play sound 
                rl.PlaySound(snd_eat)
            }
        }
    }

    // oxygen levels
    if player.in_bubble
    {
        oxygen_level += rl.GetFrameTime() * 10
        if oxygen_level > 100 do oxygen_level = 100
    }
    else
    {
        oxygen_level -= rl.GetFrameTime() * 3
        if oxygen_level < 0
        {
            oxygen_level = 0
            end_game()
        }
    }

    // hunger levels
    hunger_level -= rl.GetFrameTime() * 3
    if hunger_level < 0
    {
        hunger_level = 0
        end_game()
    }

    // score over time
    score_cd += rl.GetFrameTime()
    if score_cd > 1 
    {
        score_cd = 0
        score += 1
    }

    // bubbles update
    bubbles_to_delete := make([dynamic]int, context.temp_allocator)
    for &bpos, i in bubble_positions
    {
        bpos -= {0, rl.GetFrameTime() * 64}

        if bpos.y < 0
        {
            append(&bubbles_to_delete, i)
        }

        // bubbles close to cat absorbs it
        if rl.Vector2Distance(bpos, player.pos) < 32
        {
            player.in_bubble = true

            append(&bubbles_to_delete, i)

            //play sound
            rl.PlaySound(snd_bubble)
        }
    }

    // spawn bubbles
    if bubble_spawn_cooldown > 0
    {
        bubble_spawn_cooldown -= rl.GetFrameTime()
    }
    else
    {
        bubble_spawn_cooldown = 2

        append(&bubble_positions, rl.Vector2 {rnd.float32_uniform(0, 960), 960})
    }

    // particle update
    particles_to_delete := make([dynamic]int, context.temp_allocator)
    for &particle, i in particles
    {
        particle.lifetime += rl.GetFrameTime()
        if particle.lifetime > 0.2 do append(&particles_to_delete, i)
    }

    // delete fishes
    #reverse for f2d in fishes_to_delete
    {
        unordered_remove(&fishes, f2d)
    }

    // delete bubbles
    #reverse for b2d in bubbles_to_delete
    {
        unordered_remove(&bubble_positions, b2d)
    }

    // delete particles
    #reverse for p2d in particles_to_delete
    {
        unordered_remove(&particles, p2d)
    }

    free_all(context.temp_allocator)
}

draw_game :: proc()
{
    // Draw Score
    score_text := rl.TextFormat("%i", score)
    text_size := rl.MeasureTextEx(rl.GetFontDefault(), score_text, 128, 0)
    rl.DrawText(score_text, 480 - i32(text_size.x * 0.5), 480 - i32(text_size.y * 0.5), 128, rl.SKYBLUE)

    // Draw Player
    drawn_sprite : CroppedSprite
    if player.in_bubble
    {
        if (i32(rl.GetTime() * 4) % 4 == 0) do drawn_sprite = SPR_CAT_BUBBLE1
        else if (i32(rl.GetTime() * 4) % 4 == 1) do drawn_sprite = SPR_CAT_BUBBLE2
        else if (i32(rl.GetTime() * 4) % 4 == 2) do drawn_sprite = SPR_CAT_BUBBLE3
        else do drawn_sprite = SPR_CAT_BUBBLE4
    }
    else
    {
        if player.dir == 1
        {
            if rl.Vector2Length(player.velocity) > 1 && (i32(rl.GetTime() * 4) % 2 == 0) do drawn_sprite = SPR_CATR2
            else do drawn_sprite = SPR_CATR1
        }
        else 
        {
            if rl.Vector2Length(player.velocity) > 1 && (i32(rl.GetTime() * 4) % 2 == 0) do drawn_sprite = SPR_CATL2
            else do drawn_sprite = SPR_CATL1
        }
    }

    cat_color := rl.WHITE
    if !player.in_bubble 
    {
        cat_color = rl.Color {255, 106, 0, 255}
        if player.dash_cooldown > 2.8 do cat_color = rl.LIGHTGRAY
        else if player.dash_cooldown > 0 do cat_color = rl.RED
    }

    if game_active do draw_from_cropped_sprite(drawn_sprite, player.pos, 4, 0, cat_color)
    else do draw_from_cropped_sprite(SPR_CATR1, player.pos, 4, 180, cat_color)

    // Draw fishes
    for fish in fishes
    {
        if fish.is_pufferfish
        {
            if rl.Vector2Distance(fish.pos, player.pos) > 24 do draw_from_cropped_sprite(SPR_PUFFERFISH0, fish.pos, 4, 0, rl.WHITE)
            else do  draw_from_cropped_sprite(SPR_PUFFERFISH1, fish.pos, 4, 0, rl.WHITE)
        }
        else if fish.is_golden
        {
            if fish.dir == 1 do draw_from_cropped_sprite(SPR_GOLDFISHR, fish.pos, 4, 0, rl.WHITE)
            else do draw_from_cropped_sprite(SPR_GOLDFISHL, fish.pos, 4, 0, rl.WHITE)
        }
        else
        {
            if fish.dir == 1 do draw_from_cropped_sprite(SPR_FISHR, fish.pos, 4, 0, rl.WHITE)
            else do draw_from_cropped_sprite(SPR_FISHL, fish.pos, 4, 0, rl.WHITE)
        }
    }

    // Draw bubbles
    for bpos in bubble_positions
    {
        draw_from_cropped_sprite(SPR_BUBBLE, bpos, 4, 0, {255, 255, 255, 127})
    }

    // Draw particles
    for particle in particles
    {
        if particle.lifetime < 0.1 do draw_from_cropped_sprite(SPR_PARTICLE1, particle.pos, 4, 0, particle.color)
        else do draw_from_cropped_sprite(SPR_PARTICLE2, particle.pos, 4, 0, particle.color)
    }

    // Draw Bars
    rl.DrawRectangleV({30, 870} * rel_pos, {oxygen_level * 9, 30}, rl.SKYBLUE)
    rl.DrawRectangleV({30, 900} * rel_pos, {hunger_level * 9, 30}, rl.ORANGE)

    // Draw restart text
    if !game_active do rl.DrawText("Press R to Restart", 160, 160, 64, rl.BLACK)
}

main :: proc()
{
    init_window()
    update_rel_pos()

    for true
    {
        if rl.GetKeyPressed() != .KEY_NULL do break

        rl.BeginDrawing()
        rl.DrawTextureEx(tex_title, 0, 0, 4, rl.WHITE)
        rl.EndDrawing()
    }

    restart_game()

    for !rl.WindowShouldClose()
    {
        if game_active do update_game()
        else if rl.IsKeyPressed(.R) do restart_game()

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLUE)

        draw_game()

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
