;; 00_global.hsc
;; Globally-available scripts and helpers, useful for all mods
;; ---

;; ---
;; Player management
;; Lag once said: "if it's like 2018 and you're somehow porting things to co-op, i'm sorry."
;; It is 2022 and I'm somehow porting things to co-op. But in 2022, we have parameterized scripts!

(script static boolean (volume_test_players_any (trigger_volume volume))
    (volume_test_objects volume (players))
)

(script static boolean (volume_test_players_all (trigger_volume volume))
    (volume_test_objects_all volume (players))
)

;; CO-OP: In case of more players, add more parameters & teleport them too
(script static void (teleport_players (cutscene_flag flag_player0) (cutscene_flag flag_player1))
    (object_teleport (player0) flag_player0)
    (object_teleport (player1) flag_player1)
)

;; ---
;; Music helpers

(script static void (music_start (looping_sound music))
    (sound_looping_start music none 1)
)

(script static void (music_alt (looping_sound music))
    (sound_looping_set_alternate music true)
)

(script static void (music_stop (looping_sound music))
    (sound_looping_stop music)
)

;; ---
;; Script-node saving conveniences
;; TODO: We don't need to save script nodes anymore. Maybe some or all of these can go away

(script static boolean random_chance_50
    (> 0.50 (real_random_range 0 1))
)

(script static void skip_frame
    (sleep 1)
)

(script static void skip_second
    (sleep 30)
)

(script static void skip_half_second
    (sleep 15)
)

(script static void sleep_forever
    (sleep -1)
)

(script static void fade_to_white
    (fade_out 1 1 1 30)
)

(script static void fade_from_white
    (fade_in 1 1 1 30)
)

(script static void fade_to_black
    (fade_out 0 0 0 30)
)

(script static void fade_from_black
    (fade_in 0 0 0 30)
)

(script static void snap_to_black
    (fade_out 0 0 0 0)
)

;; ---
;; Other misc. helpers

(script static unit (ai_actor (ai my_ai) (short index))
    (unit (list_get (ai_actors my_ai) index))
)

;; ---
;; Complete garbage

;; HACK: MCC's sound mixing is very different from the original game (& Custom Edition).
;; Scripted dialogue & ambient sounds are much quieter than expected.
;; This is an engine issue, but it ruins some carefully tuned moments, so we've got to do something.

;; The evil solution: manually reduce the gain on all sound classes that aren't too quiet.
;; The user might have to increase their master volume to compensate, but we have to do something.
;; Please, PLEASE remove this if MCC ever fixes audio mixing.

(script static void (reduce_sound_class (string name))
    (sound_class_set_gain name 0.6 1)
)

(script static void (increase_sound_class (string name))
    (sound_class_set_gain name 1 1)
)

(script static void HACK_sound_gain_hack_very_evil
    (reduce_sound_class "projectile_impact")
    (reduce_sound_class "projectile_detonation")
    (reduce_sound_class "weapon_fire")
    (reduce_sound_class "weapon_ready")
    (reduce_sound_class "weapon_reload")
    (reduce_sound_class "weapon_empty")
    (reduce_sound_class "weapon_charge")
    (reduce_sound_class "weapon_overheat")
    (reduce_sound_class "weapon_idle")
    (reduce_sound_class "object_impacts")
    (reduce_sound_class "particle_impacts")
    (reduce_sound_class "slow_particle_impacts")
    (reduce_sound_class "unit_footsteps")
    (reduce_sound_class "unit_dialog")
    (reduce_sound_class "vehicle_collision")
    (reduce_sound_class "vehicle_engine")
    (reduce_sound_class "device_door")
    (reduce_sound_class "device_force_field")
    (reduce_sound_class "device_machinery")
    (reduce_sound_class "device_nature")
    (reduce_sound_class "device_computers")
    (reduce_sound_class "first_person_damage")
    (reduce_sound_class "scripted_effect")
    (reduce_sound_class "game_event")

    (sound_class_set_gain "music" 0.7 1)
    (increase_sound_class "ambient_nature")
    (increase_sound_class "ambient_machinery")
    (increase_sound_class "ambient_computers")
    (increase_sound_class "scripted_dialog_player")
    (increase_sound_class "scripted_dialog_other")
    (increase_sound_class "scripted_dialog_force_unspatialized")
)