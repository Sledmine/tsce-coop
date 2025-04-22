;; 06_b30_revamp_mission_debug_room.hsc
;; Developer room, accessible before the mission begins
;; ---

;; ---
;; Normal debug room features

(script continuous b30r_debug_room_launch_select
    (cond
        (
            (<= 1.0 (device_get_position launch_switch_lz))
            (set mission_launch_index b30r_launch_lz)
        )
        (
            (<= 1.0 (device_get_position launch_switch_ext))
            (set mission_launch_index b30r_launch_ext)
        )
        (
            (<= 1.0 (device_get_position launch_switch_override))
            (set mission_launch_index b30r_launch_override)
        )
        (
            (<= 1.0 (device_get_position launch_switch_override_a))
            (set mission_launch_index b30r_launch_override_a)
        )
        (
            (<= 1.0 (device_get_position launch_switch_return))
            (set mission_launch_index b30r_launch_return)
        )
        (
            (<= 1.0 (device_get_position launch_switch_int))
            (set mission_launch_index b30r_launch_int)
        )
        (
            (<= 1.0 (device_get_position launch_switch_exit))
            (set mission_launch_index b30r_launch_exit)
        )
        (
            (<= 1.0 (device_get_position launch_switch_free))
            (set mission_launch_index b30r_launch_free)
        )
    )
)

;; Maybe this could be an animation or something instead, but whatever
(script dormant b30r_debug_room_turret_control
    (sleep_until (= 1 (device_get_position debug_turret)) 1)
    (object_set_permutation debug_turret "" "~damaged")
)

;; ---
;; The captain

;; We have to cache these, or the game will crap out for some reason
(global unit b30r_debug_room_hack_captain none)
(global real b30r_debug_room_hack_distance 0.0)
(global boolean b30r_debug_room_captain_done false)

(script static void (b30r_debug_room_captain_line (sound line))
    ;; Wait until the captain exists, and a player is close enough to hear him
    (sleep_until
        (begin
            (set b30r_debug_room_hack_distance (objects_distance_to_object (players) b30r_debug_room_hack_captain))
            (and
                (!= none b30r_debug_room_hack_captain)
                (> 0.85 b30r_debug_room_hack_distance)
                (< 0.0 b30r_debug_room_hack_distance)
            )
        )
    )
    
    ;; Play the line, then wait a bit before the next one
    (sound_impulse_start line b30r_debug_room_hack_captain 1.0)
    (sleep 180)
)

(script dormant b30r_debug_room_captain
    ;; Set him up
    (set b30r_debug_room_hack_captain (unit (list_get (ai_actors debug_room/captain) 0)))
    (objects_attach b30r_debug_room_hack_captain pipe_in_hand the_captain_pipe "")

    ;; Phase 1 - say hello
    (b30r_debug_room_captain_line "sound\dialog\x20\keyes01")
    
    ;; Phase 2 - play each line in random order, but only once
    (begin_random
        (b30r_debug_room_captain_line "sound\dialog\x10\keyes04")
        (b30r_debug_room_captain_line "sound\dialog\x20\keyes02")
        (b30r_debug_room_captain_line "sound\dialog\x20\keyes02b")
        (b30r_debug_room_captain_line "sound\dialog\x20\keyes12b")
        (b30r_debug_room_captain_line "sound\dialog\x20\keyes14")
    )

    ;; That's all he had to say.
    (set b30r_debug_room_captain_done true)
    
    ;; Phase 3 - looping noise only
    (sleep_until
        (begin
            (b30r_debug_room_captain_line "cmt\sounds\dialog\characters\human\captain\death_quiet")
            false
        )
    )
)

;; ---
;; The escape

(global real the_escape_fx_scale 0)
(global boolean the_escape_fx_start false)
(script continuous the_escape_fx
    (sleep_until the_escape_fx_start 1)
    
    (set the_escape_fx_scale
        (max the_escape_fx_scale
            (-
                1
                (/
                    (objects_distance_to_flag (players) debug_room_bonus_flash)
                    115
                )
            )
        )
    )
    
    (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode" the_escape_fx_scale)
    (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_begin" (max 0 (- the_escape_fx_scale 0.2)))
    (cinematic_screen_effect_set_convolution 1 2 0 (* (max 0 (- the_escape_fx_scale 0.3)) 15) 0)
)

(script dormant the_escape
    ;; Things start getting a little spooky
    (sound_looping_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode" none 0)
    (ai_place escape_h1)
    (set the_escape_fx_start true)
    
    ;; Things become spookier
    (sleep_until (< 0.3 the_escape_fx_scale))
    (cinematic_screen_effect_start true)
    (sound_looping_start "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_begin" none 0)
    
    ;; The way out!
    (sleep_until (< 0.9 the_escape_fx_scale))
    (effect_new "cmt\scenarios\singleplayer\b30_revamp\effects\debug_room_bonus_flash" debug_room_bonus_flash)
    (sound_impulse_start "cmt\sounds\sfx\scenery\covenant\c_holo_projector\fx\c_holo_projector_out" none 1)
    (sleep 5)
    
    ;; Delay the fade-out until the lens flare has grown to screen-size
    (fade_out 1 1 1 10)
    (sleep 10)
    
    ;; Control is no longer necessary
    (player_enable_input false)
    (sleep -1 the_escape_fx)
    (sleep 1)
    
    ;; Wait another tick for the input change to apply, then deposit the player outside
    (object_teleport (player0) debug_room_bonus_teleport)
    (object_destroy grimdome)
    (object_create threshold)
    (physics_set_gravity 0)
    (cinematic_screen_effect_stop)
    (sound_looping_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode")
    (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_begin" 1)
    (sleep 1)
    
    ;; Wait another tick for the teleport to fulfill, then eject the player
    (fade_in 1 1 1 0)
    (player_effect_explosion)
    (player_effect_stop 12)
    (device_set_position escape 1)
    
    ;; Fake perspective
    (object_set_scale halo 0.01 3300)
    
    ;; After a while, confusion fades...
    (sleep 300)
    (sound_looping_stop "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_begin")
    
    ;; ...understanding grows...
    (sleep 90)
    (sound_impulse_start "cmt\sounds\music\h1\ambience\escape_throb" none 1)
    (sleep 150)
    (sound_looping_start "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_end" none 1)
    
	;; ...the universe begins to fade away...
	(sleep 1460)
    (object_create oblivion)
    (device_set_position oblivion 1)
	
    ;; ...and, one hopes, contentment is reached.
    (sleep 2100)
    (fade_out 1 1 1 300)
    
    ;; You made it.
    (sound_looping_stop "cmt\sounds\music\scenarios\b30_revamp\egg\escape\escape_end")
)

(script dormant the_escape_entry
    ;; Escape is only possible on the brittle edge of reality
    ;; CO-OP: Escape is also only possible alone, because this gets too complicated otherwise
    (if (or (not (game_is_easy)) (game_is_cooperative))
        (sleep -1)
    )
    
    ;; Wait for player to come to an understanding with the captain
    (sleep_until b30r_debug_room_captain_done)
    
    ;; The unthinkable becomes thinkable
    (object_destroy debug_room_door)
    (object_create debug_room_door_unlocked)
    (ai_attach debug_cheif debug_room/debug_watchers)
    (ai_attach debug_elite debug_room/debug_watchers)
    (ai_command_list_by_unit debug_cheif escape_debug_cheif_exit)
    (ai_command_list_by_unit debug_elite escape_debug_elite_exit)
    (sleep 240)
    (ai_erase debug_room/debug_watchers)

    ;; Wait for player to reach the threshold
    (sleep_until (volume_test_objects debug_room_bonus_threshold (players)))
    (wake the_escape)
    
    ;; There's no going back now.
    (object_destroy debug_room_door_unlocked)
    (object_create debug_room_door)
)

(script dormant the_escape_debug
    ;; CO-OP: This is a debug script, and the main sequence isn't meant for multiplayer anyway
    (object_teleport (player0) debug_room_bonus_debug)
    (wake the_escape)
)

;; ---
;; Entry point
;; This will block until a mission is selected

(script static void b30r_debug_room
    ;; Warp to the debug room
    (switch_bsp bsp_index_debug_room)
    (teleport_players debug_room_spawn_0 debug_room_spawn_1)
    
    ;; Wait a frame for everything to get in order
    (sleep 1)
    
    ;; Set up the room
    (ai_set_blind debug_room true)
    (ai_set_deaf debug_room true)
    (wake b30r_debug_room_turret_control)
    (wake b30r_debug_room_captain)
    (wake the_escape_entry)
    
    ;; Wait another second for everything to settle
    (skip_second)
    
    ;; Fade in
    (player_enable_input true)
    (fade_from_black)
    
    ;; Wait for player to select a launch index
    (sleep_until (< -1 mission_launch_index) 1)
    
    ;; Fade out, and disable debug room scripts
    (fade_to_black)
    (sleep -1 the_escape_entry)
    (sleep -1 b30r_debug_room_captain)
    (sleep -1 b30r_debug_room_turret_control)
    (sleep -1 b30r_debug_room_launch_select)
    (sleep 30)
    (player_enable_input false)
)