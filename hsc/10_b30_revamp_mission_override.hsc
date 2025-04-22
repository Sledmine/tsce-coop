;; 10_b30_revamp_mission_override.hsc
;; Mission to override the island's security lockdown
;; ---

;; ---
;; CLIFFS
;; ---

(global boolean m_override_cliffs_bowl_broken false)

;; ---
;; Phantom sequence

(script dormant m_override_cliffs_phantom
    ;; Wait for a player to actually see shit
    (sleep_until (volume_test_players_any override_cliffs_entrance) 1)
    
    ;; Bail out!
    (vehicle_unload override_cliffs_cship_grav "phantom")
    (skip_second)
    (ai_command_list override_cliffs_fodder_jump override_cliffs_phantom_drop)
    
    ;; Wait a bit
    (sleep 150)
    (ai_command_list_advance override_cliffs_fodder_jump)
    (unit_close override_cliffs_cship_grav)
    (unit_set_desired_flashlight_state override_cliffs_cship_grav false)
    
    ;; Fly away after a short delay
    (vehicle_hover override_cliffs_cship false)
    (recording_play_and_delete override_cliffs_cship override_cliffs_cship_out)
)

;; ---
;; AI migration + Brute anti-camping protocol (BACP)

(script static boolean (active_vehicle_in_volume (vehicle my_vehicle) (trigger_volume volume))
    (and
        (volume_test_object volume my_vehicle)
        (or
            (= my_vehicle X_CAR_vehicle_player0)
            (= my_vehicle X_CAR_vehicle_player1)
        )
    )
)

(global boolean m_override_cliffs_updater_start false)
(script continuous m_override_cliffs_updater
    (sleep_until m_override_cliffs_updater_start 1)

    ;; If we're in the bowl
    (if (not m_override_cliffs_bowl_broken)
        (begin
            ;; Wait for a player to be in jump + be camping, or for stage switch
            (sleep_until
                (or
                    (and
                        (volume_test_players_any override_cliffs_path_jump)
                        (> 1 (ai_living_fraction override_cliffs_bowl/bowl))
                    )
                    m_override_cliffs_bowl_broken
                )
            )
            
            ;; Wait
            (skip_second)

            ;; If a player is still camping
            (if
                (and (volume_test_players_any override_cliffs_path_jump) (<= 3 (ai_status override_cliffs_bowl/bowl)))
                (begin
                    (ai_migrate override_cliffs_bowl/bowl_brutes override_cliffs_bowl/brute_pursuit)
                    (ai_migrate override_cliffs_bowl/bowl_brutes_n override_cliffs_bowl/brute_pursuit)
                    (ai_migrate override_cliffs_bowl/bowl_brutes_a override_cliffs_bowl/brute_pursuit)
                    
                    ;; Grenades on legendary
                    (if (game_is_impossible)
                        (ai_command_list override_cliffs_bowl/high bowl_g_emp)
                    )

                    ;; Wait for players to fall back
                    (sleep_until
                        (not (volume_test_players_any override_cliffs_path_jump))
                    )

                    ;; Send Brutes back
                    (ai_migrate override_cliffs_bowl/brute_pursuit override_cliffs_bowl/bowl_brutes)

                )
            )
        )
        ;; If we're in the canyon
        (begin
            ;; If a player falls back to bowl
            (if (volume_test_players_any override_cliffs_path_bowl)
                (begin
                    ;; Send units to chase
                    (ai_magically_see_players override_cliffs_canyon)
                    (ai_migrate override_cliffs_canyon/low_grunts_spawn override_cliffs_canyon/bowl_grunts)
                    (ai_migrate override_cliffs_canyon/low_fallback override_cliffs_canyon/bowl_grunts)
                    (if (< normal (game_difficulty_get_real))
                        (begin
                            (ai_migrate override_cliffs_canyon/mid_jackal_spawn override_cliffs_canyon/bowl_jackals)
                            (ai_migrate override_cliffs_canyon/mid_advance override_cliffs_canyon/bowl_jackals)
                        )
                    )
                    (if (< hard (game_difficulty_get_real))
                        (ai_migrate override_cliffs_canyon/low_brutes_spawn override_cliffs_canyon/bowl_brutes)
                    )
                    
                    ;; Move them back when that player re-enters canyon
                    (sleep_until
                        (and
                            (volume_test_players_any override_cliffs_path_canyon)
                            (not (volume_test_players_any override_cliffs_path_bowl))
                        )
                    )
                    
                    (ai_migrate override_cliffs_canyon/bowl_grunts override_cliffs_canyon/low_fallback)
                    (ai_migrate override_cliffs_canyon/bowl_jackals override_cliffs_canyon/mid_advance)
                    (ai_migrate override_cliffs_canyon/bowl_brutes override_cliffs_canyon/low_brutes_spawn)
                )
            )
            
            ;; Toss grenades if a player tries to charge through in a vehicle
            (if
                (or
                    (active_vehicle_in_volume ext_drop_hog canyon_grenade_left)
                    (active_vehicle_in_volume override_cliffs_dump_hog canyon_grenade_left)
                )
                (begin
                    (ai_magically_see_players override_cliffs_canyon)
                    (skip_second)
                    (ai_command_list override_cliffs_canyon/low_brutes_spawn canyon_g_emp_left)
                    (ai_command_list override_cliffs_canyon/low_grunts_spawn canyon_g_plasma_left)
                )
            )
            (if
                (or
                    (active_vehicle_in_volume ext_drop_hog canyon_grenade_right)
                    (active_vehicle_in_volume override_cliffs_dump_hog canyon_grenade_right)
                )
                (begin
                    (ai_magically_see_players override_cliffs_canyon)
                    (skip_second)
                    (ai_command_list override_cliffs_canyon/low_brutes_spawn canyon_g_emp_right)
                    (ai_command_list override_cliffs_canyon/low_fallback canyon_g_plasma_right)
                    (ai_command_list override_cliffs_canyon/low_grunts_spawn canyon_g_plasma_right)
                )
            )
        )
    )
    
    (sleep 30)
)

;; ---
;; Main progression

(script dormant m_override_cliffs_return_friend
    (sleep_until 
        (volume_test_players_any override_cliffs_path_bowl)
    )
    (game_save_no_timeout)
    (sleep_until 
        (volume_test_players_any override_cliffs_path_end)
    )
    (game_save_no_timeout)
)

(script dormant m_override_cliffs
    ;; Phantom happens magically here due to idiocy
    
    ;; Setup
    (create_override_cliffs_cship)
    (unit_set_desired_flashlight_state override_cliffs_cship_grav true)
    (unit_open override_cliffs_cship_grav)
    (unit_open override_cliffs_cship_gun_l)
    (unit_open override_cliffs_cship_gun_r)
    
    ;; Teleport and hold
    ;; Special position for the special difficulty
    (if (game_is_easy)
        (object_teleport override_cliffs_cship override_cliffs_cship_easy)
        (object_teleport override_cliffs_cship override_cliffs_cship_flag)
    )
    (vehicle_hover override_cliffs_cship true)

    ;; Wait for a player's arrival
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_entrance)
            (volume_test_players_any override_cliffs_cliff_mid)
        )
    )

    ;; Clean shit up
    (garbage_collect_now)

    ;; Place the jump fodder
    (ai_place override_cliffs_fodder_jump)
    (vehicle_load_magic override_cliffs_cship_grav "phantom" (ai_actors override_cliffs_fodder_jump))
    
    ;; Extra dudes on legendary
    (if (game_is_impossible)
        (ai_place override_cliffs_fodder_cave)
    )

    ;; Phantom sequence
    (wake m_override_cliffs_phantom)

    ;; Save game
    (game_save_no_timeout)

    ;; Wait for a player to reach midpoint
    (sleep_until
        (volume_test_players_any override_cliffs_cliff_mid)
    )
    
    ;; Place AI in bowl
    (ai_place override_cliffs_bowl)
    
    ;; Special Grunts for the special difficulty
    (if (game_is_easy)
        (begin
            (ai_erase override_cliffs_bowl/bowl_brutes)
            (ai_erase override_cliffs_bowl/high_brutes)
            (ai_migrate override_cliffs_bowl/bowl_grunts_easy override_cliffs_bowl/bowl_brutes)
            (ai_migrate override_cliffs_bowl/bowl_grunts_easy_high override_cliffs_bowl/high_brutes)
            (ai_migrate override_cliffs_bowl/bowl_jackals_easy override_cliffs_bowl/bowl_jackals)
        )
        (ai_erase override_cliffs_bowl/easy)
    )
    
    ;; Brute leader gets a Carbine on legendary
    (if (game_is_impossible)
        (begin
            (ai_erase override_cliffs_bowl/high_brutes)
            (ai_migrate override_cliffs_bowl/high_brutes_imposs override_cliffs_bowl/high_brutes)
            (ai_migrate override_cliffs_bowl/bowl_jackals_imposs override_cliffs_bowl/bowl_jackals)
        )
        (ai_erase override_cliffs_bowl/bowl_jackals_imposs)
    )

    ;; Wait for a player to make a move, or for 10 seconds
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_path_jump)
            (volume_test_players_any override_cliffs_path_nook)
            (volume_test_players_any override_cliffs_path_bowl)
        )
        5
        300
    )

    ;; If players were lazy
    (if (not (or
                (volume_test_players_any override_cliffs_path_jump)
                (volume_test_players_any override_cliffs_path_nook)
                (volume_test_players_any override_cliffs_path_bowl)
            )
        )
        (begin
            (ai_migrate override_cliffs_bowl/nook_grunts_awake override_cliffs_bowl/nook_attacking)
            (ai_migrate override_cliffs_bowl/bowl_brutes override_cliffs_bowl/bowl_brutes_a)
            (ai_magically_see_players override_cliffs_bowl/nook)
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Then wait for someone to get to the bowl
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_path_jump)
            (volume_test_players_any override_cliffs_path_nook)
            (volume_test_players_any override_cliffs_path_bowl)
        )
    )

    ;; Wake bowl updater
    (set m_override_cliffs_updater_start true)

    ;; If a player took jump route first
    (if (volume_test_players_any override_cliffs_path_jump)
        ;; Move Jackals to be squished
        (begin
            (ai_migrate override_cliffs_bowl/bowl_jackals override_cliffs_bowl/bowl_jackals_c)
            (ai_magically_see_players override_cliffs_bowl)
        )
        ;; If a player took path route first
        (if (volume_test_players_any override_cliffs_path_nook)
            (begin
                ;; Move Brute followers to intercept player
                (ai_migrate override_cliffs_bowl/bowl_brutes override_cliffs_bowl/bowl_brutes_n)
                (ai_migrate override_cliffs_bowl/bowl_brutes_a override_cliffs_bowl/bowl_brutes_n)

                ;; And move Jackals to block off movement routes
                (ai_migrate override_cliffs_bowl/bowl_jackals override_cliffs_bowl/bowl_jackals_b)
            )
        )
    )

    ;; Wait for a player to enter bowl
    (sleep_until (volume_test_players_any override_cliffs_path_bowl))

    ;; Play arrival conversation
    (ai_conversation override_bowl_arrival)
    
    ;; Place canyon AI
    (ai_place override_cliffs_canyon)
    
    ;; Special erasure for the special difficulty
    (if (game_is_easy)
        (begin
            (ai_erase override_cliffs_canyon/low_brutes_spawn)
            (ai_erase override_cliffs_canyon/mid_brute_spawn)
            (ai_erase override_cliffs_canyon/high_brutes_spawn)
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Kill music cues
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")

    ;; Move units to attack player
    (ai_migrate override_cliffs_bowl/nook override_cliffs_bowl/bowl_grunts_d)
    (ai_migrate override_cliffs_bowl/bowl_jackals override_cliffs_bowl/bowl_jackals_c)
    (ai_migrate override_cliffs_bowl/bowl_brutes_n override_cliffs_bowl/bowl_brutes)
    (ai_migrate override_cliffs_bowl/bowl_brutes_a override_cliffs_bowl/bowl_brutes)

    ;; Wait for a player to push even more
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_path_bowl_side)
            (volume_test_players_any override_cliffs_path_canyon)
        )
    )
    
    ;; Special Phantom for the special difficulty
    (if (game_is_easy)
        (begin
            ;; Setup
            (create_override_cliffs_cship)
            (ai_place override_cliffs_brutes_easy)
            
            ;; Wait
            (skip_half_second)
            
            ;; Teleport and hold
            (object_teleport override_cliffs_cship cliffa_easy_cship_flag)
            (vehicle_hover override_cliffs_cship true)
            
             ;; Load it
            (vehicle_load_magic override_cliffs_cship_grav "phantom" (ai_actors override_cliffs_brutes_easy))
        )
    )
    
    ;; Save game
    (game_save_no_timeout)

    ;; Move things back
    (ai_migrate override_cliffs_bowl/bowl_brutes override_cliffs_bowl/high_brutes)
    (ai_migrate override_cliffs_bowl/bowl_jackals_b override_cliffs_bowl/bowl_jackals_c)
    (ai_migrate override_cliffs_bowl/nook_grunts_sleeping override_cliffs_bowl/bowl_jackals_c)
    (ai_migrate override_cliffs_bowl/nook_grunts_awake override_cliffs_bowl/bowl_jackals_c)

    ;; Wait for a player to break through
    (sleep_until (volume_test_players_any override_cliffs_path_canyon))
    (set m_override_cliffs_bowl_broken true)
    
    ;; Everyone can use a friend now and then
    (wake m_override_cliffs_return_friend)
    
    ;; Special brutes for the special difficulty
    (if (game_is_easy)
        (begin
            (vehicle_unload override_cliffs_cship_grav "phantom")
    
            ;; Wait a bit
            (skip_second)
            (ai_migrate override_cliffs_brutes_easy override_cliffs_canyon/mid_advance)
            (unit_close override_cliffs_cship_grav)
            
            ;; Fly away after a short delay
            (skip_second)
            (vehicle_hover override_cliffs_cship false)
            (recording_play_and_delete override_cliffs_cship override_cliffs_cship_out)
        )
    )
    
    ;; Save game
    (game_save_no_timeout)

    ;; Merge any remaining Brutes with the upcoming follower group
    (ai_migrate override_cliffs_bowl/bowl_brutes override_cliffs_canyon/low_brutes_spawn)

    ;; Wait for a player to pick a path
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_side_path)
            (volume_test_players_any override_cliffs_arch_path)
        )
    )

    (if (volume_test_players_any override_cliffs_side_path)
        ;; If a player goes to the side path first, head there
        (ai_migrate override_cliffs_canyon/mid override_cliffs_canyon/mid_advance)
        ;; If a player goes to the arch path first, flank
        (ai_migrate override_cliffs_canyon/mid override_cliffs_canyon/mid_fallback)
    )

    ;; Move any remaining low-platoon units to support from the side path
    (ai_migrate override_cliffs_canyon/low override_cliffs_canyon/mid_fallback)
    
    ;; And have the snipers retreat
    (ai_migrate override_cliffs_canyon/mid_jackal_snipers override_cliffs_canyon/high_jackal_snipers)

    ;; Wait for a player & push back/move up
    (sleep_until
        (volume_test_players_any override_cliffs_path_end)
    )
    
    ;; Updater no longer necessary
    (sleep -1 m_override_cliffs_updater)

    ;; Have the Brutes charge in if they haven't yet
    (ai_migrate override_cliffs_canyon/high_brutes_spawn override_cliffs_canyon/high_advance)
    (ai_migrate override_cliffs_canyon/mid override_cliffs_canyon/mid_fallback)

    ;; Cleanup
    (ai_erase override_cliffs_fodder_cave)
    (ai_erase override_cliffs_fodder_jump)

    ;; Save game
    (game_save_no_timeout)
    
    ;; Move it along, please, folks
    (sleep_until (= bsp_index_ext_pool (structure_bsp_index)) 1)
    (ai_migrate override_cliffs_canyon override_pool/anchor_right)
)

;; ---
;; Mission hooks

(script static void m_override_cliffs_startup
    (wake m_override_cliffs)
)

(script static void m_override_cliffs_cleanup
    (sleep -1 m_override_cliffs)
    (sleep -1 m_override_cliffs_updater)
)

;; ---
;; POOL
;; ---

(script dormant m_override_pool_music
    ;; Turn on boss music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_05_pool")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_05a_pool_bass")
    
    (sleep_until
        (or
            (volume_test_players_any override_pool_past)
            (volume_test_players_any override_cliffs_path_bowl)
            (= 0 (ai_living_count override_pool))
        )
        10
        4500
    )
    
    (if (not (volume_test_players_any override_pool_past))
        ;; Wait randomly just so it's not obvious
        (sleep (random_range 30 90))
    )

    ;; Turn off music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_05_pool")
    
    ;; "hm" - unknown TSC:E developer
    (sleep_until
        (or
            (volume_test_players_any override_pit_approach_left)
            (volume_test_players_any override_bridge_approach_left)
            (volume_test_players_any override_bridge_approach_right)
        )
        30
        300
    )
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_05a_pool_bass")
)

(script dormant m_override_pool
    ;; Wait for a player
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_path_end)
            (volume_test_players_any override_cliffs_smartass)
        )
    )

    ;; HACK: Wait until the BSP switches. It's this or a crash
    (sleep_until (= bsp_index_ext_pool (structure_bsp_index)) 1)
    (sleep 1)

    ;; Checkpoint
    (game_save_no_timeout)

    ;; Place AI
    ;; Special units for the special difficulty
    (if (game_is_easy)
        (begin
            (ai_place override_pool/grunts_easy)
            (ai_migrate override_pool/grunts_easy override_pool/anchor_right_brutes)
        )
        (begin
            (ai_place override_pool/fodder_left_grunts)
            (ai_place override_pool/fodder_right_grunts)
            (ai_place override_pool/anchor_right_grunts)
            (ai_place override_pool/anchor_left_brutes_imposs)
            (ai_place override_pool/anchor_right_brutes_imposs)
            (ai_place override_pool/anchor_left_brutes)
            (ai_place override_pool/anchor_right_brutes)

        )
    )
    
    ;; Legendary etc
    ;; No need to erase the legendary guys, since squad-level spawn count actually does what it says for that
    (if (game_is_impossible)
        (begin
            (ai_erase override_pool/anchor_left_brutes)
            (ai_erase override_pool/anchor_right_brutes)
            (ai_migrate override_pool/anchor_left_brutes_imposs override_pool/anchor_left_brutes)
            (ai_migrate override_pool/anchor_right_brutes_imposs override_pool/anchor_right_brutes)
        )
    )

    ;; Wait for a player
    (sleep_until (volume_test_players_any override_pool_approach))

    ;; Checkpoint
    (game_save_no_timeout)

    ;; AI are waiting for player so they know we're here
    (ai_magically_see_players override_pool)

    ;; Delay spawning these units until after the BSP switch, or they might spawn over nothing
    (if (game_is_easy)
        (begin
            (ai_place override_pool/hunters_easy)
            (ai_migrate override_pool/hunters_easy override_pool/anchor_left_brutes)
        )
        (begin
            (ai_place override_pool/boss_spawn)
            (ai_place override_pool/boss_support_long)
            (ai_place override_pool/boss_support_grunts)
        )
    )
    
    ;; Keep the fuelrod back for now! Give the players a chance to make it past the entrance
    (ai_braindead override_pool/boss_spawn true)

    ;; Turn on boss music
    (wake m_override_pool_music)

    ;; Wait for a player to move into the area, kill a few units, or shoot the boss before un-headfucking him
    (sleep_until
        (or
            (volume_test_players_any override_pool_enter_back)
            (volume_test_players_any override_pool_enter_side)
            (> 1.0 (unit_get_shield (unit (list_get (ai_actors override_pool/boss_spawn) 0))))
            (> 0.75 (ai_living_fraction override_pool))
        )
    )
    
    ;; You're going to need this!!!
    (game_save_no_timeout)

    ;; Indeed, the boss is now active
    (ai_braindead override_pool/boss_spawn false)
    (ai_migrate override_pool/boss_spawn override_pool/boss)
    
    ;; If players are is still camping the entrance, send the anchor Brutes to punish the camping little shits
    (ai_attack override_pool/anchor_right)
    (ai_attack override_pool/anchor_left)
    (ai_berserk override_pool/anchor_right true)
    (ai_berserk override_pool/anchor_left true)

    ;; Wait for boss to be killed
    (sleep_until
        (or
            (volume_test_players_any override_pool_past)
            (volume_test_players_any override_cliffs_path_bowl)
            (and
                (= 0 (ai_living_count override_pool/boss))
                (= 0 (ai_living_count override_pool/boss_spawn))
            )
        )
    )

    ;; Checkpoint
    (game_save_no_timeout)

    ;; Berserk some dudes
    (ai_berserk override_pool/fodder_left true)

    ;; Fodder is forced to retreat no matter what (though changing based on how far along the fight was)
    (ai_retreat override_pool/fodder_left)
    (ai_retreat override_pool/fodder_right)
    (ai_migrate override_pool/fodder_center override_pool/fodder_broken)

    ;; Wait for a player to mop up or move on
    (sleep_until
        (or
            (volume_test_players_any override_pool_past)
            (volume_test_players_any override_cliffs_path_bowl)
            (> 3 (ai_living_count override_pool))
        )
    )

    ;; Checkpoint
    (game_save_no_timeout)

    ;; Wait for a player to finish
    (sleep_until
        (or
            (volume_test_players_any override_pool_past)
            (= 0 (ai_living_count override_pool))
        )
    )

    ;; Handle jackasses
    (if (!= 0 (ai_living_count override_pool))
        (begin
            ;; Migrate units to continue to pursue a jackass player
            (ai_migrate override_pool override_vista/pool_cleanup)

            ;; The guards will also be alerted once the player enters their territory
            (ai_magically_see_players override_vista)
        )
    )

    ;; Checkpoint
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_override_pool_startup
    (wake m_override_pool)
)

(script static void m_override_pool_cleanup    
    (sleep -1 m_override_pool)
    (sleep -1 m_override_pool_music)
    (ai_erase override_pool)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_05_pool")
)

;; ---
;; VISTA
;; ---

(script dormant m_override_vista
    ;; Wait for a player
    (sleep_until (volume_test_players_any override_pool_rear))

    ;; Place guard dudes
    ;; (Note that they spawn blind, deaf, and brainead until someone passes the pool)
    (ai_place override_vista)
    
    ;; Special snipers for the special difficulty
    (if (not (game_is_easy))
        (ai_erase override_vista/ridge_snipers)
    )

    ;; Wait until a player passes pool
    (sleep_until (volume_test_players_any override_pool_past))
    
    ;; Ring ring, the alarm clock goes
    (ai_braindead override_vista false)
    (ai_set_deaf override_vista false)
    (ai_set_blind override_vista false)
    
    ;; Wait for a player to do shit
    (sleep_until
        (or
            (volume_test_players_any override_pit_approach_right)
            (< (ai_status override_vista) 4)
            (volume_test_players_any override_pit_approach_left)
        )
    )

    ;; Move in dudes
    (ai_migrate override_vista/right_guard_main override_vista/right_guard_main_a)
    (ai_migrate override_vista/right_guard_support override_vista/right_guard_support_e)

    ;; Wait for a player to do more shit
    (sleep_until
        (or
            (volume_test_players_any override_bridge_approach_left)
            (volume_test_players_any override_pit_approach_left)
        )
    )

    ;; Save game
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_override_vista_startup
    (wake m_override_vista)
)

(script static void m_override_vista_cleanup
    (sleep -1 m_override_vista)
    (ai_erase override_vista)
)

;; ---
;; PIT
;; ---

;; ---
;; AI migration

(global boolean m_override_pit_updater_start false)
(script continuous m_override_pit_updater
    (sleep_until m_override_pit_updater_start 1)

    ;; Send dudes based on side
    (cond
        (
            (volume_test_players_all override_pit_left)
            
            (ai_migrate override_pit/top_dudes override_pit/top_left)
            (ai_migrate override_pit/snipers override_pit/snipers_structure_left)
            (ai_migrate override_pit/ground_jackals override_pit/ground_jackals_left)
        )
        (
            (or
                (not (game_is_cooperative))
                (volume_test_players_all override_pit_right)
            )
            
            (ai_migrate override_pit/top_dudes override_pit/top_right)
            (ai_migrate override_pit/snipers override_pit/snipers_structure_right)
            (ai_migrate override_pit/ground_jackals override_pit/ground_jackals_right)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            
            (ai_migrate override_pit/top_dudes override_pit/top_all)
            (ai_migrate override_pit/snipers override_pit/snipers_structure_all)
            (ai_migrate override_pit/ground_jackals override_pit/ground_jackals_all)
        )
    )

    ;; Once a solo player alerts the top dudes, all other units are aware
    ;; CO-OP: But in multiplayer, the AI must remain ignorant or the illusion is broken
    (if
        (and
            (not (game_is_cooperative))
            (< 4 (ai_status override_pit/top_dudes))
        )
        (begin
            (ai_magically_see_players override_pit/top_dudes)
            (ai_magically_see_players override_pit/bridge_dudes)
        )
    )

    (sleep 30)
)

;; ---
;; Main progression

(script dormant m_override_pit
    ;; Let a player approach
    (sleep_until
        (volume_test_players_any override_pool_past)
    )

    ;; Place turrets
    (object_create sec_turret_low)
    (if (!= normal (game_difficulty_get_real))
        (object_create sec_turret_high)
    )

    ;; Cleanup
    (ai_erase override_cliffs_bowl)
    (ai_erase override_cliffs_canyon)

    ;; Place dudes
    (ai_place override_pit)
    
    ;; Legendary - get rid of this guy, he'll be replaced by an Elite
    ;; (Everybody else is taken care of in the squad spawn counts.)
    ;; Also get rid of him on special difficulty, helmets are a bad mechanic from halo reach which is a bad game we can have absolutely no mechanics from this bad game
    (if (or (game_is_easy) (game_is_impossible))
        (ai_erase override_pit/bridge_left_grunts_lead)
    )
    
    ;; Debug
    (if X_DBG_enabled
        (inspect (ai_living_count override_pit))
    )

    ;; Save
    (game_save_no_timeout)

    ;; Wait for a player to approach
    (sleep_until
        (or
            (volume_test_players_any override_pit_approach_left)
            (volume_test_players_any override_pit_approach_right)
            (volume_test_players_any override_pit_left)
            (volume_test_players_any override_pit_right)
            (>= (ai_status override_pit) 4)
        )
    )
    
    ;; Save
    (game_save_no_timeout)

    ;; Send Grunts to turret
    (ai_go_to_vehicle override_pit/top_grunts sec_turret_high "gunner")
    (ai_go_to_vehicle override_pit/ground_grunts sec_turret_low "gunner")

    ;; Begin update
    (set m_override_pit_updater_start true)

    ;; Wait for damage to be taken, or a player to alert the ground
    (sleep_until
        (or
            (> 0.9 (ai_living_fraction override_pit))
            (and
                (volume_test_players_any override_pit_ground_level)
                (<= (ai_status override_pit) 4)
            )
        )
    )

    ;; Save
    (game_save_no_timeout)

    ;; Send any remaining top dudes to turret
    (ai_go_to_vehicle override_pit/top_dudes sec_turret_high "gunner")
    (ai_go_to_vehicle override_pit/top_retreat sec_turret_high "gunner")
    (ai_go_to_vehicle override_pit/ground_guards sec_turret_low "gunner")

    ;; Wait for a player to advance
    (sleep_until
        (or
            (volume_test_players_any override_pit_mid_level)
            (volume_test_players_any override_pit_ground_level)
        )
    )

    ;; GC
    (garbage_collect_now)

    ;; Save
    (game_save_no_timeout)

    ;; Make Jackals be cohesive
    (ai_migrate override_pit/ground_jackals_init override_pit/ground_jackals_left)

    ;; Wait for players to kick ass and advance
    (sleep_until
        (and
            (> 0.75 (ai_living_fraction override_pit))
            (volume_test_players_any override_pit_ground_level)
        )
    )

    ;; Save
    (game_save_no_timeout)

    ;; Send out Elite
    (ai_migrate override_pit/ground_elites override_pit/ground_grunts)

    ;; Replace Jackals if they got their asses kicked
    (if (and
            (> 2 (ai_living_count override_pit/ground_jackals))
            (> 2 (ai_living_count override_pit/ground_jackals_init))
        )
        (begin
            (ai_place override_pit/ground_jackals_init)
            (ai_migrate override_pit/ground_jackals_init override_pit/ground_jackals_left)
        )
    )

    ;; Wait for players to mop up and advance
    (sleep_until
        (or
            (> 3 (ai_living_count override_pit/ground_guards))
            (volume_test_players_any override_shaft_server_entrance)
        )
    )
    
    ;; Clean up everyone
    (ai_migrate override_pit/ground_guards override_pit/ground_cleanup)

    ;; Kill update script
    (sleep -1 m_override_pit_updater)

    ;; Save
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_override_pit_startup
    (wake m_override_pit)
)

(script static void m_override_pit_cleanup
    (sleep -1 m_override_pit)
    (ai_erase override_pit)
)

(script static void m_override_pit_mark_return
    ;; Everyone at the pit but the ground and bridge goes away
    (ai_erase override_pit/top_dudes)
    (ai_erase override_pit/snipers)
    (ai_erase override_pit/top_retreat)
    (ai_erase override_pit/left_cliffs)
)


;; ---
;; BRIDGE
;; ---

;; ---
;; AI migration

(global boolean m_override_bridge_updater_start false)
(script continuous m_override_bridge_updater
    ;; Bridge guy stops doing whatever
    (ai_command_list_advance override_bridge/core_elites)
    
    ;; Just move the perimeter around. Simpler encounter for once!
    (cond    
        ;; Left side
        (     
            (volume_test_players_all override_bridge_left_side)
            
            (ai_migrate override_bridge/right_side_elites override_bridge/left_side_elites)
            (ai_migrate override_bridge/right_side_grunts override_bridge/left_side_grunts)

            (ai_migrate override_bridge/right_front_elites override_bridge/left_side_elites)
            (ai_migrate override_bridge/right_front_grunts override_bridge/left_side_grunts)
            
            (ai_migrate override_bridge/perimeter_elites override_bridge/left_side_elites)
            (ai_migrate override_bridge/perimeter_grunts override_bridge/left_side_grunts)
        )
        ;; Right side
        (    
            (volume_test_players_all override_bridge_right_side)
            
            (ai_migrate override_bridge/left_side_elites override_bridge/right_side_elites)
            (ai_migrate override_bridge/left_side_grunts override_bridge/right_side_grunts)

            (ai_migrate override_bridge/right_front_elites override_bridge/right_side_elites)
            (ai_migrate override_bridge/right_front_grunts override_bridge/right_side_grunts)
            
            (ai_migrate override_bridge/perimeter_elites override_bridge/right_side_elites)
            (ai_migrate override_bridge/perimeter_grunts override_bridge/right_side_grunts)
            
        )
        ;; Right front
        (     
            (volume_test_players_all override_bridge_right_front)
            
            (ai_migrate override_bridge/right_side_elites override_bridge/right_front_elites)
            (ai_migrate override_bridge/right_side_grunts override_bridge/right_front_grunts)

            (ai_migrate override_bridge/left_side_elites override_bridge/right_front_elites)
            (ai_migrate override_bridge/left_side_grunts override_bridge/right_front_grunts)
            
            (ai_migrate override_bridge/perimeter_elites override_bridge/right_front_elites)
            (ai_migrate override_bridge/perimeter_grunts override_bridge/right_front_grunts)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            
            (ai_migrate override_bridge/left_side_elites override_bridge/perimeter_elites)
            (ai_migrate override_bridge/left_side_grunts override_bridge/perimeter_grunts)
            
            (ai_migrate override_bridge/right_side_elites override_bridge/perimeter_elites)
            (ai_migrate override_bridge/right_side_grunts override_bridge/perimeter_grunts)

            (ai_migrate override_bridge/right_front_elites override_bridge/perimeter_elites)
            (ai_migrate override_bridge/right_front_grunts override_bridge/perimeter_grunts)
        )
    )

    (sleep 60)
)

;; ---
;; Main progression

(script dormant m_override_bridge
    ;; Wait for a player to enter general area
    (sleep_until
        (or
            (volume_test_players_any override_pool_rear)
            (volume_test_players_any override_bridge_approach_left)
            (volume_test_players_any override_bridge_approach_right)
            (volume_test_players_any override_cliffs_smartass)
        )
    )

    ;; Place dump
    (object_create_containing dump_bridge)

    ;; Place dudes
    (ai_place override_bridge)
    
    ;; Special Hunters for the special difficulty
    (if (game_is_easy)
        (ai_erase override_bridge/core_elites)
        (ai_erase override_bridge/hunters_easy)
    )
    
    ;; Place shade
    (object_create bridge_turret_1)

    ;; Wait for a player to approach area
    (sleep_until
        (or
            (volume_test_players_any override_bridge_approach_left)
            (volume_test_players_any override_bridge_approach_right)
        )
    )

    ;; Engage turret
    (ai_go_to_vehicle override_bridge/core_turret_grunts bridge_turret_1 "gunner")

    ;; Wait for players to kick some ass, or one to move on
    (sleep_until
        (or
            (> 1 (ai_living_fraction override_bridge))
            (<= 4 (ai_status override_bridge))
            (volume_test_players_any return_downed_main)
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Pushed-back perimeter Grunts may now use turret
    (ai_go_to_vehicle override_bridge/core_grunts bridge_turret_1 "gunner")

    ;; Wake update script
    (set m_override_bridge_updater_start true)

    ;; Wait for players to kick some more ass, or one to move on
    (sleep_until
        (or
            (> 0.66 (ai_living_fraction override_bridge))
            (volume_test_players_any end_bridge)
        )
    )

    ;; Patrol moves in to help their (surely doomed) buddies
    (ai_migrate override_bridge/patrol override_bridge/left_side_grunts)

    ;; Elites may now use turret
    (ai_go_to_vehicle override_bridge/core_elites bridge_turret_1 "gunner")

    ;; Wait for players to kick some seriously major ass, or one to give up and move on
    (sleep_until
        (or
            (> 0.33 (ai_living_fraction override_bridge))
            (volume_test_players_any end_bridge)
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; AI takes up defensive positions
    (ai_migrate override_bridge override_bridge/core_turret_grunts)

    ;; Wait for players to kick total ass, or one to move on
    (sleep_until
        (or
            (= 0 (ai_living_count override_bridge))
            (volume_test_players_any end_bridge)
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; End update script
    (sleep -1 m_override_bridge_updater)
)

(script dormant m_override_bridge_returning
    ;; bridge guys will know the player is coming now
    (ai_set_current_state override_bridge search)
    
    ;; engage covenant medical supplies >:)
    (ai_renew override_bridge)
    
    ;; await a player's arrival at bridge structure
    (sleep_until
        (volume_test_players_any override_bridge_left_side)
    )
    
    ;; the bridge guys knew you would come
    (ai_magically_see_players override_bridge)
    
    ;; checkpoint again
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_override_bridge_startup
    (wake m_override_bridge)
)

(script static void m_override_bridge_cleanup
    (sleep -1 m_override_bridge)
    (sleep -1 m_override_bridge_updater)
    (sleep -1 m_override_bridge_returning)
    
    (ai_erase override_bridge)
    (object_destroy bridge_turret_1)
)

(script static void m_override_bridge_mark_return
    (wake m_override_bridge_returning)
)


;; ---
;; MAIN MISSION
;; ---

;; ---
;; Lock sequence

;; DO NOT CHANGE THESE!
(global short cl_init 0)
(global short cl_in_bsp 1)
(global short cl_at_window 2)
(global short cl_locking 3)
(global short cl_locked 4)
(global short cl_postlock 5)
(global short cl_finshed 10)

;; Mission state
(global short m_override_cart_lock_state cl_init)
(global boolean m_override_known_locked false)

(script dormant m_override_chapter_cart_lock
    ;; Save the game
    (game_save_no_timeout)

    ;; Locked conversation
    (if (game_is_easy)
        (ai_conversation override_known_locked_special)
        (ai_conversation override_known_locked)
    )

    ;; Wait for a player to kill everyone or run
    (sleep_until
        (or
            (volume_test_players_any ext_cart_entrance_hall)
            (<= (ai_living_count override_locked) 1)
        )
        1
    )

    ;; Delay a few seconds to avoid being obvious
    (sleep 120)

    ;; New music cue
    (cinematic_show_letterbox 1)
    (show_hud false)
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")
    
    ;; Wait for letterbox to turn on
    (sleep 60)
    
    ;; Chapter title goes up
    (cinematic_set_title "locked")

    ;; + 10 seconds
    (sleep 300)

    ;; Take off chapter
    (cinematic_show_letterbox 0)
    (show_hud 1)

    ;; Mark the objective
    (objective_set dia_override obj_override)
    
    ;; If nobody else turns off the music soon, we should
    (sleep 5400)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")
)

(script dormant m_override_cart_lock
    ;; Don't do anything if we've been cancelled
    (if (= m_override_cart_lock_state cl_finshed)
        (sleep_forever)
    )

    ;; "i like to eat poo poo and drink pee pee" - unknown TSC:E developer
    (sleep_until (= (structure_bsp_index) bsp_index_int_shaft_a))
    (set m_override_cart_lock_state cl_in_bsp) 

    ;; Ignore if the door is unlocked
    (if
        (or
            mission_security_unlocked
            (= 1 (device_group_get power_security))
        )
        (sleep_forever)
    )

    ;; Places the dudes
    (ai_place override_locked)

    ;; Make the locker guy do his thing and ignore everything
    (ai_braindead override_locked/locker_elite true)
    (object_cannot_take_damage (list_get (ai_actors override_locked/locker_elite) 0))

    ;; Wait for a player to go to the window
    (sleep_until (volume_test_players_any override_lock_window) 1)
    (set m_override_cart_lock_state cl_at_window) 

    ;; Save game
    (game_save_no_timeout)

    ;; Ignore if the shaft was unlocked
    (if mission_security_unlocked
        (begin
            (ai_erase override_locked/locker_elite)
            (sleep_forever)
        )
    )

    ;; Have the AI conversation about locking
    (ai_conversation_stop ext_cart_entered)
    (ai_conversation_stop ext_cart_deep)
    (ai_conversation override_lock_alert)

    ;; Command list??
    (ai_command_list override_locked/locker_elite override_lock)

    ;; Wait for a player to approach or kick ass or run like a baby
    (sleep_until
        (or
            (> 4 (ai_living_count override_locked))
            (volume_test_players_any override_lock_slam)
            (volume_test_players_any ext_cart_main)
        )
        1
        30
    )
    (set m_override_cart_lock_state cl_locking) 

    ;; Have golden dude play his locking animation
    (ai_command_list_advance override_locked/locker_elite)
    
    ;; Wait for him to finish before locking the door
    (skip_half_second)
    (set m_override_cart_lock_state cl_locked)

    ;; Lock the door
    (device_set_position int_shaft_a_override_door 0)

    ;; Mark that the door is locked
    (set m_override_known_locked true)

    ;; Wait a little bit for the sequence to finish
    (sleep 90)
    (set m_override_cart_lock_state cl_postlock)

    ;; Chapter
    (wake m_override_chapter_cart_lock)

    ;; Done
    (set m_override_cart_lock_state cl_finshed)
)

(script dormant m_override_cart_lock_sbrk
    ;; Clever clever
    (sleep_until
        (and
            (= mission_state mission_cartographer_entered)
            (not mission_security_unlocked)
        )
        1
    )
    
    ;; This is too dangerous a move to risk saving, cancel checkpoints
    (game_save_cancel)

    ;; Immediately kill these guys
    (sleep -1 m_override_cart_lock)
    (sleep -1 m_override_chapter_cart_lock)

    ;; Take off chapter
    (cinematic_show_letterbox 0)
    (show_hud 1)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")

    ;; Engage, uh, active camo
    (ai_erase override_locked/locker_elite)
    (device_set_position int_shaft_a_override_door 1)

    ;; This is a ballsy move, even for the Chief
    (ai_conversation_stop override_lock_alert)
    (ai_conversation_stop override_known_locked)
    (ai_conversation wtf)

    ;; Good job...?
    (set m_override_known_locked true)
    (if (game_is_easy)
        (objective_set dia_found_ez obj_found_ez)
        (objective_set dia_found obj_found)
    )

    ;; I guess...?
    (sleep_until (volume_test_players_any ext_beach_2_dumb) 1)
    (ai_conversation wtf2)
)

;; ---
;; Unlock cutscene

(script static void m_override_setup_return
    (ai_place return_downed_waterfall_fake)
    (ai_vehicle_enterable_distance return_downed_wraith 20)
    (ai_vehicle_enterable_team return_downed_wraith covenant)
    (ai_vehicle_encounter return_downed_wraith r_downed_wrth_ext_sec-cave/b)
    (vehicle_load_magic return_downed_wraith "driver" (ai_actors return_downed_waterfall_fake/wraith_pilot))
)

(script dormant m_override_cutscene_unlock_effe
    (player_effect_set_max_translation 0 0 0)
    (player_effect_set_max_rotation 0 0 0)
    (player_effect_set_max_vibrate 0.15 0.15)
    
    ;; Strut 1 takes a little longer to get going
    (sleep 75)
    (player_effect_start 1 0.1)
    (player_effect_stop 0.4)
    
    ;; Strut 2
    (sleep 70)
    (player_effect_start 1 0.1)
    (player_effect_stop 0.4)
    
    ;; Strut 3
    (sleep 70)
    (player_effect_start 0.8 0.1)
    (player_effect_stop 0.4)
    
    ;; Strut 4 is farther off camera, use less intensity
    (sleep 70)
    (player_effect_start 0.25 0.1)
    (player_effect_stop 0.4)
)

(script static void m_override_cutscene_unlock
    ;; Disable input
    (player_enable_input 0)

    ;; Fade out
    (fade_to_white)
    (skip_second)

    ;; Once faded, start cinematic, turn off HUD
    (show_hud false)
    (cinematic_start)
    (camera_control true)

    ;; ---

    ;; If the door was never locked, we'll lock it anyway, just for cinematic effect
    (device_set_position_immediate int_shaft_a_override_door 0)

    ;; Switch to interior, set necessary PVS
    (switch_bsp bsp_index_int_shaft_a)
    (object_pvs_activate int_shaft_a_override_door)

    ;; Place golden boy, erase his clone
    (ai_erase override_locked)
    (ai_place unlock_elite)

    (if (game_is_easy)
        (ai_place unlock_slaughter)
    )

    ;; Set camera position
    (camera_set shaft_switch_1 0)

    ;; 3 second pause before fading back in
    (sleep 90)

    ;; 6-second camera sweep across room
    (camera_set shaft_switch_3 180)

    ;; 2-second fade back in (4 seconds remain in camera sweep)
    (fade_from_white)
    (skip_second)

    ;; Unlock door, wait 1 second (3 seconds remain in camera sweep)
    (device_set_position int_shaft_a_override_door 1)
    (skip_second)

    ;; Once door is unlocked, send golden boy out to investigate
    (if (game_is_easy)
        (begin
            (ai_braindead unlock_elite false)
            (ai_magically_see_encounter unlock_elite unlock_slaughter)
        )
        (ai_command_list unlock_elite override_unlock)
    )

    ;; Wait 1.5 seconds then give the Cortana line (1.5 seconds remain in camera sweep)
    (sleep 45)
    (if (< mission_state mission_cartographer_entered)
        (if m_override_known_locked
            (ai_conversation override_switch_known)
            (if (game_is_easy)
                (ai_conversation override_switch_unknow_special)
                (ai_conversation override_switch_unknow)
            )
        )
    )

    ;; Wait for remainder of camera sweep
    (sleep 75)

    ;; Fade back out to black
    (if (game_is_easy)
        (fade_out 1 0 0 30)
        (fade_to_white)
    )
    (skip_second)

    ;; Erase golden boy 
    (ai_erase unlock_elite)
    (ai_erase unlock_slaughter)

    ;; Bridge shot
    (switch_bsp bsp_index_ext_bridge)

    ;; Set up cyborg stuff
    (teleport_players player_unlock_wait player_unlock_wait)
    (skip_frame)
    
    (X_CUT_setup_player0 unlock_cyborg_0)
    (unit_set_seat unlock_cyborg_0 alert)
    
    ;; CO-OP: If more players are added, set up all of them here
    (if (game_is_cooperative)
        (begin
            (X_CUT_setup_player1 unlock_cyborg_1)
            (unit_set_seat unlock_cyborg_1 alert)
            
            (if (game_is_easy)
                (object_teleport unlock_cyborg_1 unlock_easy_leave)
            )
        )
    )

    ;; Sleep for a couple of ticks to get camera moving and ensure player hears bridge sound
    (camera_set cutscene_unlock_1a 0)
    (camera_set cutscene_unlock_1b 220)
    (sleep 5)

    ;; 1-second fade back in as bridge activates
    (fade_from_white)
    (device_group_set position_ext_sec_big_bridge 0)
    (wake m_override_cutscene_unlock_effe)
    (skip_second)

    ;; Camera rotates over bridge, then toward UFO
    (recording_play unlock_cyborg_0 unlock_cyborg_walk)
    (sleep 105)
    (camera_set cutscene_unlock_1c 150)
    (sleep 150)

    ;; Go back to UFO BSP
    (switch_bsp bsp_index_ext_ufo)

    ;; Cut close to UFO, zoom in toward walking player0
    (camera_set cutscene_unlock_2a 0)
    (camera_set cutscene_unlock_2b 210)
    
    ;; Oh.
    (if (and (game_is_cooperative) (game_is_easy))
        (recording_play unlock_cyborg_1 unlock_cyborg_leave)
    )

    ;; Hologram transforms
    (device_group_set position_ext_sec_security_holo 1)
    (sleep 30)
    
    ;; Player1 checks it out
    (if (and (game_is_cooperative) (not (game_is_easy)))
        (custom_animation unlock_cyborg_1 "cmt\characters\_shared\cyborg\cinematics\animations\level_specific\b30_revamp\b30_revamp" "look_with_intent" false)
    )
    (sleep 180)

    ;; Fade out cutscene
    ;; Special color for special difficulty
    (if (game_is_easy)
        (fade_out 1 0 0 30)
        (fade_to_white)
    )

    ;; Cleanup
    ;; CO-OP: If more players are added, clean up all of them here
    (teleport_players player_unlock_end_0 player_unlock_end_1)
    (X_CUT_teardown_player0 unlock_cyborg_0)
    (if (game_is_cooperative)
        (X_CUT_teardown_player1 unlock_cyborg_1)
    )

    ;; ---

    ;; Set up the canyon Phantom
    (create_override_cliffs_cship)

    ;; Teleport and fly away
    (if (game_is_easy)
        (object_teleport override_cliffs_cship return_cliffs_cship_flag_easy)
        (object_teleport override_cliffs_cship return_cliffs_cship_flag)
    )
    (recording_play_and_delete override_cliffs_cship return_cliffs_cship_out)

    ;; Return camera control to players, but keep the letterbox
    (camera_control false)
    (cinematic_stop)
    (cinematic_show_letterbox true)

    ;; 2-second fade back in
    ;; Special color for special difficulty
    (if (game_is_easy)
        (fade_in 1 0 0 60)
        (fade_from_white)
    )
    (skip_second)

    ;; Once faded in, enable input
    (player_enable_input true)

    ;; Checkpoint
    (game_save_totally_unsafe)

    ;; Set cinematic title
    (cinematic_set_title unlocked)

    ;; Leave title up for 5 seconds
    (sleep 150)

    ;; Show HUD again
    (show_hud true)
    (cinematic_show_letterbox false)
)

(script dormant m_override_unlock
    ;; Wait for player to enter the UFO's control center
    (print_debug "m_override_unlock: waiting for player to enter UFO control center")
    (sleep_until (volume_test_players_any override_ufo_control))
    (print_debug "m_override_shaft: player at UFO control center")
    
    ;; Save game
    (game_save_no_timeout)

    ;; Play conversation to unlock
    (if m_override_known_locked
        (ai_conversation override_switchit_known)
        (if (game_is_easy)
            (ai_conversation override_switchit_unkno_special)
            (ai_conversation override_switchit_unknow)
        )
    )

    ;; Wait until a player activates security device
    (sleep_until
        (= 0 (device_get_position ext_sec_security_switch))
        1
    )

    ;; Another door has opened somewhere...
    ;; This has to be immediate to make associated elevators work, for unclear reasons.
    (device_group_set_immediate power_security 1)
    
    ;; Cutscene
    (m_override_cutscene_unlock)

    ;; Mark security as unlocked
    (set mission_security_unlocked true)

    ;; Is a player doing something terrible?
    (if (< mission_state mission_cartographer_activated)
        (sleep -1)
    )
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_24_cruel")
    (sleep 5400)
    (ai_conversation cruel)
)

(script dormant m_override_prereturn
    ;; Wait for a player to approach elevator / UFO
    (sleep_until
        (or
            (volume_test_players_any override_ufo_elev_bot)
            (volume_test_players_any override_ufo_control)
            mission_security_unlocked
        )
    )
    
    ;; Set up the waterfall camp units in preparation for the return mission
    (m_override_setup_return)
)

;; ---
;; Mission hooks

(script static void m_override_launch_common
    ;; Fake lock sequence
    (device_set_position_immediate int_shaft_a_override_door 0)
    (ai_place override_locked/locker_elite)
    (ai_braindead override_locked/locker_elite true)
    (set m_override_cart_lock_state cl_finshed)
    (set m_override_known_locked true)
)

(script static void m_override_launch
    ;; Run common override launch logic
    (m_override_launch_common)
    
    ;; Move the hog to where the players left it
    (object_create ext_drop_hog)
    (unit_enter_vehicle (ai_actor lz_marines_holding 0) ext_drop_hog "w-gunner")
    (unit_enter_vehicle (ai_actor lz_marines_holding 1) ext_drop_hog "w-passenger")
    (object_teleport ext_drop_hog m_override_hogspawn)
    (ai_migrate_by_unit (vehicle_riders ext_drop_hog) marines_ext_capp-cart)
    
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_int_shaft_a m_override_spawn_0 m_override_spawn_1)
    
    ;; Chapter simulates continuing cinematic
    (cinematic_show_letterbox 1)
    (show_hud false)
    (wake m_override_chapter_cart_lock)
)

(script static void m_override_launch_pool
    ;; Run common override launch logic
    (m_override_launch_common)
    
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_ext_pool m_override_pool_spawn_0 m_override_pool_spawn_1)
)

(script static void m_override_start
    (print_debug "m_override_start: starting")

    ;; Launch mission if we have to
    (if (= b30r_launch_override mission_launch_index)
        (m_override_launch)
    )
    (if (= b30r_launch_override_a mission_launch_index)
        (m_override_launch_pool)
    )

    ;; Wake the lock sequence
    (wake m_override_cart_lock)
    (wake m_override_cart_lock_sbrk)
    (wake m_override_unlock)
    (wake m_override_prereturn)
    
    ;; Start all sub-missions
    (if (!= b30r_launch_override_a mission_launch_index)
        (begin
            (m_override_cliffs_startup)
            (m_override_pool_startup)
        )
    )
    (m_override_vista_startup)
    (m_override_pit_startup)
    (m_override_bridge_startup)
    (m_override_shaft_startup)
    
)

(script static void m_override_clean
    ;; Clean all sub-missions
    (m_override_cliffs_cleanup)
    (m_override_pool_cleanup)
    (m_override_vista_cleanup)
    (m_override_pit_cleanup)
    (m_override_bridge_cleanup)
    (m_override_shaft_cleanup)

    ;; Let's be courteous to free-roaming players and say they rode the elevator back down
    (device_group_set_immediate position_ext_cave_ufo_elevator 0)

    ;; The Wraith got, uh, destroyed. By the marines. Yeah.
    (object_destroy return_downed_wraith)
)

(script static void m_override_return
    ;; Cart lock sequence can no longer happen
    (sleep -1 m_override_cart_lock)

    ;; These encounters are on the players' path back
    (m_override_pit_mark_return)
    (m_override_bridge_mark_return)
    (m_override_shaft_mark_return)
    
)

(script static void m_override_skip
    ;; Mark security as unlocked
    (set m_override_known_locked true)
    (set mission_security_unlocked true)

    ;; The Hunter elevator was cleared
    (device_group_set_immediate position_ext_cave_hunter_bridge 1)
    (device_group_set_immediate position_ext_cave_ufo_elevator 1)

    ;; Security was deactivated
    (device_set_position ext_sec_security_switch 0)
    (device_group_set_immediate power_security 1)
    (device_group_set_immediate position_ext_sec_big_bridge 0)
    (device_group_set_immediate position_ext_sec_security_holo 1)
    (device_set_position_immediate int_shaft_a_override_door 1)

    ;; The dudes at the downed Pelican have their cars
    (m_override_setup_return)

    ;; Prevent lock sequence from happening
    (set m_override_cart_lock_state cl_finshed)
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - Return
;; 4 - End
(global long m_override_ctrl_state 0)

(script dormant m_override_control
    (if (!= m_override_ctrl_state 1)
        (m_override_skip)
        (m_override_start)
    )

    ;; For simplicity, we assume the return steps have happened before cleaning
    (sleep_until (>= m_override_ctrl_state 3))    
    (m_override_return) 

    (sleep_until (>= m_override_ctrl_state 4))
    (m_override_clean)
)

(script static void m_override_startup
    (if (= 0 m_override_ctrl_state)
        (begin
            (set m_override_ctrl_state 1)
            (wake m_override_control)
        )
    )
)

(script static void m_override_mark_return
    (set m_override_ctrl_state 3)
)

(script static void m_override_cleanup
    (set m_override_ctrl_state 4)
)

(script static void m_override_mark_skip
    (m_override_startup)
    (set m_override_ctrl_state 2)
)