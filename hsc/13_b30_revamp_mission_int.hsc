;; 13_b30_revamp_mission_int.hsc
;; Mission to explore the Cartographer building
;; ---

;; ---
;; HALLWAYS
;; ---

;; ---
;; L-room updater

(global boolean int_hallways_lroom_alerted false)

(global boolean int_hallways_update_start false)
(script continuous m_int_hallways_update
    (sleep_until int_hallways_update_start 1)

    ;; If L-room is alerted when waterhall is not, units have no time to ambush
    ;; This goes first so that units don't try and do the ambush set up when you're already in their face
    (if
        (and
            (> (ai_status int_hallways_lroom) 3)
            (not int_hallways_lroom_alerted)
        )
        (begin
            (set int_hallways_lroom_alerted true)
            (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")

            (print_debug "m_int_hallways_update: lroom AI were alerted; emergency defense")
            (ai_command_list_advance int_hallways_lroom/brutes_entrance)

            ;; Make sure everybody knows players are there
            (ai_magically_see_players int_hallways_waterhall)
            (ai_magically_see_players int_hallways_lroom)
        )
    )

    ;; See if waterhall's been alerted; if so, mark it down and move the units for ambush
    (if
        (and
            (= (ai_status int_hallways_waterhall) 6)
            (not int_hallways_lroom_alerted)
        )
        (begin
            (set int_hallways_lroom_alerted true)
            (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")

            ;; Flank is only on heroic+
            (print_debug "m_int_hallways_update: waterhall AI were alerted; lroom units preparing")
            (if (>= (game_difficulty_get_real) hard)
                (begin
                    (print_debug "m_int_hallways_update: heroic+ - lroom brutes preparing to flank")
                    ;; "dumb ape" is a horrible cliche and yet here we are
                    (ai_command_list int_hallways_lroom/brutes_entrance int_hallways_lroom_ambush_tele)
                    (ai_command_list_advance int_hallways_lroom/brutes_entrance)
                    (ai_migrate int_hallways_lroom/brutes_entrance int_hallways_lroom/brutes_ambush)
                )
            )

            ;; Make sure everybody knows players are there
            (ai_magically_see_players int_hallways_waterhall)
            (ai_magically_see_players int_hallways_lroom)
        )
    )

    ;; If all players leave L-room through alternate exit, cut the scripts and migrate everybody but the Grunts and snipers to the lobby
    ;; ...but not if the AI never knew player was there
    (if
        (and
            (volume_test_players_all int_hallways_lobby_entrance_up)
            int_hallways_lroom_alerted
        )
        (begin
            (print_debug "m_int_hallways_update: player took alternate lroom exit")

            ;; Migrate, and move the Grunts to the center to get out of the way
            (ai_set_current_state int_hallways_lroom search)
            (ai_migrate int_hallways_lroom/brutes int_hallways_lobby/lroom_retreat)
            (ai_migrate int_hallways_lroom/jackals int_hallways_lobby/lroom_retreat)
            (ai_migrate int_hallways_lroom/grunts int_hallways_lroom/grunts_center)
            (ai_magically_see_players int_hallways_lroom)
            (ai_magically_see_players int_hallways_lobby)

            (ai_defend int_hallways_lobby)
            (sleep_forever)
        )
    )

    (sleep 15)
)

;; ---
;; Radio conversation

(script dormant m_int_hallways_foehammer
    ;; Conversation happens if you alert the L-room, move to the water hall middle,
    ;; or alert people and move past the entrance
    (sleep_until
        (or
            int_hallways_lroom_alerted
            (volume_test_players_any int_hallways_waterhall_mid)
            (and
                (> (ai_status int_hallways_waterhall) 3)
                (not (volume_test_players_any int_hallways_waterhall_entrance))
            )
        )
    )
    ;; Make yourself non-obvious!
    (sleep (random_range 360 900))
    
    ;; Foehammer to ground teams!!!!!
    ;; But on the special difficulty, your friends are long gone...
    (if (not (game_is_easy))
        (ai_conversation shafta_descent)
    )
    
    ;; Everyone is dead now.
    (ai_kill lz_marines)
    (ai_kill lz_marines_holding)
)

;; ---
;; Main script

(script dormant m_int_hallways
    (print_debug "m_int_hallways: initialized")

    ;; Aliens
    (ai_place int_hallways_waterhall)
    
    ;; I don't know what happened last time
    (ai_set_blind int_hallways_waterhall true)
    (ai_set_deaf int_hallways_waterhall true)

    ;; Wait for a player to reach the entrance
    (sleep_until (volume_test_players_any int_hallways_waterhall_entrance))
    (print_debug "m_int_hallways: player nearing bottom of elevator; spooky music on")
    
    ;; Now, collect garbage
    (garbage_collect_now)

    ;; Spooky music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")

    ;; Start the updater
    (print_debug "m_int_hallways: waking m_int_hallways_update")
    (set int_hallways_update_start true)
    (wake m_int_hallways_foehammer)
    
    ;; They can wake up now
    (ai_set_blind int_hallways_waterhall false)
    (ai_set_deaf int_hallways_waterhall false)
    
    ;; Checkpoint
    (game_save_no_timeout)

    ;; Wait until AI is alerted or players have stopped camping the entrance
    (sleep_until
        (or
            (not (volume_test_players_any int_hallways_waterhall_entrance))
            (> (ai_status int_hallways_waterhall) 3)
        )
        1
    )
    (print_debug "m_int_hallways: ai alerted or player stopped camping")

    ;; If both players are still at the entrance, send the Elite to flank and wait for someone to move on
    (if (volume_test_players_all int_hallways_waterhall_entrance)
        (begin
            (print_debug "m_int_hallways: player has alerted AI at entrance; elite(s) flanking")
            (ai_migrate int_hallways_waterhall/elite_upper int_hallways_waterhall/entrance_flank)
            (ai_magically_see_players int_hallways_waterhall)
            (sleep_until (not (volume_test_players_any int_hallways_waterhall_entrance)))
        )
    )
    (print_debug "m_int_hallways: player has moved past entrance; elite(s) moving back if were flanking")

    ;; Elite goes back if he was flanking
    (ai_migrate int_hallways_waterhall/entrance_flank int_hallways_waterhall/elite_upper)

    ;; Wait until a player reaches the upper walkway
    (sleep_until (volume_test_players_any int_hallways_waterhall_upper) 1)
    (print_debug "m_int_hallways: player has moved to upper walkway; upper units retreating")
    
    ;; Checkpoint
    (game_save_no_timeout)

    ;; Units retreat
    (ai_migrate int_hallways_waterhall/elite_upper int_hallways_waterhall/elite_mid)
    (ai_migrate int_hallways_waterhall/grunts_upper int_hallways_waterhall/elite_upper)

    ;; Wait until a player reaches the mid walkway
    (sleep_until (volume_test_players_any int_hallways_waterhall_mid) 1)
    (print_debug "m_int_hallways: player has moved to mid walkway")

    ;; Try for a checkpoint
    (game_save_no_timeout)

    ;; Elites hold position on the walkway if >1 are still alive
    ;; Otherwise, fall back while any remaining upper units move to flank (Jackals hold position)
    (if (> (ai_living_count int_hallways_waterhall/elite_mid) 1)
        (begin
            (ai_attack int_hallways_waterhall/elite_mid)
            (print_debug "...elites will hold position")
        )
        (begin
            (ai_migrate int_hallways_waterhall/elite_mid int_hallways_waterhall/elite_lower)
            (print_debug "...elite retreating")
        )
    )
    (ai_migrate int_hallways_waterhall/upper int_hallways_waterhall/jackals_mid)
    
    ;; Special erasure on special difficulty
    (if (game_is_easy)
        (ai_erase int_hallways_waterhall)
    )

    ;; Wait until a player reaches the exit
    (sleep_until (volume_test_players_any int_hallways_waterhall_lower) 1)
    (print_debug "m_int_hallways: player has moved to exit; lower units defending, remaining units moving in")

    ;; Lower units consolidate at the entrance while any remaining mid/upper units surround the area
    (ai_migrate int_hallways_waterhall/lower int_hallways_waterhall/elite_lower)
    (ai_migrate int_hallways_waterhall/upper int_hallways_waterhall/grunts_lower)
    (ai_migrate int_hallways_waterhall/mid int_hallways_waterhall/grunts_lower)

    ;; Spawn the L-room units
    (if (game_is_easy)
        ;; Special Brootz for the special difficulty
        (begin
            (phantom_of_the_map)
            (ai_place int_hallways_lroom/brootz_easy)
            (ai_migrate int_hallways_lroom/brootz_easy int_hallways_lroom/brutes_entrance)
        )
        (begin
            (ai_place int_hallways_lroom/grunts)
            (ai_place int_hallways_lroom/jackals)
            (ai_place int_hallways_lroom/brutes_entrance)
            (ai_place int_hallways_lroom/antechamber)
            
            ;; On legendary, the snipers become the leaping Brute
            ;; (He'll spawn in automatically on legendary only thanks to squad counts)
            (ai_place int_hallways_lroom/brute_imposs)
            (if (game_is_impossible)
                (ai_migrate int_hallways_lroom/brute_imposs int_hallways_lroom/snipers_entrance)
                (ai_place int_hallways_lroom/snipers)
            )
            
            ;; On heroic+, Brute leader gets a Brute Shot
            (if (= (game_difficulty_get_real) normal)
                (begin
                    (print_debug "...brute leader will have a spiker")
                    (ai_place int_hallways_lroom/brutes_center)
                )
                (begin
                    (print_debug "...brute leader will have a bruteshot")
                    (ai_place int_hallways_lroom/brute_shot_brute)
                    (ai_migrate int_hallways_lroom/brute_shot_brute int_hallways_lroom/brutes_center)
                )
            )
        )
    )

    ;; Wait until a player moves on or everybody's dead
    (sleep_until
        (or
            (< (ai_living_count int_hallways_waterhall) 1)
            (volume_test_players_any int_hallways_special_brootz)
        )
        1
    )

    ;; Save
    (game_save_no_timeout)
    
    ;; Special Brootz for special difficulty
    (if (game_is_easy)
        (begin
            (sleep_until (volume_test_players_any int_hallways_special_brootz) 1)
            (ai_place int_hallways_surprise_brootz)
            (teleport_players brootz_position_0 brootz_position_1)
        )
    )
    
    ;; If player hasn't moved on then keep waiting
    (sleep_until (volume_test_players_any int_hallways_lroom_entrance))

    ;; If L-room was alerted...
    (if int_hallways_lroom_alerted
        (begin        
            (print_debug "m_int_hallways: player entered lroom - trap!!")
            
            ;; ...spring the trap
            (ai_migrate int_hallways_lroom/brutes_ambush int_hallways_lroom/brutes_entrance)
            (ai_migrate int_hallways_lroom/brutes_center int_hallways_lroom/brutes_entrance)
            (ai_migrate int_hallways_lroom/grunts int_hallways_lroom/grunts_entrance)
            (ai_migrate int_hallways_lroom/jackals_center int_hallways_lroom/jackals_entrance)
            (ai_magically_see_players int_hallways_lroom)
        )
        (print_debug "m_int_hallways: player entered lroom - AI still unaware of player")
    )

    ;; Wait until a player reaches the hallway center
    (sleep_until (volume_test_players_any int_hallways_lroom_center))
    (print_debug "m_int_hallways: player approaching lroom center")
    
    ;; Checkpoint
    (game_save_no_timeout)

    ;; Units retreat
    (ai_migrate int_hallways_lroom/brutes_entrance int_hallways_lroom/brutes_center)
    (ai_migrate int_hallways_lroom/jackals_entrance int_hallways_lroom/jackals_center)
    (ai_migrate int_hallways_lroom/grunts_entrance int_hallways_lroom/grunts_center)
    (ai_migrate int_hallways_lroom/snipers_entrance int_hallways_lroom/snipers_center)
    
    ;; Wraaaaaaaaaaaa! Legendary Brute jumps down to join the fight
    (if 
        (and
            (game_is_impossible)
            (> (ai_living_count int_hallways_lroom/snipers_center) 0)
            int_hallways_lroom_alerted
        )
        (begin
            (sound_impulse_start "cmt\sounds\dialog\characters\covenant\brute\h2_bloodthirsty_gibberish\involuntary\scream" (list_get (ai_actors int_hallways_lroom/snipers_center) 0) 1)
            (ai_command_list int_hallways_lroom/snipers_center int_hallways_lroom_brute_jump)
            (ai_migrate int_hallways_lroom/snipers_center int_hallways_lroom/brutes_center)
        )
    )

    ;; Wait until a player reaches the hallway exit
    (sleep_until (volume_test_players_any int_hallways_lroom_exit) 1)
    (print_debug "m_int_hallways: player approaching lroom exit")

    ;; Try to save
    (game_save_no_timeout)

    ;; Jackals & Grunts stay to defend, Brutes retreat to lobby
    (ai_migrate int_hallways_lroom/brutes int_hallways_lobby/lroom_retreat)
    (ai_migrate int_hallways_lroom/jackals int_hallways_lroom/jackals_exit)
    (ai_migrate int_hallways_lroom/grunts int_hallways_lroom/grunts_exit)

    ;; Wait until a player leaves the area
    ;; (Remember that the updater will cut this off to do its own thing if they take the alternate exit)
    (sleep_until (volume_test_players_any int_hallways_lobby_entrance_low) 1)

    ;; Checkpoint
    (game_save_no_timeout)
    
    ;; If any units except snipers (because one-way path) are alive, move them to the lobby
    (ai_migrate int_hallways_lroom/grunts int_hallways_lobby/lroom_retreat)
    (ai_migrate int_hallways_lroom/brutes int_hallways_lobby/lroom_retreat)
    (ai_migrate int_hallways_lroom/jackals int_hallways_lobby/lroom_retreat)
    (print_debug "m_int_hallways: player entering lobby")
    (print_debug_if (> (ai_living_count int_hallways_lroom) 1) "...remaining lroom units retreating")

    ;; Guys. Come on. Please.
    (ai_magically_see_players int_hallways_lobby)

    ;; Wait until a player enters the map room or everybody's dead
    (sleep_until
        (or
            (volume_test_players_any int_hallways_lobby_exit)
            (and
                (< (ai_living_count int_hallways_lroom) 1)
                (< (ai_living_count int_hallways_lobby) 1)
            )
        )
        1
    )

    ;; save
    (game_save_no_timeout)

    ;; End the updater
    (sleep -1 m_int_hallways_update)

    ;; Kill the music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")
    
    ;; Done
    (print_debug "m_int_hallways: completed")
)

;; ---
;; Mission hooks

(script static void m_int_hallways_startup
    (wake m_int_hallways)
)

(script static void m_int_hallways_cleanup
    (sleep -1 m_int_hallways)
    (sleep -1 m_int_hallways_update)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")
)


;; ---
;; MAIN MISSION
;; ---

;; ---
;; Ledge cutscene

(script dormant m_int_cutscene_ledge
    (sleep_until
        (or
            (volume_test_players_any int_shaft_edge)
            (volume_test_players_any int_shaft_ledge_big)
        )
    1)
    
    ;; Don't bother if sequences have been broken
    (if (not (volume_test_players_any int_shaft_edge))
        (sleep_forever)
    )

    ;; Stop shooting, we're doing a cinematic.
    (ai false)
    
    ;; Cinematic fade out
    (fade_to_white)
    (skip_second)
    (cinematic_start)

    ;; Set some shit up
    (camera_control true)
    (teleport_players player_ledge_wait player_ledge_wait)
    (skip_frame)
    
    (object_create_anew rock_kick)
    (camera_set shafta_ledge_1a 0)
    
    ;; Player0 starts walking
    (X_CUT_setup_player0 ledge_cyborg_0)
    (unit_set_seat ledge_cyborg_0 alert)
    (object_teleport ledge_cyborg_0 ledge_walk)
    (recording_play ledge_cyborg_0 ledge_cyborg_walk_0)
    
    ;; Player1 waits for a bit
    ;; CO-OP: If more players are added, set up all of them here
    (if (game_is_cooperative)
        (begin
            (X_CUT_setup_player1 ledge_cyborg_1)
            (unit_set_seat ledge_cyborg_1 alert)
            
            (if (game_is_easy)
                (object_teleport ledge_cyborg_1 ledge_easy_await)
            )
        )
    )

    ;; 0.5 sec white -> fade back in as things happen
    (skip_half_second)
    (fade_from_white)
    
    ;; Start with the top down shot
    (camera_set shafta_ledge_1b 250)
    (sleep 200)
    
    ;; Player1 can start moving now
    (if (game_is_cooperative)
        (if (game_is_easy)
            (begin
                (object_teleport ledge_cyborg_1 ledge_easy_leave)
                (recording_play ledge_cyborg_1 ledge_cyborg_walk_0)
            )
            (recording_play ledge_cyborg_1 ledge_cyborg_walk_1)
        )
    )
    (sleep 50)
    
    ;; Title plays with the wide shot
    (camera_set shafta_ledge_2a 0)
    (camera_set shafta_ledge_2b 240)
    (cinematic_set_title shafted)
    (sound_looping_predict "sound\sinomatixx\b30_ledge_foley")
    (sleep 200)

    ;; Now, cut to Chiefs at the ledge
    (object_teleport ledge_cyborg_0 ledge_look_0)
    (custom_animation ledge_cyborg_0 "cinematics\animations\chief\level_specific\b30\b30" "b30ledge" false)
    (scenery_animation_start rock_kick "scenery\cutscene_small_rock\cutscene_small_rock" "clip01-rockfalling")
    (sound_looping_start "sound\sinomatixx\b30_ledge_foley" none 1)
    
    (if (and (game_is_cooperative) (not (game_is_easy)))
        (object_teleport ledge_cyborg_1 ledge_look_1)
    )
    
    (camera_set shafta_ledge_3a 0)
    (camera_set shafta_ledge_3b 650)
    (sleep 30)
    
    ;; Player1 looks around for a bit
    (if (and (game_is_cooperative) (not (game_is_easy)))
        (custom_animation ledge_cyborg_1 "cmt\characters\_shared\cyborg\cinematics\animations\level_specific\b30_revamp\b30_revamp" "look_with_intent" true)
    )
    (sleep 15)
    
    ;; Decorative rumble on the kick
    (player_effect_set_max_translation 0 0 0)
    (player_effect_set_max_rotation 0 0 0)
    (player_effect_set_max_vibrate 0.1 0.1)
    (player_effect_start 0.5 0.1)
    (player_effect_stop 0.4)
    (sleep 145)

    ;; Player1 turns to the shaft
    (if (and (game_is_cooperative) (not (game_is_easy)))
        (recording_play ledge_cyborg_1 ledge_cyborg_turn_left)
    )
    (sleep 60)
    
    ;; Fade out
    (fade_to_white)
    (skip_half_second)

    ;; Cleanup
    ;; CO-OP: If more players are added, clean up all of them here
    (teleport_players player_ledge_end_0 player_ledge_end_1)
    (X_CUT_teardown_player0 ledge_cyborg_0)
    (if (game_is_cooperative)
        (X_CUT_teardown_player1 ledge_cyborg_1)
    )
    
    (object_destroy rock_kick)
    (show_hud true)
    (camera_control false)
    (cinematic_stop)

    ;; Ok you can shoot now
    (ai true)
    
    ;; Fade back in
    (fade_from_white)
    (skip_half_second)

    ;; Heyyy, a checkpoint!
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_int_launch
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_int_shaft_a m_int_spawn_0 m_int_spawn_1)

    ;; Special objective just for here
    (if (game_is_easy)
        (objective_set dia_found_ez obj_found_ez)
        (objective_set dia_found obj_found)
    )
)

(script static void m_int_start
    (print_debug "m_int_start: starting")

    ;; Launch mission if we have to
    (if (= b30r_launch_int mission_launch_index)
        (m_int_launch)
    )
    
    ;; Fuck you HCE
    (object_create rock_kick)
    
    ;; Wait until a player approaches the edge
    (sleep_until 
        (and
            (= bsp_index_int_shaft_a (structure_bsp_index))
            (or
                (volume_test_players_any int_shaft_entered)
                (volume_test_players_any int_shaft_bridge)
                (volume_test_players_any int_shaft_ledge_big)
                (volume_test_players_any int_shaft_leaving)
            )
        )
    1)

    ;; A player is at the edge, record that someone's made it inside
    (set mission_state mission_cartographer_entered)

    ;; Music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_08_crash")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_09_crashsite")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_10_return_sneaky")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_11_return_hogrun")
    
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_12_shafted")
    
    ;; Cutscene! (Maybe)
    (wake m_int_cutscene_ledge)

    ;; Wait until a player's heading down the elevator
    (sleep_until (volume_test_players_any int_elevator_descending) 1)

    ;; Fade the spooky music out...
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_12_shafted")

    ;; ...into the ascending strings.
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_12a_elevator")

    ;; This should be safe now
    (garbage_collect_now)
    (game_save_no_timeout)

    ;; Start the sub-missions
    (m_int_hallways_startup)
    (m_int_cart_startup)
)

(script static void m_int_clean
    ;; Kill all music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_12_shafted")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_12a_elevator")
    
    ;; Clean sub-missions
    (m_int_hallways_cleanup)
    (m_int_cart_cleanup)
)

(script static void m_int_skip
    (set mission_state mission_cartographer_entered)
    (set mission_state mission_cartographer_activated)

    ;; Rock was kicked
    (object_destroy rock_kick)

    ;; Light bridge was extended
    (device_group_set_immediate position_int_shaft_a_bridge 1)
    
    ;; Elevator was used
    (device_group_set_immediate position_int_shaft_a_elevator 1)

    ;; Marines were killed
    (ai_kill lz_marines)
    (ai_kill lz_marines_holding)

    ;; Main door was opened
    ;; (We need to do both of these commands here, because otherwise the door will auto-close and never open again.)
    ;; (I don't know why device_set_position_immediate doesn't count as a change for the purposes of the only-change-once behavior.)
    (device_set_position int_shaft_c_cart_door_upper 1)
    (device_set_position_immediate int_shaft_c_cart_door_upper 1)
    
    ;; Generators were powered
    (device_group_set power_int_shaft_c_gen_classc 1)
    (device_group_set power_int_shaft_c_gen_brute 1)
    (device_group_set power_int_shaft_c_gen_evolve 1)
    
    ;; Cartographer was activated
    (device_group_set_immediate power_cartographer 1)
    (device_group_set_immediate hack_int_shaft_c_holo_ring 1)
    (device_set_position int_shaft_c_cart_switch 1)
    (device_set_position_immediate int_shaft_c_holo_ring 1)
    (device_set_position_immediate int_shaft_c_holo_glows 1)
    
    ;; Elevator has arrived
    (object_create int_shaft_c_hunter_lift)

    ;; Seal was broken
    (if (game_is_easy)
        (device_set_position grimdome 1)
    )
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - End
(global long m_int_ctrl_state 0)

(script dormant m_int_control
    (if (!= m_int_ctrl_state 1)
        (m_int_skip)
        (m_int_start)
    )

    (sleep_until (>= m_int_ctrl_state 3))
    (m_int_clean)
)

(script static void m_int_startup
    (if (= 0 m_int_ctrl_state)
        (begin
            (set m_int_ctrl_state 1)
            (wake m_int_control)
        )
    )
)

(script static void m_int_cleanup
    (set m_int_ctrl_state 3)
)

(script static void m_int_mark_skip
    (m_int_startup)
    (set m_int_ctrl_state 2)
)
