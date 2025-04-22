;; 11_b30_revamp_mission_return.hsc
;; Mission to return to the Cartographer, triggered after the completion of "override"
;; ---

;; ---
;; CRASH SITE
;; ---

;; ---
;; Music

(global boolean return_downed_music_started false)

(script dormant m_return_downed_music
    ;; Wait for a player to get on the bridge
    (sleep_until (volume_test_players_any override_bridge_halfway) 1)
    
    ;; Turn on ominous strings until someone makes it to the other side
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_09_crashsite")
    (set return_downed_music_started true)
    
    ;; Wait for a player to pick a path
    ;; Don't need the strings anymore, cool music instead
    (sleep_until
        (or
            (volume_test_players_any return_downed_funnel_left)
            (volume_test_players_any return_downed_funnel_right)
        )
    )
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_09_crashsite")
    
    ;; Special music for the special difficulty
    (if (game_is_easy)
        (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11b_return_easymode")
        (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
    )
    
    ;; Cellos automatically timed to come in around beach_2

    ;; Guitars once someone makes it to the cart
    (sleep_until
        (and
            (= (structure_bsp_index) bsp_index_ext_cart)
            (or
                (volume_test_players_any ext_cart_return_approaching)
                (volume_test_players_any ext_cart_terrain_front)
            )
        )
    1)
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11b_return_easymode")
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
    
    ;; Wait until a player's heading into the shaft or everyone's dead
    (sleep 300)
    (sleep_until
        (or
            (volume_test_players_any ext_cart_entrance)
            (volume_test_players_any ext_cart_secret_inside)
        )
    )

    ;; Stop the music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11b_return_easymode")
)

(global boolean m_return_downed_music_start false)
(script continuous m_return_downed_music_fucker
    (sleep_until m_return_downed_music_start 1)

    (sleep_until
        (and
            return_downed_music_started
            (or
                (volume_test_players_any override_pool_past)
                (volume_test_players_any ext_cart_smallgorge)
            )
        )
    )
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_09_crashsite")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11b_return_easymode")
    (sleep_until
        (and
            (not (volume_test_players_any override_pool_past))
            (not (volume_test_players_any ext_cart_smallgorge))
        )
    )
)

;; ---
;; Phantom harassment

(global boolean return_cship_start false)
(global boolean return_cship_leave false)
(script continuous return_cship_harass
    (sleep_until return_cship_start 1)

    (if return_cship_leave
        (begin
            ;; Un-hover the Phantom
            (vehicle_hover ext_beach_1_cship false)
            (recording_play_and_delete ext_beach_1_cship return_cship_out)
            (sleep_forever)
        )
    )

    ;; Play the idle animation
    (phantom_hover_and_bank ext_beach_1_cship)
)

;; ---
;; Mission scripts

(script dormant m_return_downed
    ;; Save game
    (game_save_no_timeout)

    ;; The Phantom pounding the Marines
    (create_ext_beach_1_cship)
    (object_teleport ext_beach_1_cship bridge_flavor_cship_flag_2)
    (vehicle_hover ext_beach_1_cship true)

    ;; Wake the return cship scripts
    (set return_cship_start true)

    ;; GC
    (garbage_collect_now)

    ;; Re-place the potentially GC'd turret
    (object_create bridge_turret_1)
    
    ;; Await a player's arrival at bridge end
    (sleep_until
        (or
            (volume_test_players_any override_bridge_left_side)
            (volume_test_players_any return_downed_main)
        )
    )
    
    ;; Save
    (game_save_no_timeout)

    ;; Await a player's arrival at bridge structure
    (sleep_until 
        (or
            (volume_test_players_any override_bridge_left_side)
            (volume_test_players_any return_downed_main)
        )
    1)
    (print_debug "m_return_downed: player looks like they're taking the bridge path")

    ;; Spawn crashsite AI
    (ai_place return_downed_marines/crashsite_marines)
    (ai_place return_downed/crashsite_grunts)
    
    ;; Yoink
    (ai_erase return_downed_waterfall_fake)
    
    ;; Special Marines for the special difficulty
    (if (game_is_easy)
        (begin
            (ai_place return_downed_marines/crashsite_jerks)
            (ai_set_team return_downed_marines/crashsite_jerks sentinel)
            (ai_place johnson)
        )
    )

    ;; Normal - Jackal only; heroic - Elite only; legendary - both; easy - neither
    (if (or
            (= normal (game_difficulty_get_real))
            (game_is_impossible)
        )
        (ai_place return_downed/crashsite_jackal)
    )
    (if (or
            (= hard (game_difficulty_get_real))
            (game_is_impossible)
        )
        (ai_place return_downed/crashsite_elite)
    )

    ;; Marines ignore the Phantom
    (ai_try_to_fight return_downed_marines return_downed)

    ;; Don't let them kill each other
    (ai_playfight return_downed_marines true)
    (ai_playfight return_downed true)
    (ai_playfight return_downed_waterfall true)
    (ai_playfight r_downed_wrth_ext_sec-cave true)
    (object_cannot_take_damage (ai_actors return_downed_marines))
    
    ;; Fuck you HCE
    (ai_magically_see_encounter return_downed_marines return_downed)
    (ai_magically_see_encounter return_downed return_downed_marines)

    ;; Checkpoint
    (game_save_no_timeout)

    ;; Wait until a player's ~halfway across
    (sleep_until 
        (or
            (volume_test_players_any override_bridge_halfway) 
            (volume_test_players_any return_downed_main)
        )
    1)

    ;; Now the waterfall camp units
    (ai_place return_downed_waterfall)
    ;; ...but have them deaf for now
    (ai_set_deaf return_downed_waterfall true)
    (ai_braindead return_downed_waterfall/funnel_left true)

    ;; Just get rid of these dumbfuck apes on special difficulty
    (if (game_is_easy)
        (ai_erase return_downed_waterfall/funnel_right)
    )

    ;; Special car behavior
    (ai_vehicle_enterable_distance return_downed_wraith 20)
    (ai_vehicle_enterable_team return_downed_wraith covenant)
    (vehicle_load_magic return_downed_wraith "driver" (ai_actors return_downed_waterfall/wraith_pilot))
    (ai_renew return_downed_marines)
    (ai_go_to_vehicle return_downed_waterfall/shade_pilot return_downed_turret "gunner")
    
    ;; Everybody gets a checkpoint
    (game_save_no_timeout)

    ;; Wait for a player to get to the other side
    (sleep_until 
        (or
            (volume_test_players_any end_bridge)
            (volume_test_players_any return_downed_main)
        )
        1
    )

    ;; "good to see you sir!!! wow! haha"
    (if (game_is_easy)
        (ai_conversation johnson)
        (ai_conversation downed_arrival)
    )
    
    ;; Special traitors for the special difficulty
    (ai_allegiance_remove human sentinel)

    ;; Phantom goes away
    (set return_cship_leave true)

    ;; Set Plasma Rifles to kill
    (ai_playfight return_downed_marines false)
    (ai_playfight return_downed false)
    (ai_playfight return_downed_waterfall false)
    (ai_playfight r_downed_wrth_ext_sec-cave false)
    (object_can_take_damage (ai_actors return_downed_marines))

    ;; Marines fall back
    (ai_defend return_downed_marines/marines)

    ;; Wait a minute aren't you somewhere else?
    (if (game_is_easy)
        (begin
            ;; Wait until conversation waiting to advance
            (sleep_until (<= 4 (ai_conversation_status johnson)))
            (ai_conversation_advance johnson)

            ;; Voip
            (effect_new_on_object_marker "cmt\effects\shared effects\teleport" johnson "")
            (sleep 10)
            (object_destroy johnson)
        )
    )

    ;; Wait for a player to get in the hog or advance
    (sleep_until
        (or
            (vehicle_test_seat_list return_downed_dump_hog "w-driver" (players))
            (volume_test_players_any return_downed_leaving)
        )
        1
    )
    
    ;; Heal up the Marines
    (ai_renew return_downed_marines)
    
    ;; Units can get in the turret now
    (ai_vehicle_enterable_distance return_downed_turret 3)

    ;; Wow that sure was hard better save
    (game_save_no_timeout)

    ;; Un-deaf the next encounter and have the left funnel advance
    (ai_set_deaf return_downed_waterfall false)
    (ai_braindead return_downed_waterfall false)
    (skip_frame)
    (ai_magically_see_players return_downed_waterfall/funnel_left)

    ;; Merge any remaining crashsite units with the left funnel
    (ai_migrate return_downed return_downed_waterfall/funnel_left_elites)
    
    ;; Wait for a player to pick a path
    (sleep_until
        (or
            (volume_test_players_any return_downed_funnel_left)
            (volume_test_players_any return_downed_funnel_right)
        )
        1
    )

    ;; That turret is looking like a really good option, guys
    (ai_go_to_vehicle return_downed_waterfall/shade_pilot return_downed_turret "gunner")
    
    ;; Units in the selected path retreat; other path's units move to the clearing
    (if (volume_test_players_any return_downed_funnel_left)
        (begin
            (ai_migrate return_downed_waterfall/funnel_right_brute_followers return_downed_waterfall/clearing_grunts)
            (ai_migrate return_downed_waterfall/funnel_right_brute_leader return_downed_waterfall/clearing_elite)
        )
    )
    (if (volume_test_players_any return_downed_funnel_left)
        (begin
            (ai_migrate return_downed_waterfall/funnel_left_elites return_downed_waterfall/clearing_elite)
            (ai_migrate return_downed_waterfall/funnel_left_grunts return_downed_waterfall/clearing_grunts)
        )
    )
    
    ;; Wait for a player to enter clearing
    (sleep_until (volume_test_players_any return_downed_clearing) 1)

    ;; Remaining funnel units move to clearing, then adopt defensive positions
    (ai_migrate return_downed_waterfall/funnel_left_elites return_downed_waterfall/clearing_elite)
    (ai_migrate return_downed_waterfall/funnel_left_grunts return_downed_waterfall/clearing_grunts)
    (ai_migrate return_downed_waterfall/funnel_right_brute_followers return_downed_waterfall/clearing_grunts)
    (ai_migrate return_downed_waterfall/funnel_right_brute_leader return_downed_waterfall/clearing_elite)
    (ai_defend return_downed_waterfall/clearing)

    ;; Send Marines up
    (ai_migrate return_downed_marines/marines return_downed_marines/assault_left)

    ;; Wait for a player to drive past the AA Wraith
    (sleep_until (volume_test_players_any return_downed_jump) 1)
    
    ;; This is okay now
    (ai_follow_target_players r_downed_wrth_ext_sec-cave)

    ;; Send Marines up
    (ai_migrate return_downed_marines/marines return_downed_marines/assault_right)
    
    ;; Ka-ching
    (game_save_no_timeout)
    ;; This should be safe
    (garbage_collect_now)
    
    ;; Wait until a player exits the cave
    (sleep_until (volume_test_players_any ext_cave_exit) 1)
    
    ;; Those cave jumps are pretty precarious so give the players a checkpoint
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_return_downed_startup
    (print_debug "m_return_downed_startup")
    
    (wake m_return_downed)
    (wake m_return_downed_music)
    (set m_return_downed_music_start true)
)

(script static void m_return_downed_cleanup
    (print_debug "m_return_downed_cleanup")
    
    (ai_erase return_downed_waterfall)
    (ai_erase return_downed)
    
    (sleep -1 m_return_downed)
    (sleep -1 m_return_downed_music)
    (sleep -1 m_return_downed_music_fucker)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_09_crashsite")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
)

;; ---
;; CLIFFS
;; ---

;; ---
;; Music

(global boolean return_cliffs_music_started false)

(script dormant m_return_cliffs_music
    ;; Wait for a player to get on the bridge
    (sleep_until (volume_test_players_any override_cliffs_entrance) 1)
    
    ;; Turn on ominous hum until someone makes it to the cart
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
    (set return_cliffs_music_started true)
    
    ;; Wait for player to get into a battle
    (sleep_until
        (or
            (<= 4 (ai_status return_cart_field))
            (<= 4 (ai_status return_cart_entrance))
        )
    )
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
    
    ;; Aait until a player's heading into the shaft or everyone's dead
    (sleep 300)
    (sleep_until
        (volume_test_players_any ext_cart_entrance_past)
    )

    ;; Stop the music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
)

(global boolean m_return_cliffs_music_started false)
(script continuous m_return_cliffs_music_fucker
    (sleep_until m_return_cliffs_music_started)

    (sleep_until
        (and
            return_cliffs_music_started
            (or
                (volume_test_players_any override_bridge_crossing)
                (volume_test_players_any ext_cart_entrance_past)
            )
        )
    )
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
    (sleep_until
        (not 
            (or
                (volume_test_players_any override_bridge_crossing)
                (volume_test_players_any ext_cart_entrance_past)
            )
        )
    )
)

;; ---
;; Migration

(global boolean m_return_cliffs_canyon_start false)
(script continuous m_return_cliffs_canyon_automig
    (sleep_until m_return_cliffs_canyon_start 1)

    (sleep_until (= bsp_index_ext_sapp (structure_bsp_index)) 1)
    
    (ai_migrate return_cliffs_canyon/high return_cliffs_canyon_c/canyon_elite_ground_high)
    (ai_migrate return_cliffs_canyon/hole return_cliffs_canyon_c/canyon_jackals)
    (ai_migrate return_cliffs_canyon/mid return_cliffs_canyon_c/canyon_grunts_mid)
    (ai_migrate return_cliffs_canyon/low return_cliffs_canyon_c/canyon_grunts_low)
    
    (sleep_until (!= bsp_index_ext_sapp (structure_bsp_index)) 1)
    
    (ai_migrate return_cliffs_canyon_c/high return_cliffs_canyon/canyon_elite_ground_high)
    (ai_migrate return_cliffs_canyon_c/hole return_cliffs_canyon/canyon_jackals)
    (ai_migrate return_cliffs_canyon_c/mid return_cliffs_canyon/canyon_grunts_mid)
    (ai_migrate return_cliffs_canyon_c/low return_cliffs_canyon/canyon_grunts_low)
)

;; ---
;; Pool

(script dormant m_return_cliffs_pool
    (sleep_until 
        (or
            (volume_test_players_any override_pool_past)
            (volume_test_players_any override_pool_approach)
            (volume_test_players_any override_cliffs_smartass)
        )
        1
    )
    (print_debug "player looks like they're taking the cliff path")

    ;; Save
    (game_save_no_timeout)

    ;; Aliens
    (ai_place return_pool)

    ;; Wait for the players to alert the bad guys
    (sleep_until
        (or
            (> (ai_status return_pool) 3)
            (< (ai_living_count return_pool/pool_jackal_bait) 1)
        )
        1
    )

    ;; Elites should now move into position
    (ai_magically_see_players return_pool)

    ;; If for some reason the players haven't killed the bait jackal, move it in with the rest
    (ai_migrate return_pool/pool_jackal_bait return_pool/pool_jackals)

    ;; Wait until a player pushes forward
    (sleep_until
        (or
            (volume_test_players_any override_pool_enter_side)
            (volume_test_players_any override_pool_enter_back)
            (volume_test_players_any ext_canyon_main)
        )
        1
    )

    ;; Move units back if they're not already defending
    (ai_defend return_pool)

    ;; If only one Elite is left, retreat to the canyon encounter
    (if
        (or
            (< (ai_living_count return_pool/pool_elite_left) 1)
            (< (ai_living_count return_pool/pool_elite_right) 1)
        )
        (if (= bsp_index_ext_sapp (structure_bsp_index))
            (ai_migrate return_pool/back return_cliffs_canyon_c/pool_elites_retreat)
            (ai_migrate return_pool/back return_cliffs_canyon/pool_elites_retreat)
        )
    )

    ;; Pick where to create the Jackal wall
    (if (volume_test_players_any override_pool_enter_side)
        (ai_migrate return_pool/pool_jackals return_pool/pool_jackals_leftwall)
        (ai_migrate return_pool/pool_jackals return_pool/pool_jackals_rightwall)
    )

    (print_debug_if (volume_test_players_any override_pool_enter_side) "players heading up into canyon from left")
    (print_debug_if (volume_test_players_any override_pool_enter_back) "players heading up into canyon from right")
)

;; ---
;; Canyon

(script dormant m_return_cliffs_canyon
    ;; Wait until a player pushes forward
    (sleep_until
        (or
            (volume_test_players_any override_pool_enter_side)
            (volume_test_players_any override_pool_enter_back)
            (volume_test_players_any ext_canyon_main)
            (volume_test_players_any override_cliffs_smartass)
        )
        1
    )

    ;; Canyon units should now exist
    (ai_place return_cliffs_canyon)
    (set m_return_cliffs_canyon_start true)
    
    ;; Save
    (game_save_no_timeout)
    
    ;; Wait until either one Elite is left or a player makes it past it
    (sleep_until
        (or
            (< (ai_living_count return_pool/pool_elite_left) 1)
            (< (ai_living_count return_pool/pool_elite_right) 1)
            (volume_test_players_any override_pool_approach)
        )
        1
    )
    
    ;; Try to save
    (game_save_no_timeout)

    ;; Retreat whoever's alive in the pool if they're still here for some reason
    (ai_migrate return_pool/back return_cliffs_canyon/pool_elites_retreat)

    ;; Canyon units heard the commotion, ready to intercept
    (ai_magically_see_players return_cliffs_canyon)
    (ai_magically_see_players return_cliffs_canyon_c)

    ;; Wait until a player gets a ways into the canyon
    (sleep_until (volume_test_players_any override_cliffs_path_end) 1)

    ;; Retreat anybody who hasn't already
    (ai_defend return_cliffs_canyon)
    (ai_defend return_cliffs_canyon_c)

    ;; Wait to see what players do
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_arch_path)
            (volume_test_players_any override_cliffs_side_path)
        )
        1
    )

    ;; Migrate to new squads
    ;; (We can be pretty sure that one of the players is in the cart-sapp BSP now.)
    ;; (If they're both not, they're doing something funky anyway)
    (ai_migrate return_cliffs_canyon_c/pool_elites_retreat return_cliffs_canyon_c/canyon_elite_ground_low)
    (ai_migrate return_cliffs_canyon_c/canyon_elite_ground_high return_cliffs_canyon_c/canyon_elite_ridge_low)
    (ai_migrate return_cliffs_canyon_c/canyon_elite_ridge_high return_cliffs_canyon_c/canyon_elite_ground_low)
    (ai_migrate return_cliffs_canyon_c/canyon_grunts_mid return_cliffs_canyon_c/canyon_grunts_low)

    ;; If arch, move units to flank
    ;; Otherwise, keep retreating
    (if (volume_test_players_any override_cliffs_arch_path)
        (begin
            (ai_attack return_cliffs_canyon)
            (ai_attack return_cliffs_canyon_c)
            (print_debug "player moved through arch; units intercepting")
        )
        (begin
            (ai_defend return_cliffs_canyon)
            (ai_defend return_cliffs_canyon_c)
            (print_debug "player moved through side; units falling back")
        )
    )
)

;; ---
;; Bowl

(script dormant m_return_cliffs_bowl
    ;; Wait to see what players do
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_cliff_mid)
            (volume_test_players_any override_cliffs_arch_path)
            (volume_test_players_any override_cliffs_side_path)
        )
        1
    )

    ;; Place the bowl units
    (ai_place return_cliffs_bowl)

    ;; Try to save
    (game_save_no_timeout)

    ;; Migrate leftover units to the bowl
    (ai_migrate return_cliffs_canyon/low return_cliffs_bowl/canyon_retreat)
    (ai_migrate return_cliffs_canyon_c/low return_cliffs_bowl/canyon_retreat)

    ;; Bowl units ready to go
    (ai_magically_see_players return_cliffs_bowl)

    ;; Wait until a player moves into the bowl
    (sleep_until (volume_test_players_any override_cliffs_path_bowl))
    
    ;; Save
    (game_save_no_timeout)

    ;; Any units that aren't defending should be now
    (ai_defend return_cliffs_bowl)

    ;; Wait for a player to exit the bowl
    (sleep_until 
        (or
            (volume_test_players_any override_cliffs_path_nook)
            (volume_test_players_any override_cliffs_path_jump)
        )
        1
    )

    ;; Any remaining units pile on and harass the leaving player
    (ai_migrate return_cliffs_bowl return_cliffs_bowl/bowl_exit)
    
    ;; Save
    (game_save_no_timeout)
)

;; ---
;; Fodder

(script dormant m_return_cliffs_fodder
    ;; Wait for a player to exit the bowl or enter the fodder zone
    (sleep_until 
        (or
            (volume_test_players_any override_cliffs_path_bowl)
            (volume_test_players_any ext_cart_smallgorge)
        )
        1
    )

    ;; Save
    (game_save_no_timeout)
    
    ;; Place the other doods
    (ai_place return_cliffs_fodder)
    (ai_go_to_vehicle return_cliffs_fodder/fodder_grunts return_cliffs_turret "gunner")

    ;; Wait for a player to leave the area
    (sleep_until (volume_test_players_any override_cliffs_entrance))

    ;; Anyone can use the turret
    (ai_go_to_vehicle return_cliffs_fodder return_cliffs_turret "gunner")
    
    ;; Save
    (game_save_no_timeout)

    ;; Wait until a player clears fodder units
    (sleep_until
        (or
            (> 0.25 (ai_living_fraction return_cliffs_fodder))
            (volume_test_players_any ext_cart_smallgorge)
            (volume_test_players_any ext_canyon_main)
        )
    )
    
    ;; Save
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_return_cliffs_startup
    (print_debug "m_return_cliffs_startup")
    
    (wake m_return_cliffs_pool)
    (wake m_return_cliffs_canyon)
    (wake m_return_cliffs_bowl)
    (wake m_return_cliffs_fodder)
    (wake m_return_cliffs_music)
    (set m_return_cliffs_music_started true)
    
    (object_create_containing return_cliffs)
)

(script static void m_return_cliffs_cleanup
    (print_debug "m_return_cliffs_cleanup")
    
    (sleep -1 m_return_cliffs_pool)
    (sleep -1 m_return_cliffs_canyon)
    (sleep -1 m_return_cliffs_bowl)
    (sleep -1 m_return_cliffs_fodder)
    (sleep -1 m_return_cliffs_canyon_automig)
    (sleep -1 m_return_cliffs_music)
    (sleep -1 m_return_cliffs_music_fucker)
    
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
    
    (ai_erase return_pool)
    (ai_erase return_cliffs_canyon)
    (ai_erase return_cliffs_canyon_c)
    (ai_erase return_cliffs_bowl)
    (ai_erase return_cliffs_fodder)
)

;; ---
;; CART FIELD
;; ---

;; ---
;; Other events

(global boolean m_return_cart_assaulting false)
(global boolean m_return_cart_combat_begun false)

(script dormant m_return_cart_combat_beginner
    (sleep_until
        (or
            (>= 4 (ai_status return_cart_field))
            (>= 4 (ai_status return_cart_entrance))
        )
    )
    (set m_return_cart_combat_begun true)
    
    ;; Gahhhhhhhhhhhhhhh
    (if (not (game_is_easy))
        (object_create magic_shotgun)
    )

    ;; Good job, you made it here
    (game_save_no_timeout)
)

(script dormant return_cart_field_triggerer
    ;; Wait for combat to begin
    (sleep_until
        m_return_cart_combat_begun
    )

    ;; Just run in a loop giving snipers magical sight
    (sleep_until
        (begin
            ;; Snipers are all-knowing
            (ai_magically_see_players return_cart_field/snipers)
            false
        )
    )
)

;; ---
;; Hunters

(global boolean return_cart_hunters_start false)
(script continuous return_cart_hunters_updater
    (sleep_until return_cart_hunters_start 1)

    (cond
        (
            (or
                (volume_test_players_any ext_cart_entrance_past)
                (volume_test_players_any ext_cart_entrance_top)
                (volume_test_players_any ext_cart_secret_inside)
            )
            (ai_migrate return_cart_entrance/hunters return_cart_entrance/hunters_defending)
        )
        (
            (or
                (volume_test_players_any ext_cart_platform_left)
                (volume_test_players_any ext_cart_platform_right)
                (volume_test_players_any ext_cart_entrance)
            )
            (ai_migrate return_cart_entrance/hunters return_cart_entrance/hunters_pursuing)
        )
        
    )

    (if (volume_test_players_all ext_cart_side_right)
        (ai_migrate return_cart_entrance/hunters return_cart_entrance/hunters_pursuing_right)
    )
    (if (volume_test_players_all ext_cart_side_left)
        (ai_migrate return_cart_entrance/hunters return_cart_entrance/hunters_pursuing_left)
    )
)

(script dormant return_cart_hunters_triggerer
    ;; Hunters will charge if:
    ;;    1) A player enters hall
    ;;    2) A player jumps down from secret passage
    ;;    3) Entrance dudes are wiped out
    ;;     Regardless, Hunters are cautious and stay in the hall, only moving out to pursue.
    (sleep_until
        (or
            (<= 3 (ai_living_count return_cart_entrance))
            (volume_test_players_any ext_cart_entrance_past)
        )
    )

    ;; Send Hunters out + make them real mad
    (ai_migrate return_cart_entrance/hunters_spawn return_cart_entrance/hunters_pursuing)
    (ai_migrate return_cart_entrance/hunters_spawn_easy return_cart_entrance/hunters_pursuing)

    ;; Wake the hunter updater
    (set return_cart_hunters_start true)

    ;; Good job, you made it here
    (game_save_no_timeout)

    ;; Checkpoints for killing both Hunters
    (sleep_until (>= 1 (ai_living_count return_cart_entrance/hunters)))
    (game_save_no_timeout)
    (sleep_until (>= 0 (ai_living_count return_cart_entrance/hunters)))
    (game_save_no_timeout)
)

;; ---
;; Entrance squads

(global boolean return_cart_jackals_start false)
(script continuous return_cart_jackals_updater
    (sleep_until return_cart_jackals_start 1)

    (if
        (and
            (volume_test_players_any ext_cart_platform_left)
            (not (volume_test_players_any ext_cart_platform_right))
        )
        (ai_migrate return_cart_entrance/jackals return_cart_entrance/jackals_pursuing_left)
    )
    (if
        (and
            (volume_test_players_any ext_cart_platform_right)
            (not (volume_test_players_any ext_cart_platform_left))
        )
        (ai_migrate return_cart_entrance/jackals return_cart_entrance/jackals_pursuing_right)
    )
)

(script dormant return_cart_entrance_triggerer
    (sleep_until
        m_return_cart_combat_begun
    )
    
    ;; Set up the turrets
    (object_create_anew_containing return_cart_turret_)
    (ai_go_to_vehicle return_cart_entrance/fodder_grunts return_cart_turret_left "gunner")
    (ai_go_to_vehicle return_cart_entrance/fodder_grunts return_cart_turret_right "gunner")
    (ai_go_to_vehicle return_cart_entrance/fodder_grunts ext_cart_turret_front "gunner")
    (ai_vehicle_enterable_distance return_cart_turret_left 10)
    (ai_vehicle_enterable_distance return_cart_turret_right 10)
    (ai_vehicle_enterable_distance ext_cart_turret_front 10)
    
    ;; Let Jackals run around
    (set return_cart_jackals_start true)
)

;; ---
;; Wraiths

(script dormant return_cart_wraith_triggerer
    ;; Checkpoints for killing Wraiths
    (sleep_until (>= 0 (ai_living_count return_cart_wraith_1)))
    (game_save_no_timeout)
    (sleep_until (>= 0 (ai_living_count return_cart_wraith_2)))
    (game_save_no_timeout)
)

(script dormant return_cart_wdrop_triggerer
    ;; Wait until combat has begun, or a player is in the main area
    (sleep_until
        (or
            (volume_test_players_any ext_cart_terrain_front)
            (volume_test_players_any ext_cart_side_left)
            (volume_test_players_any ext_cart_side_right)
        )
    )
    
    ;; Wraith is dropped
    (unit_exit_vehicle return_cart_wraith_1)    
    
    ;; Good job, you made it here
    (game_save_no_timeout)
    
    ;; Don't enter Wraith until people are alerted
    (sleep_until
        m_return_cart_combat_begun
    )
    
    ;; Come on, driver!
    (ai_go_to_vehicle return_cart_field_pilots/wraith_pilot_1 return_cart_wraith_1 "driver")

    ;; Phantom flies away
    (sleep 150)
    (vehicle_hover ext_cart_cship false)
    (recording_play_and_delete ext_cart_cship return_cart_cliffs_dropoff_out)
)

(script static void m_return_cart_wraith_setup
    ;; I guess MCC can crap itself if we don't wait a bit
    (sleep 15)
    
    (object_create_anew return_cart_wraith_1)
    (skip_frame)
    (ai_vehicle_enterable_distance return_cart_wraith_1 10)
    (ai_vehicle_enterable_team return_cart_wraith_1 covenant)
    (ai_vehicle_encounter return_cart_wraith_1 return_cart_wraith_1/d)
    (ai_follow_target_players return_cart_wraith_1)
    (ai_follow_distance return_cart_wraith_1 10)
    (ai_automatic_migration_target return_cart_wraith_1 true)

    ;; Second Wraith only on heroic+ and in assault mode
    (if (and
            (<= hard (game_difficulty_get_real))
            m_return_cart_assaulting
        )
        (begin
            (object_create_anew return_cart_wraith_2)
            (skip_frame)
            (ai_vehicle_enterable_distance return_cart_wraith_2 10)
            (ai_vehicle_enterable_team return_cart_wraith_2 covenant)
            (ai_vehicle_encounter return_cart_wraith_2 return_cart_wraith_2/d)
            (ai_follow_target_players return_cart_wraith_2)
            (ai_follow_distance return_cart_wraith_2 10)
            (ai_automatic_migration_target return_cart_wraith_2 true)
        )
    )
)

;; ---
;; Mission main

(script static void m_return_cart_init
    ;; These guys are always here
    (ai_place return_cart_secret)
    (ai_place return_cart_entrance)

    ;; Special Hunters for the special difficulty
    (object_set_scale (list_get (ai_actors return_cart_entrance/hunters_spawn_easy) 0) 0.8 1)
    (object_set_scale (list_get (ai_actors return_cart_entrance/hunters_spawn_easy) 1) 0.8 1)
    (if (game_is_easy)
        (ai_erase return_cart_entrance/hunters_spawn)
        (ai_erase return_cart_entrance/hunters_spawn_easy)
    )

    ;; Let Jackals, Hunters do their things
    (wake return_cart_hunters_triggerer)
    (wake return_cart_entrance_triggerer)
    
    ;; Get rid of the old Bonus ghosts if they're still there
    ;; (Aliens are now using them is sufficient explanation for disappearance)
    (if (volume_test_object ext_cart_main ext_cart_bonus_ghost_1)
        (object_destroy ext_cart_bonus_ghost_1)
    )
    (if (volume_test_object ext_cart_main ext_cart_bonus_ghost_2)
        (object_destroy ext_cart_bonus_ghost_2)
    )

    ;; Goodbye
    (object_destroy_containing ext_cart_turret_front)

    ;; Set up the field dudes
    (ai_place return_cart_field)
    (wake return_cart_field_triggerer)
    
    ;; Remove old dudes who are pains in the ass
    (ai_erase ext_cart_entrance/interior)
    (ai_erase ext_cart_entrance/ledge_left)
    (ai_erase ext_cart_entrance/ledge_right)
    (ai_erase ext_cart_field)
)

(script static void m_return_cart_init_assault
    (print_debug "m_return_cart_init_assault")
    (sleep_until (= bsp_index_ext_cart (structure_bsp_index)) 1)

    ;; Mark that we're assaulting
    (set m_return_cart_assaulting true)

    ;; Combat has definitely begun
    (set m_return_cart_combat_begun true)

    ;; Set up the Wraiths
    (m_return_cart_wraith_setup)

    ;; Magic Wraith pilots
    ;; We need to force-load units for reasons I no longer remember.
    ;; The original comment here was "oh so that's how it is. hce you motherfucker."
    ;; ...on a commit titled "this bastard game". 2014 lag must have been pretty upset.
    (ai_place return_cart_field_pilots/wraith_pilot_1)
    (ai_place return_cart_field_pilots/wraith_pilot_2)
    (skip_frame)
    (unit_enter_vehicle (ai_actor return_cart_field_pilots/wraith_pilot_1 0) return_cart_wraith_1 "wraith-driver")
    (unit_enter_vehicle (ai_actor return_cart_field_pilots/wraith_pilot_2 0) return_cart_wraith_2 "wraith-driver")

    ;; The vehicles also have uhhhhh Covenant radios onboard or something so they know you're here
    (ai_magically_see_players return_cart_field_pilots)

    (wake return_cart_wraith_triggerer)
)

(script static void m_return_cart_init_stealth
    (print_debug "m_return_cart_init_stealth")
    (sleep_until (= bsp_index_ext_cart (structure_bsp_index)) 1)
    
    ;; We need to listen for when combat has begun
    (wake m_return_cart_combat_beginner)
    
    ;; cship flavor event v2
    (create_ext_cart_cship)
    (object_teleport ext_cart_cship return_cart_cliffs_dropoff_flag)
    (vehicle_hover ext_cart_cship true)
    (ai_place return_cart_field_pilots/wraith_pilot_1)

    ;; Set up the Wraiths
    (m_return_cart_wraith_setup)
    
    ;; Load Wraith for dropping
    (unit_enter_vehicle return_cart_wraith_1 ext_cart_cship "large_cargo")
    (wake return_cart_wdrop_triggerer)
    
    (wake return_cart_wraith_triggerer)
)

(script dormant m_return_cart_main
    (sleep_until
        (or
            (volume_test_players_any override_cliffs_entrance)
            (volume_test_players_any ext_cart_return_approaching)
        )
        1
    )
    (print_debug "m_return_cart_start - a player has approached")
    
    (if (volume_test_players_any ext_cart_return_approaching)
        (m_return_cart_init_assault)
        (m_return_cart_init_stealth)
    )
    (m_return_cart_init)
)


;; ---
;; Mission hooks

(script static void m_return_cart_startup
    (print_debug "m_return_cart_startup")
    
    (wake m_return_cart_main)
)

(script static void m_return_cart_cleanup
    (print_debug "m_return_cart_cleanup")
    
    (ai_erase return_cart_secret)
    (ai_erase return_cart_entrance)
    (ai_erase return_cart_field)
)


;; ---
;; MAIN MISSON
;; ---

;; ---
;; Music

(script dormant m_return_leadup_music
    ;; Play Pelican downed intro music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_08_crash")

    ;; Wait for a player to make it past the old elevator room
    (sleep_until
        (volume_test_players_any override_shaft_door)
        30
        900
    )

    ;; Play ambient music
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_08_crash")

    ;; Await a player's arrival at one of the turning points
    ;; Or just wait for 2-3 minutes
    (sleep_until
        (or
            (volume_test_players_any override_bridge_halfway)
            (volume_test_players_any override_cliffs_path_canyon)
        )
        30
        7200
    )

    ;; Then turn off the damn music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_08_crash")
)

;; ---
;; Pelican crash

(script dormant m_return_pelican_crash
    ;; Sleep a few seconds so it's not obvious
    (sleep 150)

    ;; Pelican crashing conversation
    (ai_conversation downed_enter)
    (object_create joke)

    ;; Brief delay
    (skip_second)

    ;; Play Pelican downed intro music
    (wake m_return_leadup_music)

    ;; Save game
    (game_save_no_timeout)

    ;; Wait some seconds
    (sleep 350)

    ;; Pelican crash!!!
    (player_effect_explosion)
    (sound_impulse_start "cmt\sounds\sfx\effects\explosions\muffled_indistinct_explosions" none 1)
    (object_create_containing downed)
    (object_set_permutation return_downed_pelican "parts" "damaged")
    (object_set_permutation return_downed_pelican "wind" "off")
    (player_effect_stop 4)
    (object_destroy joke)

    ;; Special crash for the special difficulty
    (if (game_is_easy)
        (begin
            (object_destroy return_downed_dump_w2)
            (object_destroy return_downed_dump_w3)
            (object_destroy return_downed_dump_w4)
            (object_teleport return_downed_pelican easy_crash_flag)
            (object_teleport help_boulder help_boulder_flag)
            (object_teleport help_boulder_2 help_boulder_flag_2)
            (object_teleport help_boulder_3 help_boulder_flag_3)
            (physics_set_gravity 0.9)
            (ai_place victims)
            (ai_command_list victims suicide)
            (phantom_of_the_map)
        )
    )

    ;; Wait for a player to make it past the old elevator room
    (sleep_until (volume_test_players_any override_shaft_door))

    ;; Save game
    (game_save_no_timeout)
)

;; ---
;; Mission scripts

(global boolean m_return_shaft_server_start false)
(script continuous m_return_shaft_server_updater
    (sleep_until m_return_shaft_server_start 1)

    ;; Stealth Elites always know where the player is
    (ai_magically_see_players return_shaft_server)

    ;; Stealth Elites always coordinate on grouped players
    (cond
        (
            (volume_test_players_all override_shaft_server_a)
            
            (ai_migrate return_shaft_server/stealth_harass return_shaft_server/stealth_elites_harass_b)
            (ai_migrate return_shaft_server/stealth_guard return_shaft_server/stealth_elites_guard_f)
            (ai_migrate return_shaft_server/stealth_intercept return_shaft_server/stealth_elites_intercept_c)
        )
        (
            (volume_test_players_all override_shaft_server_b)
            
            (ai_migrate return_shaft_server/stealth_harass return_shaft_server/stealth_elites_harass_c)
            (ai_migrate return_shaft_server/stealth_guard return_shaft_server/stealth_elites_guard_f)
            (ai_migrate return_shaft_server/stealth_intercept return_shaft_server/stealth_elites_intercept_b)
        )
        (
            (volume_test_players_all override_shaft_server_c)
            
            (ai_migrate return_shaft_server/stealth_harass return_shaft_server/stealth_elites_harass_d)
            (ai_migrate return_shaft_server/stealth_guard return_shaft_server/stealth_elites_guard_g)
            (ai_migrate return_shaft_server/stealth_intercept return_shaft_server/stealth_elites_intercept_c)
        )
        (
            (volume_test_players_all override_shaft_server_d)
            
            (ai_migrate return_shaft_server/stealth_harass return_shaft_server/stealth_elites_harass_e)
            (ai_migrate return_shaft_server/stealth_guard return_shaft_server/stealth_elites_guard_h)
            (ai_migrate return_shaft_server/stealth_intercept return_shaft_server/stealth_elites_intercept_b)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            
            (ai_migrate return_shaft_server/stealth_harass return_shaft_server/stealth_elites_harass_all)
            (ai_migrate return_shaft_server/stealth_guard return_shaft_server/stealth_elites_guard_all)
            (ai_migrate return_shaft_server/stealth_intercept return_shaft_server/stealth_elites_intercept_all)
        )
    )
)

(script continuous m_return_shaft_server_automig
    ;; Make sure stealth guys don't go braindead across BSP switches
    (sleep_until (= (structure_bsp_index) bsp_index_ext_pit) 1)
    (ai_migrate return_shaft_server_pit/ground_cleanup override_pit/ground_cleanup)

    ;; Make sure stealth Elites don't re-freeze or fall into the void if the players backtrack
    (sleep_until (= (structure_bsp_index) bsp_index_int_sec_servers) 1)
    (ai_migrate override_pit/ground_cleanup return_shaft_server_pit/ground_cleanup)
    (ai_teleport_to_starting_location_if_unsupported return_shaft_server_pit/ground_cleanup)
)

(script dormant m_return_shaft
    ;; Wait for a player to get back down the elevator
    (sleep_until
        (volume_test_players_any override_ufo_elev_bot)
    )

    ;; Wake the Pelican crash sequence
    (wake m_return_pelican_crash)

    ;; Go ahead and place the return encounter
    (ai_place return_shaft_corridor/catwalk)

    ;; Alert server men
    (ai_set_current_state override_shaft_server search)

    ;; Wait for a player to get closer to the server room
    (sleep_until
        (volume_test_players_any override_shaft_door)
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Make the Jackals rush in
    (ai_migrate return_shaft_corridor/catwalk_jackal return_shaft_corridor/catwalk_jackal_rush)
    (ai_command_list return_shaft_corridor/catwalk return_shaft_elev_catwalk_rush)

    ;; Wait for a player to get closer to the server room
    (sleep_until
        (volume_test_players_any override_shaft_entrance)
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Do do-do do-do inspector stealth Elite do do-do do-do do doooooo
    (ai_place return_shaft_server)

    ;; Magic sight prevents blowing through encounters
    (sleep_until
        (volume_test_players_any override_shaft_server_d)
    )

    ;; Alert the units
    (set m_return_shaft_server_start true)

    ;; Wait until a player's leaving the building
    (sleep_until
        (or
            (= 0 (ai_living_count return_shaft_server))
            (volume_test_players_any override_shaft_server_entrance)
        )
    )

    ;; Elites become sec entrance guys
    (ai_migrate return_shaft_server return_shaft_server_pit/ground_cleanup)
    (ai_command_list override_pit/ground_cleanup return_pit_ground)

    ;; Save game
    (game_save_no_timeout)

    ;; Await a player's arrival back at pit
    (sleep_until
        (or
            (volume_test_players_any override_pit_right)
            (volume_test_players_any override_pit_left)
        )
    )

    ;; Special weather for the special difficulty
    (if (game_is_easy)
        (ai_place return_pit_inclement_weather)
    )

    ;; Just in case
    (sleep 60)
    (ai_kill return_pit_inclement_weather)

    ;; Save game
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_return_launch
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_ext_ufo m_return_spawn_0 m_return_spawn_1)

    ;; Once faded in, enable input
    (cinematic_show_letterbox 1)
    (show_hud false)
    (game_save_totally_unsafe)
    (cinematic_set_title unlocked)
    (sleep 150)
    (cinematic_show_letterbox 0)
    (show_hud true)
)

(script static void m_return_start
    (print_debug "m_return_start: starting")

    ;; Launch mission if we have to
    (if (= b30r_launch_return mission_launch_index)
        (m_return_launch)
    )

    ;; Player's objective is the cartographer once more
    (if (game_is_easy)
        (objective_set dia_found_ez obj_found_ez)
        (if (>= mission_state mission_cartographer_found)
            (objective_set dia_found obj_found)
            (objective_set dia_find obj_find)
        )
    )

    ;; Wake the main return mission
    (wake m_return_shaft)

    ;; Place some new blocks for the cart return
    (object_create_containing cart_return_block)
    (object_destroy_containing cart_old_block)

    ;; The Covenant have killed any hog drivers left in the field
    (ai_kill marines_ext_capp-cart)

    ;; Await a player's arrival back at pit
    ;; (This fixes a 1.4-era regression that caused the return to _immediately_ start when it shouldn't, resulting in
    ;; weird artifacts like the strafing phantom appearing at the crash site immediately)
    (sleep_until (volume_test_players_any override_pit_ground_level))

    ;; Wake the return missions
    (m_return_downed_startup)
    (m_return_cliffs_startup)
    (m_return_cart_startup)
)

(script static void m_return_clean
    ;; Clean it all up
    (sleep -1 m_return_shaft)
    (sleep -1 m_return_shaft_server_updater)
    (sleep -1 m_return_shaft_server_automig)
    (m_return_downed_cleanup)
    (m_return_cliffs_cleanup)
    (m_return_cart_cleanup)
)

(script static void m_return_skip
    ;; This stuff is noticeable and it happens
    (object_create_containing downed)
    (object_create_containing cart_return_block)
    (object_destroy_containing cart_old_block)
    (object_create_containing return_cliffs)
    (object_destroy_containing ext_cart_turret_front)
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - End
(global long m_return_ctrl_state 0)

(script dormant m_return_control
    (if (!= m_return_ctrl_state 1)
        (m_return_skip)
        (m_return_start)
    )

    (sleep_until (>= m_return_ctrl_state 3))
    (m_return_clean)
)

(script static void m_return_startup
    (if (= 0 m_return_ctrl_state)
        (begin
            (set m_return_ctrl_state 1)
            (wake m_return_control)
        )
    )
)

(script static void m_return_cleanup
    (set m_return_ctrl_state 3)
)

(script static void m_return_mark_skip
    (m_return_startup)
    (set m_return_ctrl_state 2)
)