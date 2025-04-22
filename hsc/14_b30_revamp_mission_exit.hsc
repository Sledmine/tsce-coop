;; 14_b30_revamp_mission_exit.hsc
;; Mission to return to the surface, and extract from the island
;; ---

;; ---
;; Extraction cutscene

(script dormant m_exit_cutscene_extraction
    ;; Put up a letterbox, wait a moment while Pelican gets moving
    (cinematic_show_letterbox true)
    (show_hud false)
    (vehicle_hover insertion_pelican_1 false)
    (recording_play_and_hover insertion_pelican_1 extraction_pelican_out)

    ;; Begin lines
    (sleep 50)
    (ai_conversation extraction)
    (sleep 50)

    ;; Fade to cutscene proper, begin music
    (fade_to_white)
    (skip_second)
    (camera_control true)
    (cinematic_start)
    (camera_set cutscene_extraction_1a 0)
    (unit_close insertion_pelican_1)
    (sound_looping_start "cmt\sounds\sfx\scenarios\b30_revamp\foley\b30r_extraction_foley" none 1)
    (fade_from_white)

    ;; Start music once faded in
    (skip_second)
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_20_extraction")

    ;; Let the Pelican fly off, rotate up to follow
    (player_effect_rumble)
    (sleep 35)
    
    (player_effect_stop 3)
    (camera_set cutscene_extraction_1b 130)
    (sleep 139)

    ;; Switch BSP and cut to the lid shot
    (switch_bsp bsp_index_ext_sapp)
    (recording_kill insertion_pelican_1)
    (object_teleport insertion_pelican_1 extraction_pelican_hack_flag)
    (recording_play insertion_pelican_1 extraction_pelican_hack)
    (camera_set cutscene_extraction_2a 0)
    (camera_set cutscene_extraction_2b 300)
    (skip_frame)

    ;; Kill any leftover lid units
    (ai_kill ext_lid)
    (ai_kill return_lid)

    (sleep 148)

    ;; Pelican incoming
    (player_effect_set_max_rotation 0 0.4 0.4 )
    (player_effect_set_max_rumble 0.4 0.4 )
    (player_effect_start 1 2 )
    (sleep 100)

    ;; Open FX
    (object_create_anew_containing lid_dust)
    (object_create_anew_containing lid_crate)
    (device_set_position extraction_lid 1)
    (sleep 20)

    ;; Start ending music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_19_surface")
    (sleep 40)

    ;; Cut to shaft view, move lid
    (device_set_position_immediate extraction_lid 0.8)
    (switch_bsp bsp_index_int_shaft_b)
    (camera_set cutscene_extraction_3a 0)
    (camera_set cutscene_extraction_3b 585)
    (device_set_position extraction_lid 0)
    (player_effect_stop 13)

    ;; Remove any leftover L-room units
    (ai_erase int_hallways_lroom)
    (ai_erase exit_lroom)

    ;; Flare and Pelican
    (fade_in 1 1 1 45)
    (object_create_anew extraction_lid_flare)
    (object_teleport insertion_pelican_1 extraction_pelican_shaft_flag)
    (recording_kill insertion_pelican_1)
    (vehicle_hover insertion_pelican_1 false)
    (recording_play insertion_pelican_1 extraction_pelican_descend)
    (sleep 175)

    ;; Bounce
    ;; This crate doesn't land where it used to in versions before 1.4.
    ;; It used to comically bounce off one of the shaft ribs, which was kinda great.
    ;; So, we secretly force a different crate to do it to retain the visual.
    (object_destroy lid_crate_1)
    (object_create bounce_crate)

    ;; Cut to above
    (object_teleport insertion_pelican_1 extraction_pelican_shaft_flag_2)
    (camera_set cutscene_extraction_4a 0)
    (camera_set cutscene_extraction_4b 600)
    (sleep 155)

    ;; Fade out
    (fade_to_white)
    (sleep 150)

    ;; Cut to black so we can clean up after ourselves
    (snap_to_black)

    ;; Done
    (set mission_state mission_extracted)
    (sleep 120)
    (cinematic_stop)
    (show_hud false)
    (player_enable_input false)
)

;; ---
;; Secret cutscene

(global unit m_exit_secret_cutscene_unit none)

(script dormant m_exit_secret_cutscene
    ;; CO-OP: If more players are added, test for all of them here
    (if (unit_has_weapon (player0) "cmt\weapons\evolved\_egg\battle_rifle_silent\battle_rifle_silent")
        (set m_exit_secret_cutscene_unit (player0))
    )
    (if (unit_has_weapon (player1) "cmt\weapons\evolved\_egg\battle_rifle_silent\battle_rifle_silent")
        (set m_exit_secret_cutscene_unit (player1))
    )
    (if (= none m_exit_secret_cutscene_unit)
        (sleep -1)  ;; wtf
    )
    
    (sleep_until
        (not (unit_has_weapon m_exit_secret_cutscene_unit "cmt\weapons\evolved\_egg\battle_rifle_silent\battle_rifle_silent"))
        1
    )

    ;; CO-OP: If more players are added, check all of them here
    (if (or
            (< 0 (unit_get_health (player0)))
            (< 0 (unit_get_health (player1)))
        )
        (begin
            (game_save_cancel)
            (object_cannot_take_damage (players))
            
            (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro")
            (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit")
            (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_23_sbr")
            (ai_conversation sbr_dead)

            (player_enable_input false)
            (camera_control true)
            (cinematic_show_letterbox true)
            (camera_set_relative tsbr_relative 0 the_silent_battle_rifle)

            (sleep 210)
            (game_lost)
        )
    )
)

;; ---
;; Music control

;; Helper macros and variables
(global short m_exit_music_helper_timer 0)
(global boolean m_exit_music_helper_timer_on false)

;; Main control macros and variable
(global short exit_music_begin 0)
(global short exit_music_withperc 1)
(global short exit_music_perconly 2)
(global short exit_music_full 3)
(global short exit_music_end 4)
(global short m_exit_music_phase exit_music_begin)

;; This script fades in the perc-only loop, then runs a countdown to full-loop that can at any time be interrupted by sufficient player progress
(global boolean m_exit_music_helper_start false)
(script continuous m_exit_music_helper
    (sleep_until m_exit_music_helper_start 1)
    
    (if m_exit_music_helper_timer_on
        (if (> m_exit_music_helper_timer 0)
            (set m_exit_music_helper_timer (- m_exit_music_helper_timer 1))
            (begin
                (set m_exit_music_phase exit_music_full)
                (sleep_forever)
            )
        )
        ;; 113 ticks ~= 3.75 seconds, i.e. half a phrase, timed with the 3.75 second tag-side fade-out of the synth+perc loop
        (if (< m_exit_music_helper_timer 113)
            (begin
                (set m_exit_music_helper_timer (+ m_exit_music_helper_timer 1))
                (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit" (/ m_exit_music_helper_timer 113))
            )
            (begin
                ;; Done - get the timer ready for the next phase and wait until it's time
                (set m_exit_music_helper_timer 450)
                (sleep_until m_exit_music_helper_timer_on)
            )
        )
    )
)

(script dormant m_exit_music
    ;; Start both tracks simultaneously to ensure they're aligned later, mute the percussion
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit")
    (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit" 0)

    ;; Wait for synth + percussion phase
    (sleep_until (= m_exit_music_phase exit_music_withperc))

    ;; Alt loop
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro")

    ;; Wait for percussion only phase
    (sleep_until (= m_exit_music_phase exit_music_perconly))

    ;; Stop 17; its tag-side fade-out coincides with script-side fade-in of 17a
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro")
    (set m_exit_music_helper_start true)

    ;; Wait for synth + percussion + choral phase
    (sleep_until (= m_exit_music_phase exit_music_full))

    ;; Wwitch to the full loop
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit")

    ;; Wait for end phase
    (sleep_until (= m_exit_music_phase exit_music_end))

    ;; Finish it off
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit")
)

;; ---
;; Special zealot behavior
;; CO-OP: Pay close attention to the nuances here, this is a tricky script

(global boolean m_exit_zealot_start false)
(script continuous m_exit_zealot
    (sleep_until m_exit_zealot_start 1)
    
    ;; Make sure he's alive before we go
    (if (< (ai_living_count exit_zealot) 1)
        (sleep_forever)
    )

    ;; Special behavior begins when:
    ;; - At least one player is on the lightbridge
    ;; - All other players are in a non-cheesy position
    (sleep_until
        (and
            (volume_test_players_any int_shaft_bridge)
            (volume_test_players_all int_shaft_ledge_big)
        )
        1
    )
    
    ;; Take away Elite's brains
    (ai_braindead exit_zealot 1)

    ;; Check to see if we need the special on-bridge command list
    (if (volume_test_object int_shaft_bridge (list_get (ai_actors exit_zealot) 0))
        (begin
            (ai_command_list exit_zealot exit_shaft_zealot_panel_bridge)
            (sleep 90)
            (ai_command_list exit_zealot exit_shaft_zealot_panel)
        )
        (ai_command_list exit_zealot exit_shaft_zealot_panel)
    )

    ;; Then wait until one of these things happens:
    ;; - Elite is in position
    ;; - Elite is stuck on the bridge
    ;; - No players are currently on the bridge
    ;; - Any player has entered a cheesy position
    ;; - Enough time elapses to consider this a failure
    (sleep_until
        (or
            (volume_test_object exit_shaft_zealot_switch (list_get (ai_actors exit_zealot) 0))
            (volume_test_object int_shaft_bridge (list_get (ai_actors exit_zealot) 0))
            (not (volume_test_players_any int_shaft_bridge))
            (not (volume_test_players_all int_shaft_ledge_big))
        )
        1
        60
    )

    ;; Give Elite his brains back
    (ai_braindead exit_zealot 0)

    ;; If everything is set up...
    (if
        (and
            (volume_test_players_any int_shaft_bridge)
            (volume_test_players_all int_shaft_ledge_big)
            (volume_test_object exit_shaft_zealot_switch (list_get (ai_actors exit_zealot) 0))
            (> (ai_living_count exit_zealot) 0)
        )
        (begin
            ;; ...turn it off!
            (device_group_set position_int_shaft_a_bridge 0)

            ;; Gloat if all players were caught in the trap
            (if (volume_test_players_all int_shaft_bridge)
                (ai_command_list exit_zealot exit_shaft_zealot_gloat)
            )

            ;; Wait so script doesn't loop crazy while players die (or recover!)
            (sleep 60)
        )
    )
)

(script dormant m_exit_zealot_trigger
    ;; Wait for a player to alert him to wake his updater
    (sleep_until
        (or
            (= 0 (ai_living_count exit_zealot))
            (> (ai_status exit_zealot) 3)
            (volume_test_players_any int_shaft_entered)
        )
    )
    (set m_exit_zealot_start true)
    
    ;; Wait to see if a player retreats
    ;; CO-OP: If more players are added, check all of them here
    (sleep_until
        (or
            (< 14 (objects_distance_to_object (ai_actors exit_zealot) (player0)))
            (< 14 (objects_distance_to_object (ai_actors exit_zealot) (player1)))
        )
    )

    ;; I'm almost 30, I don't need to play these games
    (ai_defend exit_zealot)
)

;; ---
;; Main mission

(global boolean m_exit_automig_start false)
(script continuous m_exit_automig
    (sleep_until m_exit_automig_start 1)
    (sleep_until (= bsp_index_int_shaft_b (structure_bsp_index)) 1)

    ;; Hunters
    (ai_migrate exit_hunters_retreat/hunters exit_hunters_retreat_b/lobby)
    (sleep_until (= bsp_index_int_shaft_c (structure_bsp_index)) 1)

    ;; Hunters
    (ai_migrate exit_hunters_retreat_b/hunters exit_hunters_retreat/lobby)
)

;; I'll say it in red! _"the door you walk in through cannot be closed once it is opened!"_
;; Use magic to secretly create a new door to replace the old one to allow it to close behind the player.
(script dormant m_exit_door_witch
    (sleep_until (volume_test_players_any int_cart_threshold) 1)
    (object_create_anew int_shaft_c_cart_door_upper)
    (device_group_change_only_once_more_set position_int_shaft_c_cart_dooru false)
)

(script dormant m_exit_main
    ;; If Hunters are alive, haunt the players for as long as possible
    (ai_erase int_cart_hunters/hack)
    (ai_migrate int_cart_hunters exit_hunters_retreat/elevator)
    (ai_migrate int_cart_hunters_side exit_hunters_retreat/elevator)
    (if (> (ai_living_count exit_hunters_retreat) 0)
        (begin
            ;; Destroy bottom floor elevator, create upper floor elevator
            (object_destroy int_shaft_c_hunter_lift)
            (object_create int_shaft_c_hunter_lift_fake)

            ;; Zap
            (skip_frame)
            (ai_teleport_to_starting_location exit_hunters_retreat)
        )
    )

    ;; Place the lobby guards and have them lie in wait
    (ai_place exit_lobby)
    (ai_defend exit_lobby)

    ;; Get out!!
    (sleep 90)
    (objective_set dia_leave obj_leave)

    ;; Start the super cool music after a brief delay
    (sleep 210)
    (wake m_exit_music)

    ;; Turn on magic sight for hunters once the music starts
    (ai_magically_see_players exit_hunters_retreat)

    ;; Wait for a player
    (sleep_until (volume_test_players_any int_cart_door_outer))

    ;; Player shouldn't be going back to map room
    (garbage_collect_now)

    ;; Place the L-room units
    (ai_place exit_lroom)

    ;; Erase any leftover L-room units depending on difficulty
    (cond
        (
            (game_is_easy)
            (ai_erase int_hallways_lroom)
            (ai_erase int_hallways_surprise_brootz)
            (ai_conversation int_exit_special_c_first)
        )
        (
            (= (game_difficulty_get_real) normal)
            (ai_erase int_hallways_lroom/brutes)
            (ai_erase int_hallways_lroom/snipers)
        )
        (
            (= (game_difficulty_get_real) hard)
            (ai_erase int_hallways_lroom/grunts)
        )
    )

    ;; Why not put the entrance Elite here first, to facilitate some flavor for later
    (ai_migrate exit_lroom/elite_entrance exit_lroom/retreat)

    ;; Lobby guards attack, Hunters migrate
    (ai_migrate exit_lobby/grunts_retreat exit_lobby/grunts_center)
    (ai_attack exit_lobby)
    (ai_migrate exit_hunters_retreat exit_hunters_retreat/lobby)

    ;; Save after that horrible grind of a not an encounter
    (game_save_no_timeout)

    ;; See where a player goes
    (sleep_until
        (or
            (volume_test_players_any int_hallways_lobby_entrance_up)
            (volume_test_players_any int_hallways_lobby_entrance_low)
        )
    )

    ;; Dead end!
    (if (volume_test_players_any int_hallways_lobby_entrance_up)
        (begin
            ;; Elite chases player in if alive
            (ai_migrate exit_lobby/elite exit_lobby/elite_aquarium)

            ;; Grunts move back to center position to wait for player
            (ai_migrate exit_lobby/grunts exit_lobby/grunts_center)

            ;; Wait for the players to go back or somehow make it up
            (sleep_until (not (volume_test_players_any int_hallways_lobby_entrance_up)))

            ;; Elite returns to center squad
            (ai_migrate exit_lobby/elite exit_lobby/elite_center)

            ;; Wait for a player to move on or somehow make it up
            (sleep_until
                (or
                    (volume_test_players_any int_hallways_lobby_entrance_low)
                    (volume_test_players_any int_hallways_lobby_exit_up)
                )
            )

            (game_save_no_timeout)

            ;; Add the percussion
            (set m_exit_music_phase exit_music_withperc)

            ;; Move the Hunters
            (ai_migrate exit_hunters_retreat exit_hunters_retreat/lroom_side)

            ;; Move any live lobby units to the L-room
            (ai_migrate exit_lobby/grunts exit_lroom/grunts_exit)
            (ai_migrate exit_lobby/elite exit_lroom/elite_exit)

            (if (game_is_easy)
                (ai_conversation int_exit_special_c_second)
            )

            ;; See where a player went
            (if (volume_test_players_any int_hallways_lobby_entrance_low)
                (begin
                    ;; Alarm Jackal no longer necessary
                    (ai_migrate exit_lroom/jackal_balcony_alarm exit_lroom/jackals_balcony)

                    ;; Fuuck yooou HCEEEE
                    (ai_magically_see_players exit_lroom/exit)

                    ;; Wait until a player reaches center to move on
                    (sleep_until (volume_test_players_any int_hallways_lroom_center))

                    ;; Award a checkpoint for doing the encounter right
                    (game_save_no_timeout)
                )
                (begin
                    ;; If not, dogpiiiiiile
                    (ai_magically_see_players exit_lroom)
                    (ai_migrate exit_lroom/elite_center exit_lroom/elite_entrance)
                    (ai_migrate exit_lroom/grunts_center exit_lroom/jackals_entrance)
                )
            )
        )
        (begin
            ;; Add the percussion
            (set m_exit_music_phase exit_music_withperc)

            ;; Move any live lobby units to the lroom
            (ai_migrate exit_lobby/grunts exit_lroom/grunts_exit)
            (ai_migrate exit_lobby/elite exit_lroom/elite_exit)

            ;; Alarm Jackal no longer necessary
            (ai_migrate exit_lroom/jackal_balcony_alarm exit_lroom/jackals_balcony)

            ;; Just when I think there's no more going wrong
            ;; It shits itself and I'm here three times as long
            ;; So all that I'm able to do, you see,
            ;; Is stand up and yell: "Fuck you HCE"
            (ai_magically_see_players exit_lroom)

            (if (game_is_easy)
                (ai_conversation int_exit_special_c_second)
            )

            ;; Wait for a player to move on (or to be a real shit and double back through the upper entrance)
            (sleep_until
                (or
                    (volume_test_players_any int_hallways_lroom_center)
                    (volume_test_players_any int_hallways_lobby_exit_up)
                )
            )

            (game_save_no_timeout)
        )
    )

    ;; Dude in the entrance comes out
    (ai_migrate exit_lroom/retreat exit_lroom/elite_entrance)

    ;; Exit squad moves to reinforce center
    (ai_migrate exit_lroom/elite_exit exit_lroom/elite_center)
    (ai_migrate exit_lroom/jackals_exit exit_lroom/elite_center)
    (ai_migrate exit_lroom/grunts_exit exit_lroom/grunts_center)

    ;; Center takes defensive positions near the entrance
    (ai_defend exit_lroom/center)

    ;; Place the initial waterhall dudes and start them in defensive
    (ai_place exit_waterhall/jackals_lower_spawn)
    (ai_place exit_waterhall/elite_mid)
    (ai_place exit_waterhall/snipers_upper)
    (ai_place exit_waterhall/jackals_upper)
    (ai_place exit_waterhall/grunts_elevator)
    (ai_place exit_waterhall/snipers_elevator)
    (ai_defend exit_waterhall)

    ;; Erase any leftover waterhall units depending on difficulty
    (cond
        (
            (game_is_easy)
            (ai_erase int_hallways_waterhall)
        )
        (
            (= (game_difficulty_get_real) normal)
            (ai_erase int_hallways_waterhall/elite_upper)
            (ai_erase int_hallways_waterhall/elite_mid)
            (ai_erase int_hallways_waterhall/elite_lower)
            (ai_erase int_hallways_waterhall/jackals_mid)
        )
        (
            (= (game_difficulty_get_real) hard)
            (ai_erase int_hallways_waterhall/elite_mid)
            (ai_erase int_hallways_waterhall/jackals_mid)
        )
    )

    ;; Wait for a player to leave L-room
    (sleep_until (volume_test_players_any int_hallways_lroom_entrance))

    (if (game_is_easy)
        (begin
            ;; Special erasure for special difficulty
            (ai_erase exit_waterhall)
            (ai_erase exit_lobby)
            (ai_erase exit_lroom)

            ;; Special door for special difficulty
            (device_set_position_immediate int_shaft_b_waterhall_door 1)
            (device_set_power int_shaft_b_waterhall_door 0)
        )
    )

    (game_save_no_timeout)

    ;; Percussion only
    (set m_exit_music_phase exit_music_perconly)

    ;; Figure out the nearest pieces of shit that let the player get away without dying and send them in to chase
    (cond
        (
            (> (ai_living_count exit_lroom/entrance) 0)
            (ai_migrate exit_lroom/entrance exit_lroom/retreat)
        )
        (
            (> (ai_living_count exit_lroom/center) 0)
            (ai_migrate exit_lroom/center exit_lroom/retreat)
        )
        (
            (> (ai_living_count exit_lroom/exit) 0)
            (ai_migrate exit_lroom/exit exit_lroom/retreat)
        )
    )

    ;; Jackals move
    (ai_migrate exit_waterhall/jackals_lower_spawn exit_waterhall/jackals_lower)
    (ai_command_list exit_waterhall/jackals_lower exit_hallways_jackals)

    ;; L-room door guards retreat if they haven't already
    (ai_migrate exit_lroom/entrance exit_lroom/retreat)

    ;; Wait until someone's in the transition area
    (sleep_until (volume_test_players_any int_hallways_special_brootz) 1)

    ;; Oh no
    (if (game_is_easy)
        (begin
            (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro" 0)
            (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit" 0)
            (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17_exit_intro")
            (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_17a_exit")
            (object_create_containing "special_help")
        )
    )

    ;; Wait for a player to enter waterhall
    (sleep_until (volume_test_players_any int_hallways_waterhall_lower))

    ;; Start the timer for full music loop
    (set m_exit_music_helper_timer_on true)

    ;; Not dead L-room retreat units chase
    (ai_migrate exit_lroom/retreat exit_waterhall/jackals_lower)

    ;; Upper Elite arrives (he'll only spawn on legendary though)
    (ai_place exit_waterhall/elite_upper)

    ;; Waterhall dudes attack so we get at least some kind of motion
    (ai_attack exit_waterhall)

    ;; Endless checkpoints
    (game_save_no_timeout)

    ;; Wait for a player to move up or kill a lot of guys
    (sleep_until
        (or
            (volume_test_players_any int_hallways_waterhall_mid)
            (< (ai_living_fraction exit_waterhall) 0.5)
        )
    )

    ;; Checking on things
    (if X_DBG_enabled
        (inspect m_exit_music_helper_timer)
    )

    ;; The mid grunts are late
    (if (not (game_is_easy))
        (ai_place exit_waterhall/grunts_mid)
        (ai_conversation int_exit_special_trap)
    )

    ;; Light mid units retreat, lower units follow players and take their place
    (ai_migrate exit_waterhall/grunts_mid exit_waterhall/jackals_upper)
    (ai_migrate exit_waterhall/lower exit_waterhall/grunts_mid)

    (game_save_no_timeout)

    ;; Wait for a player to move further up or kill basically everybody
    (sleep_until
        (or
            (volume_test_players_any int_hallways_waterhall_upper)
            (< (ai_living_fraction exit_waterhall) 0.25)
        )
    )

    ;; If timer hasn't set off the full music yet, do it now by setting timer to 0
    (set m_exit_music_helper_timer 0)

    ;; Elevator Elite arrives in the nick of time
    (if (not (game_is_easy))
        (ai_place exit_waterhall/elite_elevator)
    )

    ;; Why not
    (game_save_no_timeout)

    ;; Light upper units retreat, mid units follow players and take their place
    (ai_migrate exit_waterhall/jackals_upper exit_waterhall/grunts_elevator)
    (ai_migrate exit_waterhall/mid exit_waterhall/jackals_upper)

    ;; Wait for a player to reach the elevator
    (sleep_until (volume_test_players_any int_hallways_waterhall_entrance) 15)
    (game_save_no_timeout)

    ;; Elevator units consolidate around the door, the rest surround the area
    (ai_migrate exit_waterhall/elevator exit_waterhall/snipers_elevator)
    (ai_migrate exit_waterhall/upper exit_waterhall/grunts_elevator)

    ;; Special units for special difficulty
    (if (game_is_easy)
        (begin
            ;; Start
            (game_save_totally_unsafe)
            (object_create water_fogs_elevator)
            (device_set_position water_fogs_elevator 1)
            (device_set_position lodvol_int_hallways_water_f 1)
            (ai_place exit_waterhall_easy/fuck)
            (ai_place exit_waterhall_easy/you)
            (ai_set_respawn exit_waterhall_easy true)
            (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_18_halo_1")

            ;; Lock the door
            (device_set_power int_shaft_b_waterhall_door 1)
            (device_operates_automatically_set int_shaft_b_waterhall_door 0)
            (sleep 60)
            (object_destroy int_shaft_b_waterhall_door)
            (object_create int_shaft_b_waterhall_door_bsh)

            ;; Chill out, Cheif
            (sleep 300)
            (ai_conversation int_exit_special_how_get_out)

            ;; Wait until players survive long enough
            (sleep 600)

            ;; Bash down the door
            (ai_place exit_waterhall_easy/hce)
            (ai_defend exit_waterhall_easy)
            (device_set_position int_shaft_b_waterhall_door_bsh 1)
            (ai_conversation int_exit_special_what's_that)

            ;; Hmm
            (sleep 90)
            (ai_conversation int_exit_special_get_up)
        )
    )

    ;; Wait for a player to ride up the elevator
    (sleep_until (volume_test_players_any int_elevator_descending))

    ;; End the super cool music
    (set m_exit_music_phase exit_music_end)

    ;; End the special stuff too
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_18_halo_1")
    (ai_set_respawn exit_waterhall_easy false)

    ;; If the Marines were waiting for you to return, somebody got to them first...
    (ai_kill marines_int_shaft_a)
    (ai_kill marines_ext_capp-cart)

    ;; Place mr. zealot
    (ai_place exit_zealot)

    ;; Special mystery
    (skip_second)
    (if (game_is_easy)
        (begin
            (ai_kill exit_zealot)
            (ai_conversation int_exit_special_mystery)
        )
    )

    ;; Wait for a player to head across the bridge
    (sleep_until (volume_test_players_any int_shaft_bridge))

    ;; Checkpoint
    (game_save_no_timeout)

    ;; Zealot
    (wake m_exit_zealot_trigger)

    ;; Wait for a player to make the worst mistake imaginable (the music is started down below, this is just a
    ;; convenient place to stop it if needed)
    (sleep_until (volume_test_players_any ext_cart_smallgorge))
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_19_surface")
)

;; ---
;; Mission end

;; Secret
(script dormant m_exit_secret_end
    (sleep_until (volume_test_players_any ext_cart_entrance_past))
    (game_save_totally_unsafe)
    (object_create_containing satan)
    (object_set_scale satan_huge 5 0)
    (object_set_scale satan_huge2 10 0)
    (object_set_scale satan_huge3 15 0)
    (phantom_of_the_map)
    (player_effect_rumble)
    (skip_frame)
    (physics_set_gravity 1)
    
    (sleep_until (volume_test_players_any ext_cart_main))
    (player_effect_rumble)
    (ai_conversation int_exit_special_captain)
    (activate_team_nav_point_flag "satan" player satan_hud 0)
    
    (ai_place exit_keyesmen)
    (ai_magically_see_players exit_keyesmen)

    ;; Wait for someone to investigate
    (sleep_until (>= 5 (objects_distance_to_object (players) satan00)))
    
    ;; Wait for everyone to investigate, someone to try and wander away, or enough time to pass
    ;; CO-OP: If more players are added, check all of them here
    (sleep_until
        (or
            (and
                (>= 5 (objects_distance_to_object (player0) satan00))
                (>= 5 (objects_distance_to_object (player1) satan00))
            )
            (< 30 (objects_distance_to_object (players) satan00))
        )
        30
        150
    )

    ;; CO-OP: If more players are added, poke all of them here
    (physics_set_gravity -1)
    (damage_object "cmt\globals\_shared\damage_effects\impulse" (player0))
    (damage_object "cmt\globals\_shared\damage_effects\impulse" (player1))
    (sleep 180)
    (unit_kill (player0))
    (unit_kill (player1))
    (map_reset)
)

;; Mission progression
(script dormant m_exit_end
    ;; Wait for a player to start heading up
    (sleep_until (volume_test_players_any ext_cart_entrance_hall))

    ;; Music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_19_surface")

    ;; Place the stealth guys
    (if (not (game_is_easy))
        (ai_place exit_stealth_elites)
    )

    ;; Voices in your head
    (if (game_is_easy)
        (ai_conversation evac_special)
        (ai_conversation evac_1)
    )

    ;; Also setup dropships
    (if (not (game_is_easy))
        (begin
            (create_ext_cart_cship)
            (object_teleport ext_cart_cship exit_cart_cship_flag)
            (vehicle_hover ext_cart_cship true)
        )
    )

    ;; Move in the stealth guys once a player approaches
    (sleep_until (volume_test_players_any ext_cart_entrance_past))
    (ai_migrate exit_stealth_elites/outside exit_stealth_elites/inside)

    ;; Let's hope this is the last time I have to say fuck you HCE
    (ai_magically_see_players exit_stealth_elites)

    ;; One last checkpoint
    (game_save_no_timeout)

    ;; Rupture in the fabric of reality
    (if (game_is_easy)
        (sleep_forever)
    )

    ;; Have dropships do their thing after a little bit
    (sleep (random_range 80 200))
    (create_insertion_pelican_1)
    (unit_close insertion_pelican_1)
    (object_cannot_take_damage insertion_pelican_1)
    (object_teleport insertion_pelican_1 extraction_pelican_flag)
    (recording_play_and_hover insertion_pelican_1 extraction_pelican_in)
    (vehicle_hover ext_cart_cship false)
    (recording_play_and_delete ext_cart_cship exit_cart_cship_out)

    ;; Players can get in the Pelican when it's ready
    (sleep_until (< (recording_time insertion_pelican_1) 61) 1)
    (unit_open insertion_pelican_1)
    (unit_set_enterable_by_player insertion_pelican_1 true)

    ;; Wait for the Pelican to finish its recording before progression, and also make sure it plays the damn hover
    ;; animation that lag worked so hard on all those years ago
    ;; (The unit_open call secretly kills the idle animation. Sigh)
    (sleep_until (= (recording_time insertion_pelican_1) 0) 1)
    (custom_animation insertion_pelican_1 "cmt\vehicles\_shared\pelican\pelican" "stand fixed idle" 1)

    ;; Wait for player0 to enter one of the anointed seats
    (sleep_until
        (or
            (vehicle_test_seat insertion_pelican_1 "P-riderLF" (player0))
            (vehicle_test_seat insertion_pelican_1 "P-riderRF" (player0))
        )
    )
    
    ;; CO-OP: In a multiplayer game, wait until other players are seated
    ;; (This ugly mess is taken straight from stock b30)
    (if (game_is_cooperative)
        (sleep_until
            (and
                (vehicle_test_seat_list insertion_pelican_1 "P-riderLF" (players))
				(vehicle_test_seat_list insertion_pelican_1 "P-riderRF" (players))
            )
        )
    )
    
    (wake m_exit_cutscene_extraction)
)

;; ---
;; Mission hooks

(script static void m_exit_launch
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_int_shaft_c m_exit_spawn_0 m_exit_spawn_1)

    ;; Special gun for the special difficulty
    ;; CO-OP: If more players are added, equip all of them here, but don't forget -- there is only one silent battle rifle
    (if (game_is_easy)
        (begin
            (player_add_equipment (player0) checkpoint_easy_silent true)
            (player_add_equipment (player1) checkpoint_easy true)
        )
    )
)

(script static void m_exit_start
    ;; Launch mission if we have to
    (if (= b30r_launch_exit mission_launch_index)
        (m_exit_launch)
    )

    (wake m_exit_main)
    (set m_exit_automig_start true)
    (wake m_exit_door_witch)
    (wake m_exit_end)
    (if (game_is_easy)
        (begin
            (wake m_exit_secret_end)
            (wake m_exit_secret_cutscene)
        )
    )

    ;; Activate the lobby door
    (device_set_power int_shaft_b_lobby_door 1)
    (device_set_position_immediate int_shaft_b_lobby_door 0)
)

(script static void m_exit_skip
    (set mission_state mission_extracted)

    ;; Elevator was used (again)
    (device_group_set_immediate position_int_shaft_a_elevator 0)
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - End
(global long m_exit_ctrl_state 0)

(script dormant m_exit_control
    (if (!= m_exit_ctrl_state 1)
        (m_exit_skip)
        (m_exit_start)
    )

    (sleep_until (>= m_exit_ctrl_state 3))
    ;; Honestly it's the end of the mission, there's no point in cleaning anything up
)

(script static void m_exit_startup
    (if (= 0 m_exit_ctrl_state)
        (begin
            (set m_exit_ctrl_state 1)
            (wake m_exit_control)
        )
    )
)

(script static void m_exit_cleanup
    (set m_exit_ctrl_state 3)
)

(script static void m_exit_mark_skip
    (m_exit_startup)
    (set m_exit_ctrl_state 2)
)
