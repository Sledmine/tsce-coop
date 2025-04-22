;; 12_b30_revamp_mission_int_cart.hsc
;; Sub-mission for "int", isolated to this file because it's monstrously large
;; ---

;; ---
;; The sweet rewarding cutscene

(script static void m_int_cart_cutscene
    ;; Cinematic fade out
    (fade_to_white)
    (skip_second)
    (cinematic_start)
    
    ;; Now that we've faded out, scoot the Hunters out of the way
    (ai_teleport_to_starting_location int_cart_hunters_side)

    ;; Let's not have people shooting at us during our little celebration
    (ai_braindead int_cart_brutes true)
    (ai_braindead int_cart_evolved true)
    (ai_braindead int_cart_classic true)
    (ai_braindead int_cart_sides true)
    (ai_braindead int_cart_hunters true)
    (ai_braindead int_cart_hunters_side true)
    
    ;; Victory music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_16_cart_active")
    
    ;; Setup
    (show_hud false)
    (player_enable_input false)
    (camera_control true)
    (teleport_players int_cart_cutscene_wait int_cart_cutscene_wait)
    (skip_frame)
    
    (X_CUT_setup_player0 cart_cyborg_0)
    (unit_set_seat cart_cyborg_0 alert)
    (object_teleport cart_cyborg_0 int_cart_activate)
    
    ;; CO-OP: If more players are added, set up all of them here
    (if (game_is_cooperative)
        (begin
            (X_CUT_setup_player1 cart_cyborg_1)
            (unit_set_seat cart_cyborg_1 alert)
        )
    )

    ;; Recreate the ring to reset its animation for the cutscene
    (object_create_anew int_shaft_c_holo_ring)
    
    ;; Camerawork starts
    (camera_set int_cart_1a 0)
    (camera_set int_cart_1b 180)
    
    ;; Fade in, wait a moment
    (fade_from_white)
    (skip_second)
    
    ;; Cortana says things as the ring expands
    (device_set_position int_shaft_c_holo_ring 1)
    (sound_impulse_start "cmt\sounds\sfx\scenarios\b30_revamp\foley\b30r_ring_foley" none 1)
    (if (> (device_group_get position_ext_sec_security_holo) 0)
        (ai_conversation int_cart_switch)
        (ai_conversation int_cart_switch_bonus)
    )
    (sleep 135)
    
    ;; Cut to view of control segment
    (camera_set int_cart_2 0)
    (sleep 145)
    
    ;; Player1 moves to join
    (if (game_is_cooperative)
        (recording_play cart_cyborg_1 cart_cyborg_approach)
    )
    (sleep 15)
    
    ;; Cut to MCs
    (camera_set int_cart_3a 0)
    (camera_set int_cart_3b 300)
    (sleep 80)
    
    ;; Have player0 look around like the fool he is
    (custom_animation cart_cyborg_0 "cmt\characters\_shared\cyborg\cinematics\animations\level_specific\b30_revamp\b30_revamp" "look_with_intent" false)
    (sleep 170)
    
    ;; Fade out
    (fade_to_white) 
    (skip_half_second)
    
    ;; Wake the aliens back up
    (ai_braindead int_cart_brutes false)
    (ai_braindead int_cart_evolved false)
    (ai_braindead int_cart_classic false)
    (ai_braindead int_cart_sides false)
    (ai_braindead int_cart_hunters false)
    (ai_braindead int_cart_hunters_side false)
    
    ;; Clean
    ;; CO-OP: If more players are added, clean up all of them here
    (teleport_players int_cart_cutscene_end_0 int_cart_cutscene_end_1)
    (X_CUT_teardown_player0 cart_cyborg_0)
    
    (if (game_is_cooperative)
        (X_CUT_teardown_player1 cart_cyborg_1)
    )
    
    (cinematic_stop)
    (camera_control false)
    (show_hud true)
    (player_enable_input true)
    (game_save_totally_unsafe)
    
    ;; New objective
    (set mission_state mission_cartographer_activated)
    
    ;; Fade in
    (fade_from_white)
    (skip_half_second)
)

;; ---
;; The big cartographer battle

;; How often each updater updates
(global short cart_update_cycle_rate 7)

;; Where is the player this update cycle?
;; Left / right / front / center / back / upper / any of the prior
(global long player_pos_l 0)
(global long player_pos_r 1)
(global long player_pos_f 2)
(global long player_pos_c 3)
(global long player_pos_b 4)
(global long player_pos_u 5)
(global long player_pos_any 6)

(global long m_int_cart_pos_statebits 0)

;; This guy keeps the checkpoints coming
(global real m_int_cart_checkpoint_limit 5)
(global boolean m_int_cart_checkpoint_start false)
(script continuous m_int_cart_checkpoint_bastard
    (sleep_until m_int_cart_checkpoint_start 1)

    (sleep_until
        (and
            (not (game_safe_to_save))
            (volume_test_players_any int_cart_main)
        )
    )
    (sleep_until
        (game_safe_to_save)
    )
    (game_save_no_timeout)
    (set m_int_cart_checkpoint_limit (- m_int_cart_checkpoint_limit 1))
    (if (= m_int_cart_checkpoint_limit 0)
        (sleep_forever)
    )
)

;; ---
;; GENERATORS
;; ---

;; How many generators are online
(global short m_int_cart_gen_count 0)

;; "Combine some things together to save on those precious globals"
;; ...used to be the rationale. Now that we don't use the preprocessor,
;; we must use both globals AND the bit fields to preserve stability. Ouch.
(global long player_approached_bit 0)
(global long player_fled_bit 1)
(global long guards_tapped_bit 2)
(global long guards_pushed_bit 3)
(global long guards_destroyed_bit 4)
(global long catwalk_placed_bit 5)
(global long reins_l_place_bit 6)
(global long reins_l_placed_bit 7)
(global long reins_r_place_bit 8)
(global long reins_r_placed_bit 9)
(global long reins_other_triggered_bit 10)
(global long guards_broken_bit 11)
(global long ended_bit 12)
(global long gen_bit 13)

;; Bitfields tracking state of each generator's battle
(global long m_int_cart_classic_statebits 0)
(global long m_int_cart_brute_statebits 0)
(global long m_int_cart_evolved_statebits 0)

;; ---
;; Cross-generator interaction

;; END IT ALL (just contains the end-of-battle logic for each generator)
(script stub void m_int_cart_brute_end (print "UNIMPLEMENTED: m_int_cart_brute_end"))
(script stub void m_int_cart_evolved_end (print "UNIMPLEMENTED: m_int_cart_evolved_end"))
(script stub void m_int_cart_classic_end (print "UNIMPLEMENTED: m_int_cart_classic_end"))

;; Calls for reinforcements to be placed on either side (each generator triggers reins for the other 2)
(script static void m_int_cart_classic_rein_left    (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits reins_l_place_bit true)))
(script static void m_int_cart_classic_rein_right   (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits reins_r_place_bit true)))
(script static void m_int_cart_evolved_rein_left    (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits reins_l_place_bit true)))
(script static void m_int_cart_evolved_rein_right   (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits reins_r_place_bit true)))
(script static void m_int_cart_brute_rein_left      (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits reins_l_place_bit true)))
(script static void m_int_cart_brute_rein_right     (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits reins_r_place_bit true)))

;; ---
;; Classic generator

;; How long have the players been fighting us?
(global long m_int_cart_classic_combat_ticks 0)

;; A lot of triggers have to happen, and this is the thing that does that
(global boolean m_int_cart_classic_start false)
(script continuous m_int_cart_classic_updater
    (sleep_until m_int_cart_classic_start 1)

    ;; Figure out where the players are
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_l (volume_test_players_all int_cart_classic_left)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_r (volume_test_players_all int_cart_classic_right)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_f (volume_test_players_all int_cart_classic_front)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_c (volume_test_players_all int_cart_classic_center)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_b (volume_test_players_all int_cart_classic_back)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_u (volume_test_players_all int_cart_upper)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_any
        (or
            (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
            (game_is_cooperative)   ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
        )
    ))

    ;; Move people around
    (if (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
        (begin
            (ai_migrate int_cart_classic/anchors_core int_cart_classic/anchors_core_left)
            (ai_migrate int_cart_classic/fodder_core int_cart_classic/fodder_core_left)
            (ai_migrate int_cart_classic/catwalk int_cart_classic/catwalk_left)

            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_classic/support_left int_cart_classic/support_left_left)
                (ai_migrate int_cart_classic/support_left int_cart_classic/support_left_center)
            )
            (ai_migrate int_cart_classic/support_right int_cart_classic/support_right_left)

            (ai_migrate int_cart_classic/stragglers int_cart_classic/stragglers_left)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
        (begin
            (ai_migrate int_cart_classic/anchors_core int_cart_classic/anchors_core_right)
            (ai_migrate int_cart_classic/fodder_core int_cart_classic/fodder_core_right)
            (ai_migrate int_cart_classic/catwalk int_cart_classic/catwalk_right)

            (ai_migrate int_cart_classic/support_left int_cart_classic/support_left_right)
            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_classic/support_right int_cart_classic/support_right_right)
                (ai_migrate int_cart_classic/support_right int_cart_classic/support_right_center)
            )

            (ai_migrate int_cart_classic/stragglers int_cart_classic/stragglers_right)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
        (begin
            ;; Ignore core and stragglers unless we're in the center
            (if (and (!= (bit_test m_int_cart_pos_statebits player_pos_r) 1) (!= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (begin
                    (ai_migrate int_cart_classic/anchors_core int_cart_classic/anchors_core_front)
                    (ai_migrate int_cart_classic/fodder_core int_cart_classic/anchors_core_front)

                    (ai_migrate int_cart_classic/stragglers int_cart_classic/stragglers_front)
                )
            )
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
        (begin
            (ai_migrate int_cart_classic/anchors_core int_cart_classic/anchors_core_center)
            (ai_migrate int_cart_classic/fodder_core int_cart_classic/fodder_core_center)

            (ai_migrate int_cart_classic/support_left int_cart_classic/support_left_rear)
            (ai_migrate int_cart_classic/support_right int_cart_classic/support_right_rear)

            (ai_migrate int_cart_classic/stragglers int_cart_classic/stragglers_center)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
        (begin
            (ai_migrate int_cart_classic/support_left int_cart_classic/support_left_rear)
            (ai_migrate int_cart_classic/support_right int_cart_classic/support_right_rear)

            (ai_migrate int_cart_classic/stragglers int_cart_classic/stragglers_center)
        )
    )

    ;; Some events can happen too.

    ;; Did the players do some damage?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits guards_tapped_bit) 1)
            (> 0.75 (ai_living_fraction int_cart_classic))
        )
        (begin
            (print_debug "m_int_cart_classic_updater: guards tapped")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_tapped_bit true))
        )
    )

    ;; Did the players do some major damage?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits guards_pushed_bit) 1)            
            (or
                (> 0.5 (ai_living_fraction int_cart_classic))
                (= 0 (ai_living_count int_cart_classic/anchors_core))
            )
        )
        (begin
            (print_debug "m_int_cart_classic_updater: guards pushed")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_tapped_bit true))
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_pushed_bit true))
        )
    )

    ;; Did the players destroy us?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits guards_destroyed_bit) 1)
            (> 0.25 (ai_living_fraction int_cart_classic))
        )
        (begin
            (print_debug "m_int_cart_classic_updater: guards destroyed")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_tapped_bit true))
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_pushed_bit true))
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_destroyed_bit true))
        )
    )

    ;; Did the players finally approach us?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits player_approached_bit) 1)
            (or
                (= (bit_test m_int_cart_classic_statebits guards_pushed_bit) 1)
                (and
                    (= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
                    (not
                        (and
                            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
                            (!= (bit_test m_int_cart_classic_statebits guards_tapped_bit) 1)
                        )
                    )
                )
            )
        )
        (begin
            (print_debug "m_int_cart_classic_updater: player approached")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits player_approached_bit true))

            ;; Some units are on command lists until the players shows up, let them advance
            (ai_command_list_advance int_cart_classic)

            ;; We know you're here if this is a frontal assault
            (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
                (begin
                    (ai_magically_see_players int_cart_classic)
                    (print_debug "m_int_cart_classic_updater: player approached with frontal assault")
                )
            )
        )
    )

    ;; Did the players run away?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits player_fled_bit) 1)
            (= (bit_test m_int_cart_classic_statebits player_approached_bit) 1)
            (!= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
        )
        (begin
            (print_debug "m_int_cart_classic_updater: player is a coward")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits player_fled_bit true))
            (game_save_no_timeout)
        )
    )

    ;; Is our shit fucked?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits guards_broken_bit) 1)
            (or
                (= (bit_test m_int_cart_classic_statebits gen_bit) 1)
                (= (bit_test m_int_cart_classic_statebits guards_destroyed_bit) 1)
            )
        )
        (begin
            (print_debug "m_int_cart_classic_updater: units broken")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits guards_broken_bit true))

            ;; Potentially berserk the other side's supporters, if we're on a side
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (ai_berserk int_cart_classic/support_right true)
            )
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_r) 1))
                (ai_berserk int_cart_classic/support_left true)
            )

            ;; Everybody run!
            (ai_maneuver int_cart_classic)
        )
    )

    ;; Can we call for reinforcements for our buddies?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits reins_other_triggered_bit) 1)
            (or
                (= (bit_test m_int_cart_classic_statebits gen_bit) 1)
                (and
                    (= (bit_test m_int_cart_classic_statebits guards_destroyed_bit) 1)
                    (> m_int_cart_classic_combat_ticks 120)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_classic_updater: calling other gens' reins")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits reins_other_triggered_bit true))

            ;; The others will have their revenge..!
            (m_int_cart_evolved_rein_left)
            (m_int_cart_brute_rein_right)
        )
    )

    ;; Is it time for this to end?
    (if (and
            (or
                (= (bit_test m_int_cart_classic_statebits guards_broken_bit) 1)
                (and
                    (= (bit_test m_int_cart_classic_statebits guards_pushed_bit) 1)
                    (> m_int_cart_classic_combat_ticks 180)
                )
            )
            (= 3 m_int_cart_gen_count)
        )
        (begin
            (print_debug "m_int_cart_classic_updater: ending")
            (m_int_cart_classic_end)
        )
    )

    ;; We can get some reinforcements

    ;; Can we place the left people?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits reins_l_placed_bit) 1)
            (!= (bit_test m_int_cart_classic_statebits gen_bit) 1)
            (= (bit_test m_int_cart_classic_statebits reins_l_place_bit) 1)
            (not (volume_test_players_any int_cart_classic_secret_l))
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_classic_updater: placing right reins")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits reins_l_placed_bit true))

            ;; Send them in
            (if (game_is_impossible)
                (begin
                    (ai_place int_cart_classic/elites_core_rein_imposs)
                    (ai_migrate int_cart_classic/elites_core_rein_imposs int_cart_classic/elites_core_rein)
                )
                (ai_place int_cart_classic/elites_core_rein)
            )
            (ai_place int_cart_classic/jackals_left_rein)
            (ai_magically_see_players int_cart_classic)
        )
    )

    ;; Can we place the right people?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits reins_r_placed_bit) 1)
            (!= (bit_test m_int_cart_classic_statebits gen_bit) 1)
            (= (bit_test m_int_cart_classic_statebits reins_r_place_bit) 1)
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_classic_updater: placing right reins")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits reins_r_placed_bit true))

            ;; Send them in
            (ai_place int_cart_classic/jackals_right_rein)
            (ai_magically_see_players int_cart_classic)
        )
    )

    ;; Can we place the catwalk people?
    (if (and
            (!= (bit_test m_int_cart_classic_statebits catwalk_placed_bit) 1)
            (> 2 (ai_living_count int_cart_hunters))
            (or
                (= (bit_test m_int_cart_classic_statebits guards_destroyed_bit) 1)
                (> m_int_cart_classic_combat_ticks 90)
                (and
                    (= (bit_test m_int_cart_classic_statebits reins_r_placed_bit) 1)
                    (= (bit_test m_int_cart_classic_statebits reins_l_placed_bit) 1)
                )
                (and
                    (= (bit_test m_int_cart_classic_statebits guards_pushed_bit) 1)
                    (= (bit_test m_int_cart_classic_statebits player_fled_bit) 1)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_classic_updater: placing catwalk reins")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits catwalk_placed_bit true))

            ;; yep, we can place the catwalk people
            (ai_place int_cart_classic/grunts_catwalk_rein)
            (ai_magically_see_players int_cart_classic)
        )
    )

    ;; Some timers are counting as well

    ;; Keep track of how long the players have been in combat with us
    (if (and
            (= (bit_test m_int_cart_classic_statebits player_approached_bit) 1)
            (= (bit_test m_int_cart_classic_statebits guards_tapped_bit) 1)
        )
        (set m_int_cart_classic_combat_ticks
            (+ m_int_cart_classic_combat_ticks cart_update_cycle_rate)
        )
    )

    (sleep cart_update_cycle_rate)
)

(script dormant m_int_cart_classic_objs
    ;; If the generator got activated, mark it
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_classc)))
    (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits gen_bit true))

    ;; A new generator is online
    (set m_int_cart_gen_count (+ m_int_cart_gen_count 1))

    ;; No need for the hint
    (deactivate_team_nav_point_flag player int_cart_gen_classic_nav)
)

(script static void m_int_cart_classic_end
    (if (!= (bit_test m_int_cart_classic_statebits ended_bit) 1)
        (begin
            (print_debug "m_int_cart_classic_end")
            (set m_int_cart_classic_statebits (bit_toggle m_int_cart_classic_statebits ended_bit true))

            ;; Kill the updater
            (sleep -1 m_int_cart_classic_updater)

            ;; Fuck we're so fucked we have to kill the player or mr. zealot is gonna fire us
            (ai_migrate int_cart_classic/stragglers_left int_cart_sides/right_lower)
            (ai_migrate int_cart_classic/stragglers_center int_cart_sides/right_upper)
            (ai_migrate int_cart_classic/stragglers_right int_cart_sides/right_lower)
            (ai_migrate int_cart_classic/stragglers_front int_cart_sides/right_upper)
        )
    )
)

(script static void m_int_cart_classic_init
    ;; Place the mans, and womans
    (if (game_is_impossible)
        (begin
            (ai_place int_cart_classic/elites_core_imposs)
            (ai_migrate int_cart_classic/elites_core_imposs int_cart_classic/elites_core)
        )
        (ai_place int_cart_classic/elites_core)
    )
    (ai_place int_cart_classic/jackals_left)
    (ai_place int_cart_classic/jackals_right)
    (ai_place int_cart_classic/grunts_left)
    (ai_place int_cart_classic/grunts_right)

    ;; Wake the updater
    (set m_int_cart_classic_start true)
    (wake m_int_cart_classic_objs)
)

;; ---
;; Evolved generator

;; How long has the player been fighting us?
(global long m_int_cart_evolved_combat_ticks 0)

;; A lot of triggers have to happen, and this is the thing that does that
(global boolean m_int_cart_evolved_start false)
(script continuous m_int_cart_evolved_updater
    (sleep_until m_int_cart_evolved_start 1)

    ;; Figure out where the player is
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_l (volume_test_players_all int_cart_evolved_left)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_r (volume_test_players_all int_cart_evolved_right)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_f (volume_test_players_all int_cart_evolved_front)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_c (volume_test_players_all int_cart_evolved_center)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_b (volume_test_players_all int_cart_evolved_back)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_u (volume_test_players_all int_cart_upper)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_any
        (or
            (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
            (game_is_cooperative)   ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
        )
    ))

    ;; Move people around
    (if (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
        (begin
            (ai_migrate int_cart_evolved/anchors_core int_cart_evolved/anchors_core_left)
            (ai_migrate int_cart_evolved/fodder_core int_cart_evolved/fodder_core_left)
            (ai_migrate int_cart_evolved/catwalk int_cart_evolved/catwalk_left)

            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_evolved/support_left int_cart_evolved/support_left_left)
                (ai_migrate int_cart_evolved/support_left int_cart_evolved/support_left_center)
            )
            (ai_migrate int_cart_evolved/support_right int_cart_evolved/support_right_left)

            (ai_migrate int_cart_evolved/stragglers int_cart_evolved/stragglers_left)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
        (begin
            (ai_migrate int_cart_evolved/anchors_core int_cart_evolved/anchors_core_right)
            (ai_migrate int_cart_evolved/fodder_core int_cart_evolved/fodder_core_right)
            (ai_migrate int_cart_evolved/catwalk int_cart_evolved/catwalk_right)

            (ai_migrate int_cart_evolved/support_left int_cart_evolved/support_left_right)
            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_evolved/support_right int_cart_evolved/support_right_right)
                (ai_migrate int_cart_evolved/support_right int_cart_evolved/support_right_center)
            )

            (ai_migrate int_cart_evolved/stragglers int_cart_evolved/stragglers_right)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
        (begin
            ;; Ignore core and stragglers unless we're in the center
            (if (and (!= (bit_test m_int_cart_pos_statebits player_pos_r) 1) (!= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (begin
                    (ai_migrate int_cart_evolved/anchors_core int_cart_evolved/anchors_core_front)
                    (ai_migrate int_cart_evolved/fodder_core int_cart_evolved/anchors_core_front)

                    (ai_migrate int_cart_evolved/stragglers int_cart_evolved/stragglers_front)
                )
            )
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
        (begin
            (ai_migrate int_cart_evolved/anchors_core int_cart_evolved/anchors_core_center)
            (ai_migrate int_cart_evolved/fodder_core int_cart_evolved/fodder_core_center)

            (ai_migrate int_cart_evolved/support_left int_cart_evolved/support_left_rear)
            (ai_migrate int_cart_evolved/support_right int_cart_evolved/support_right_rear)

            (ai_migrate int_cart_evolved/stragglers int_cart_evolved/stragglers_center)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
        (begin
            (ai_migrate int_cart_evolved/support_left int_cart_evolved/support_left_rear)
            (ai_migrate int_cart_evolved/support_right int_cart_evolved/support_right_rear)

            (ai_migrate int_cart_evolved/stragglers int_cart_evolved/stragglers_center)
        )
    )

    ;; Some events can happen too

    ;; Did the players do some damage?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits guards_tapped_bit) 1)
            (> 0.75 (ai_living_fraction int_cart_evolved))
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: guards tapped")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_tapped_bit true))
        )
    )

    ;; Did the players do some major damage?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits guards_pushed_bit) 1)
            (or
                (> 0.5 (ai_living_fraction int_cart_evolved))
                (= 0 (ai_living_count int_cart_evolved/anchors_core))
            )
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: guards pushed")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_tapped_bit true))
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_pushed_bit true))
        )
    )

    ;; Did the players destroy us?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits guards_destroyed_bit) 1)
            (> 0.25 (ai_living_fraction int_cart_evolved))
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: guards destroyed")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_tapped_bit true))
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_pushed_bit true))
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_destroyed_bit true))
        )
    )

    ;; Did the players finally approach us?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits player_approached_bit) 1)
            (or
                (= (bit_test m_int_cart_evolved_statebits guards_pushed_bit) 1)
                (and
                    (= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
                    (not
                        (and
                            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
                            (!= (bit_test m_int_cart_evolved_statebits guards_tapped_bit) 1)
                        )
                    )
                )
            )
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: player approached")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits player_approached_bit true))

            ;; Some units are on command lists until the player shows up, let them advance
            (ai_command_list_advance int_cart_evolved)

            ;; We know you're here if this is a frontal assault
            (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
                (begin
                    (ai_magically_see_players int_cart_evolved)
                    (print_debug "m_int_cart_evolved_updater: player approached with frontal assault")
                )
            )
        )
    )

    ;; Did the players run away?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits player_fled_bit) 1)
            (= (bit_test m_int_cart_evolved_statebits player_approached_bit) 1)
            (!= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: player is a coward")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits player_fled_bit true))
            (game_save_no_timeout)
        )
    )

    ;; Is our shit fucked?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits guards_broken_bit) 1)
            (or
                (= (bit_test m_int_cart_evolved_statebits gen_bit) 1)
                (= (bit_test m_int_cart_evolved_statebits guards_destroyed_bit) 1)
            )
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: units broken")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits guards_broken_bit true))

            ;; Potentially berserk the other side's supporters, if we're on a side
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (ai_berserk int_cart_evolved/support_right true)
            )
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_r) 1))
                (ai_berserk int_cart_evolved/support_left true)
            )

            ;; Everybody run!
            (ai_maneuver int_cart_evolved)
        )
    )

    ;; Can we call for reinforcements for our buddies?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits reins_other_triggered_bit) 1)
            (or
                (= (bit_test m_int_cart_evolved_statebits gen_bit) 1)
                (and
                    (= (bit_test m_int_cart_evolved_statebits guards_destroyed_bit) 1)
                    (> m_int_cart_evolved_combat_ticks 120)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: calling other gens' reins")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits reins_other_triggered_bit true))

            ;; The others will have their revenge..!
            (m_int_cart_brute_rein_left)
            (m_int_cart_classic_rein_right)
        )
    )

    ;; Is it time for this to end?
    (if (and
            (or
                (= (bit_test m_int_cart_evolved_statebits guards_broken_bit) 1)
                (and
                    (= (bit_test m_int_cart_evolved_statebits guards_pushed_bit) 1)
                    (> m_int_cart_evolved_combat_ticks 180)
                )
            )
            (= 3 m_int_cart_gen_count)
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: ending")
            (m_int_cart_evolved_end)
        )
    )

    ;; we can get some reinforcements

    ;; Can we place the left people?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits reins_l_placed_bit) 1)
            (!= (bit_test m_int_cart_evolved_statebits gen_bit) 1)
            (= (bit_test m_int_cart_evolved_statebits reins_l_place_bit) 1)
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: placing right reins")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits reins_l_placed_bit true))

            ;; Send them in
            (ai_place int_cart_evolved/elites_left_rein)
            (ai_place int_cart_evolved/jackals_left_rein)
            (ai_magically_see_players int_cart_evolved)
        )
    )

    ;; Can we place the right people?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits reins_r_placed_bit) 1)
            (!= (bit_test m_int_cart_evolved_statebits gen_bit) 1)
            (= (bit_test m_int_cart_evolved_statebits reins_r_place_bit) 1)
            (not (volume_test_players_any int_cart_evolved_secret_r))
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: placing right reins")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits reins_r_placed_bit true))

            ;; Send them in - and make them specops on legendary
            (if (game_is_impossible)
                (begin
                    (ai_place int_cart_evolved/grunts_right_rein_imposs)
                    (ai_migrate int_cart_evolved/grunts_right_rein_imposs int_cart_evolved/grunts_right_rein)
                )
                (ai_place int_cart_evolved/grunts_right_rein)
            )
            (ai_magically_see_players int_cart_evolved)
        )
    )

    ;; Can we place the catwalk people?
    (if (and
            (!= (bit_test m_int_cart_evolved_statebits catwalk_placed_bit) 1)
            (> 2 (ai_living_count int_cart_hunters))
            (or
                (= (bit_test m_int_cart_evolved_statebits guards_destroyed_bit) 1)
                (> m_int_cart_evolved_combat_ticks 90)
                (and
                    (= (bit_test m_int_cart_evolved_statebits reins_r_placed_bit) 1)
                    (= (bit_test m_int_cart_evolved_statebits reins_l_placed_bit) 1)
                )
                (and
                    (= (bit_test m_int_cart_evolved_statebits guards_pushed_bit) 1)
                    (= (bit_test m_int_cart_evolved_statebits player_fled_bit) 1)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_evolved_updater: placing catwalk reins")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits catwalk_placed_bit true))

            ;; Yep, we can place the catwalk people
            (ai_place int_cart_evolved/jackals_catwalk_rein)
            (ai_magically_see_players int_cart_evolved)
        )
    )

    ;; Some timers are counting as well

    ;; Keep track of how long the player has been in combat with us
    (if (and
            (= (bit_test m_int_cart_evolved_statebits player_approached_bit) 1)
            (= (bit_test m_int_cart_evolved_statebits guards_tapped_bit) 1)
        )
        (set m_int_cart_evolved_combat_ticks
            (+ m_int_cart_evolved_combat_ticks cart_update_cycle_rate)
        )
    )

    (sleep cart_update_cycle_rate)
)

(script dormant m_int_cart_evolved_objs
    ;; If the generator got activated, mark it
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_evolve)) 1)
    (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits gen_bit true))

    ;; A new generator is online
    (set m_int_cart_gen_count (+ m_int_cart_gen_count 1))

    ;; No need for the hint
    (deactivate_team_nav_point_flag player int_cart_gen_evolved_nav)
)

(script static void m_int_cart_evolved_end
    (if (!= (bit_test m_int_cart_evolved_statebits ended_bit) 1)
        (begin
            (print_debug "m_int_cart_evolved_end")
            (set m_int_cart_evolved_statebits (bit_toggle m_int_cart_evolved_statebits ended_bit true))

            ;; Kill the updater
            (sleep -1 m_int_cart_evolved_updater)

            ;; Fuck we're so fucked we have to kill the player or mr. zealot is gonna fire us
            (ai_migrate int_cart_evolved/stragglers_left int_cart_sides/left_lower)
            (ai_migrate int_cart_evolved/stragglers_center int_cart_sides/left_upper)
            (ai_migrate int_cart_evolved/stragglers_right int_cart_sides/left_lower)
            (ai_migrate int_cart_evolved/stragglers_front int_cart_sides/left_upper)
        )
    )
)

(script static void m_int_cart_evolved_init
    ;; Place the mans, and womans
    (ai_place int_cart_evolved/elites_core)
    (ai_place int_cart_evolved/jackals_left)
    (ai_place int_cart_evolved/jackals_right)
    
    ;; Adjust for legendary
    (if (game_is_impossible)
        (begin
            (ai_place int_cart_evolved/grunts_core_imposs)
            (ai_migrate int_cart_evolved/grunts_core_imposs int_cart_evolved/grunts_core)
        )
        (ai_place int_cart_evolved/grunts_core)
    )

    ;; Wake the updater
    (set m_int_cart_evolved_start true)
    (wake m_int_cart_evolved_objs)
)

;; ---
;; Brute generator

;; How long have the players been fighting us?
(global long m_int_cart_brutes_combat_ticks 0)

;; A lot of triggers have to happen, and this is the thing that does that
(global boolean m_int_cart_brute_start false)
(script continuous m_int_cart_brute_updater
    (sleep_until m_int_cart_brute_start 1)

    ;; Figure out where the player is
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_l (volume_test_players_all int_cart_brutes_left)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_r (volume_test_players_all int_cart_brutes_right)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_f (volume_test_players_all int_cart_brutes_front)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_c (volume_test_players_all int_cart_brutes_center)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_b (volume_test_players_all int_cart_brutes_back)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_u (volume_test_players_all int_cart_upper)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_any
        (or
            (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
            (game_is_cooperative)   ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
        )
    ))

    ;; Move people around
    (if (= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
        (begin
            (ai_migrate int_cart_brutes/anchors_core int_cart_brutes/anchors_core_left)
            (ai_migrate int_cart_brutes/fodder_core int_cart_brutes/fodder_core_left)
            (ai_migrate int_cart_brutes/catwalk int_cart_brutes/catwalk_left)

            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_brutes/support_left int_cart_brutes/support_left_left)
                (ai_migrate int_cart_brutes/support_left int_cart_brutes/support_left_center)
            )
            (ai_migrate int_cart_brutes/support_right int_cart_brutes/support_right_left)

            (ai_migrate int_cart_brutes/stragglers int_cart_brutes/stragglers_left)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
        (begin
            (ai_migrate int_cart_brutes/anchors_core int_cart_brutes/anchors_core_right)
            (ai_migrate int_cart_brutes/fodder_core int_cart_brutes/fodder_core_right)
            (ai_migrate int_cart_brutes/catwalk int_cart_brutes/catwalk_right)

            (ai_migrate int_cart_brutes/support_left int_cart_brutes/support_left_right)
            (if (!= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
                (ai_migrate int_cart_brutes/support_right int_cart_brutes/support_right_right)
                (ai_migrate int_cart_brutes/support_right int_cart_brutes/support_right_center)
            )

            (ai_migrate int_cart_brutes/stragglers int_cart_brutes/stragglers_right)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
        (begin
            ;; Ignore core and stragglers unless we're in the center
            (if (and (!= (bit_test m_int_cart_pos_statebits player_pos_r) 1) (!= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (begin
                    (ai_migrate int_cart_brutes/anchors_core int_cart_brutes/anchors_core_front)
                    (ai_migrate int_cart_brutes/fodder_core int_cart_brutes/anchors_core_front)

                    (ai_migrate int_cart_brutes/stragglers int_cart_brutes/stragglers_front)
                )
            )
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_c) 1)
        (begin
            (ai_migrate int_cart_brutes/anchors_core int_cart_brutes/anchors_core_center)
            (ai_migrate int_cart_brutes/fodder_core int_cart_brutes/fodder_core_center)

            (ai_migrate int_cart_brutes/support_left int_cart_brutes/support_left_rear)
            (ai_migrate int_cart_brutes/support_right int_cart_brutes/support_right_rear)

            (ai_migrate int_cart_brutes/stragglers int_cart_brutes/stragglers_front)
        )
    )
    (if (= (bit_test m_int_cart_pos_statebits player_pos_b) 1)
        (begin
            (ai_migrate int_cart_brutes/support_left int_cart_brutes/support_left_rear)
            (ai_migrate int_cart_brutes/support_right int_cart_brutes/support_right_rear)

            (ai_migrate int_cart_brutes/stragglers int_cart_brutes/stragglers_center)
        )
    )

    ;; Some events can happen too

    ;; Did the players do some damage?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits guards_tapped_bit) 1)
            (> 0.75 (ai_living_fraction int_cart_brutes))
        )
        (begin
            (print_debug "m_int_cart_brute_updater: guards tapped")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_tapped_bit true))
        )
    )

    ;; Did the players do some major damage?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits guards_pushed_bit) 1)
            (or
                (> 0.5 (ai_living_fraction int_cart_brutes))
                (= 0 (ai_living_count int_cart_brutes/anchors_core))
            )
        )
        (begin
            (print_debug "m_int_cart_brute_updater: guards pushed")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_tapped_bit true))
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_pushed_bit true))
        )
    )

    ;; Did the players destroy us?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits guards_destroyed_bit) 1)
            (> 0.25 (ai_living_fraction int_cart_brutes))
        )
        (begin
            (print_debug "m_int_cart_brute_updater: guards destroyed")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_tapped_bit true))
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_pushed_bit true))
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_destroyed_bit true))
        )
    )

    ;; Did the players finally approach us?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits player_approached_bit) 1)
            (or
                (= (bit_test m_int_cart_brute_statebits guards_pushed_bit) 1)
                (and
                    (= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
                    (not
                        (and
                            (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
                            (!= (bit_test m_int_cart_brute_statebits guards_tapped_bit) 1)
                        )
                    )
                )
            )
        )
        (begin
            (print_debug "m_int_cart_brute_updater: player approached")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits player_approached_bit true))

            ;; Some units are on command lists until the player shows up, let them advance
            (ai_command_list_advance int_cart_brutes)

            ;; We know you're here if this is a frontal assault
            (if (= (bit_test m_int_cart_pos_statebits player_pos_f) 1)
                (begin
                    (print_debug "m_int_cart_brute_updater: player approached with frontal assault")
                    (ai_magically_see_players int_cart_brutes)
                )
            )
        )
    )

    ;; Did the players run away?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits player_fled_bit) 1)
            (= (bit_test m_int_cart_brute_statebits player_approached_bit) 1)
            (!= (bit_test m_int_cart_pos_statebits player_pos_any) 1)
        )
        (begin
            (print_debug "m_int_cart_brute_updater: player is a coward")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits player_fled_bit true))
            (game_save_no_timeout)
        )
    )

    ;; Is our shit fucked?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits guards_broken_bit) 1)
            (or
                (= (bit_test m_int_cart_brute_statebits gen_bit) 1)
                (= (bit_test m_int_cart_brute_statebits guards_destroyed_bit) 1)
            )
        )
        (begin
            (print_debug "m_int_cart_brute_updater: units broken")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits guards_broken_bit true))

            ;; Potentially berserk the other side's supporters, if we're on a side
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_l) 1))
                (ai_berserk int_cart_brutes/support_right true)
            )
            (if (and (random_chance_50) (= (bit_test m_int_cart_pos_statebits player_pos_r) 1))
                (ai_berserk int_cart_brutes/support_left true)
            )

            ;; Everybody run!
            (ai_maneuver int_cart_brutes)
        )
    )

    ;; Can we call for reinforcements for our buddies?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits reins_other_triggered_bit) 1)
            (or
                (= (bit_test m_int_cart_brute_statebits gen_bit) 1)
                (and
                    (= (bit_test m_int_cart_brute_statebits guards_destroyed_bit) 1)
                    (> m_int_cart_brutes_combat_ticks 120)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_brute_updater: calling other gens' reins")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits reins_other_triggered_bit true))

            ;; The others will have their revenge..!
            (m_int_cart_evolved_rein_right)
            (m_int_cart_classic_rein_left)
        )
    )

    ;; Is it time for this to end?
    (if (and
            (or
                (= (bit_test m_int_cart_brute_statebits guards_broken_bit) 1)
                (and
                    (= (bit_test m_int_cart_brute_statebits guards_pushed_bit) 1)
                    (> m_int_cart_brutes_combat_ticks 180)
                )
            )
            (= 3 m_int_cart_gen_count)
        )
        (begin
            (print_debug "m_int_cart_brute_updater: ending")
            (m_int_cart_brute_end)
        )
    )

    ;; We can get some reinforcements

    ;; Can we place the left people?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits reins_l_placed_bit) 1)
            (!= (bit_test m_int_cart_brute_statebits gen_bit) 1)
            (= (bit_test m_int_cart_brute_statebits reins_l_place_bit) 1)
            (not (volume_test_players_any int_cart_brute_secret_l))
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_brute_updater: placing right reins")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits reins_l_placed_bit true))

            ;; Send them in
            (ai_place int_cart_brutes/jackals_left_rein)
            (ai_place int_cart_brutes/grunts_left_rein)
            (ai_magically_see_players int_cart_brutes)
        )
    )

    ;; Can we place the right people?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits reins_r_placed_bit) 1)
            (!= (bit_test m_int_cart_brute_statebits gen_bit) 1)
            (= (bit_test m_int_cart_brute_statebits reins_r_place_bit) 1)
            (not (volume_test_players_any int_cart_brute_secret_r))
            (> 2 (ai_living_count int_cart_hunters))
        )
        (begin
            (print_debug "m_int_cart_brute_updater: placing right reins")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits reins_r_placed_bit true))

            ;; Send them in
            (ai_place int_cart_brutes/jackals_right_rein)
            (ai_place int_cart_brutes/grunts_right_rein)
            (ai_magically_see_players int_cart_brutes)
        )
    )

    ;; Can we place the catwalk people?
    (if (and
            (!= (bit_test m_int_cart_brute_statebits catwalk_placed_bit) 1)
            (> 2 (ai_living_count int_cart_hunters))
            (or
                (= (bit_test m_int_cart_brute_statebits guards_destroyed_bit) 1)
                (> m_int_cart_brutes_combat_ticks 90)
                (and
                    (= (bit_test m_int_cart_brute_statebits reins_r_placed_bit) 1)
                    (= (bit_test m_int_cart_brute_statebits reins_l_placed_bit) 1)
                )
                (and
                    (= (bit_test m_int_cart_brute_statebits guards_pushed_bit) 1)
                    (= (bit_test m_int_cart_brute_statebits player_fled_bit) 1)
                )
            )
        )
        (begin
            (print_debug "m_int_cart_brute_updater: placing catwalk reins")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits catwalk_placed_bit true))

            ;; Yep, we can place the catwalk people
            (ai_place int_cart_brutes/grunts_catwalk_rein)
            (ai_magically_see_players int_cart_brutes)
        )
    )

    ;; Some timers are counting as well

    ;; Keep track of how long the player has been in combat with us
    (if (and
            (= (bit_test m_int_cart_brute_statebits player_approached_bit) 1)
            (= (bit_test m_int_cart_brute_statebits guards_tapped_bit) 1)
        )
        (set m_int_cart_brutes_combat_ticks
            (+ m_int_cart_brutes_combat_ticks cart_update_cycle_rate)
        )
    )

    (sleep cart_update_cycle_rate)
)

(script dormant m_int_cart_brute_objs
    ;; If the generator got activated, mark it
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_brute)) 1)
    (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits gen_bit true))

    ;; A new generator is online
    (set m_int_cart_gen_count (+ m_int_cart_gen_count 1))

    ;; No need for the hint
    (deactivate_team_nav_point_flag player int_cart_gen_brute_nav)
)

(script static void m_int_cart_brute_end
    (if (!= (bit_test m_int_cart_brute_statebits ended_bit) 1)
        (begin
            (print_debug "m_int_cart_brute_end")
            (set m_int_cart_brute_statebits (bit_toggle m_int_cart_brute_statebits ended_bit true))

            ;; Kill the updater
            (sleep -1 m_int_cart_brute_updater)

            ;; Fuck we're so fucked we have to kill the player or mr. zealot is gonna fire us
            (ai_migrate int_cart_brutes/stragglers_left int_cart_sides/left_lower)
            (ai_migrate int_cart_brutes/stragglers_center int_cart_sides/left_upper)
            (ai_migrate int_cart_brutes/stragglers_right int_cart_sides/right_lower)
            (ai_migrate int_cart_brutes/stragglers_front int_cart_sides/right_upper)
        )
    )
)

(script static void m_int_cart_brute_init
    ;; Place the mans, and womans
    (ai_place int_cart_brutes/brutes_core)
    (ai_place int_cart_brutes/grunts_core)
    (ai_place int_cart_brutes/grunts_left)
    (ai_place int_cart_brutes/grunts_right)
    
    (cond
        (
            (= normal (game_difficulty_get_real))
            (ai_place int_cart_brutes/brutes_normal)
        )
        (
            (= hard (game_difficulty_get_real))
            (ai_place int_cart_brutes/brutes_hard)
        )
        (
            (game_is_impossible)
            (ai_place int_cart_brutes/brutes_imposs)
        )
    )

    ;; Wake the updater
    (set m_int_cart_brute_start true)
    (wake m_int_cart_brute_objs)
)

;; ---
;; SIDE UNITS
;; ---

(global long rein_l_placed_bit 0)
(global long rein_r_placed_bit 1)

;; This is actually many booleans combined into the bits of a long
(global long m_int_cart_sides_statebits 0)

(global boolean m_int_cart_sides_start false)
(script continuous m_int_cart_sides_updater
    (sleep_until m_int_cart_sides_start 1)
    
    ;; Figure out where the player is
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_l (volume_test_players_any int_cart_nook_left)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_r (volume_test_players_any int_cart_nook_right)))
    (set m_int_cart_pos_statebits (bit_toggle m_int_cart_pos_statebits player_pos_u (volume_test_players_any int_cart_upper)))

    ;; Move people around
    (if (!= (bit_test m_int_cart_pos_statebits player_pos_l) 1)
        (if (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
            (ai_migrate int_cart_sides/right int_cart_sides/right_upper)
            (ai_migrate int_cart_sides/right int_cart_sides/right_lower)
        )
    )

    (if (!= (bit_test m_int_cart_pos_statebits player_pos_r) 1)
        (if (= (bit_test m_int_cart_pos_statebits player_pos_u) 1)
            (ai_migrate int_cart_sides/left int_cart_sides/left_upper)
            (ai_migrate int_cart_sides/left int_cart_sides/left_lower)
        )
    )

    ;; We can get some reinforcements

    ;; Left sniper
    (if (and
            (!= (bit_test m_int_cart_sides_statebits rein_l_placed_bit) 1)
            (or
                (and
                    (<= 1 m_int_cart_gen_count)
                    (= 0 (ai_living_count int_cart_sides/left))
                    (= 0 (ai_living_count int_cart_sides/fodder_left))
                    (> 2 (ai_living_count int_cart_hunters))
                )
                (and
                    (<= 2 m_int_cart_gen_count)
                    (= 0 (ai_living_count int_cart_sides/left))
                    (= 0 (ai_living_count int_cart_sides/fodder_left))
                )
            )
        )
        (begin
            (print_debug "m_int_cart_sides_updater: placing left sniper & friends")
            (set m_int_cart_sides_statebits (bit_toggle m_int_cart_sides_statebits rein_l_placed_bit true))
            (ai_place int_cart_sides/sniper_left_rein)
            (ai_place int_cart_sides/grunts_left_rein)
            (ai_magically_see_players int_cart_sides)
        )
    )

    ;; Right sniper
    (if (and
            (!= (bit_test m_int_cart_sides_statebits rein_r_placed_bit) 1)
            (or
                (and
                    (<= 1 m_int_cart_gen_count)
                    (= 0 (ai_living_count int_cart_sides/right))
                    (= 0 (ai_living_count int_cart_sides/fodder_right))
                    (> 2 (ai_living_count int_cart_hunters))
                )
                (and
                    (<= 2 m_int_cart_gen_count)
                    (= 0 (ai_living_count int_cart_sides/right))
                    (= 0 (ai_living_count int_cart_sides/fodder_right))
                )
            )
        )
        (begin
            (print_debug "m_int_cart_sides_updater: placing right sniper & friends")
            (set m_int_cart_sides_statebits (bit_toggle m_int_cart_sides_statebits rein_r_placed_bit true))
            (ai_place int_cart_sides/sniper_right_rein)
            (ai_place int_cart_sides/grunts_right_rein)
            (ai_magically_see_players int_cart_sides)
        )
    )

    (sleep cart_update_cycle_rate)
)

(script static void m_int_cart_sides_init
    (print_debug "m_int_cart_sides_init")
    (ai_place int_cart_sides/grunts_left)
    (ai_place int_cart_sides/grunts_right)
    (ai_place int_cart_sides/jackals_left)
    (ai_place int_cart_sides/jackals_right)
    
    (ai_magically_see_players int_cart_sides)
    
    (set m_int_cart_sides_start true)
)

(script static void m_int_cart_sides_end
    (print_debug "m_int_cart_sides_end")
    (sleep -1 m_int_cart_sides_updater)
)

;; ---
;; HUNTERS
;; ---

(global unit m_int_cart_hunter_target none)

(global boolean m_int_cart_hunters_start false)
(script continuous m_int_cart_hunters_updater
    (sleep_until m_int_cart_hunters_start 1)

    ;; CO-OP: In co-op, Hunters navigate to intercept the closest player
    (if (game_is_cooperative)
        (if
            (<
                (objects_distance_to_object (ai_actors int_cart_hunters/hunter_chase) (player0))
                (objects_distance_to_object (ai_actors int_cart_hunters/hunter_chase) (player1))
            )
            (set m_int_cart_hunter_target (player0))
            (set m_int_cart_hunter_target (player1))
        )
        (set m_int_cart_hunter_target (player0))
    )

    
    ;; Move Hunters around
    (if (volume_test_object int_cart_entrance m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_entrance)
    )
    
    (if (volume_test_object int_cart_evolved_left m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_evolved_l)
    )
    
    (if (volume_test_object int_cart_evolved_right m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_evolved_r)
    )
    
    (if (volume_test_object int_cart_brutes_left m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_brute_l)
    )
    
    (if (volume_test_object int_cart_brutes_right m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_brute_r)
    )
    
    (if (volume_test_object int_cart_classic_left m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_classic_l)
    )
    
    (if (volume_test_object int_cart_classic_right m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_classic_r)
    )
    
    (if (volume_test_object int_cart_nook_left m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_l_nook)
    )

    (if (volume_test_object int_cart_nook_right m_int_cart_hunter_target)
        (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters/hunter_chase_r_nook)
    )
    
    ;; Move side Hunters around
    (cond
        (
            (or
                (volume_test_players_all int_cart_nook_right)
                (volume_test_players_all int_cart_brutes_left)
                (volume_test_players_all int_cart_classic_right)
            )
            (ai_migrate int_cart_hunters_side/right int_cart_hunters_side/right_present)
        )
        (
            (or
                (volume_test_players_all int_cart_brutes_front)
                (volume_test_players_all int_cart_classic_front)
            )
            (ai_migrate int_cart_hunters_side/right int_cart_hunters_side/right_near)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            (ai_migrate int_cart_hunters_side/right int_cart_hunters_side/right_all)
            
        )
        (
            true
            (ai_migrate int_cart_hunters_side/right int_cart_hunters_side/right_far)
        )
    )
    
    (cond
        (
            (or
                (volume_test_players_all int_cart_nook_left)
                (volume_test_players_all int_cart_brutes_right)
                (volume_test_players_all int_cart_evolved_left)
            )
            (ai_migrate int_cart_hunters_side/left int_cart_hunters_side/left_present)
        )
        (
            (or
                (volume_test_players_all int_cart_brutes_front)
                (volume_test_players_all int_cart_evolved_front)
            )
            (ai_migrate int_cart_hunters_side/left int_cart_hunters_side/left_near)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            (ai_migrate int_cart_hunters_side/left int_cart_hunters_side/left_all)
        )
        (
            true
            (ai_migrate int_cart_hunters_side/left int_cart_hunters_side/left_far)
        )
    )

    (sleep cart_update_cycle_rate)
)

;; Send Hunters to the side...
(script static void m_int_cart_hunters_side
    (print_debug "m_int_cart_hunters_side")
    (ai_migrate int_cart_hunters/hunter_guard int_cart_hunters_side/left_near)
    (ai_migrate int_cart_hunters/hunter_chase int_cart_hunters_side/right_near)
)

(script static void m_int_cart_hunters_init
    (print_debug "m_int_cart_hunters_init")
    
    ;; Replace the locked lower door with an unlocked door
    (object_destroy int_shaft_c_cart_door_lower_lk)
    (object_create int_shaft_c_cart_door_lower)
    (device_set_position int_shaft_c_cart_door_lower 1)
    (object_create int_shaft_c_hunter_lift)
    
    (skip_second)
    
    (if (>= normal (game_difficulty_get_real))
        (ai_place int_cart_hunters/hunter_guard_init_normal)
        (ai_place int_cart_hunters/hunter_guard_init_hard)
    )
    
    (ai_place int_cart_hunters/hunter_chase_init)
    (ai_place int_cart_hunters/servants_init)
    (ai_magically_see_players int_cart_hunters)

    (sleep 3)
    
    (ai_erase int_cart_hunters/hack)
    
    (set m_int_cart_hunters_start true)
)

(script static void m_int_cart_hunters_end
    (print_debug "m_int_cart_hunters_end")
    (sleep -1 m_int_cart_hunters_updater)
    
    (ai_migrate int_cart_hunters int_cart_hunters_side)
    (ai_migrate int_cart_hunters_side int_cart_hunters_side/retreat)
    (ai_defend int_cart_hunters_side)
)

;; ---
;; MAIN SCRIPTS
;; ---

(script dormant m_int_cart_main
    (print_debug "m_int_cart_main: starting")
    
    ;; Await player approach
    (sleep_until (volume_test_players_any int_cart_door_outer))
    (print_debug "m_int_cart_main: player approaching")

    ;; Turn on approach music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_14_cart_door")
    
    ;; Await player midpoint
    (sleep_until (volume_test_players_any int_hallways_lobby_exit))
    (print_debug "m_int_cart_main: player at midpoint")

    ;; Place dudes
    (m_int_cart_brute_init)
    (skip_frame)
    (m_int_cart_evolved_init)
    (skip_frame)
    (m_int_cart_classic_init)
    (skip_frame)
    (m_int_cart_sides_init)
    (skip_frame)
    
    ;; Hooray
    (game_save_no_timeout)

    ;; >:)
    (ai_place int_cart_hunters/hack)
    (ai_place int_cart_sword_imposs)

    ;; Await a player at threshold
    (sleep_until 
        (or
            (volume_test_players_any int_cart_entrance)
            (< 0.5 (device_get_position int_shaft_c_cart_door_upper))
        )
    )
    (print_debug "m_int_cart_main: player at cartographer")
    
    ;; Players probably aren't going back by now
    (garbage_collect_now)

    ;; Hooray
    (game_save_no_timeout)
    
    ;; Oh no, it's a sword guy! (He's only there on legendary)
    (ai_magically_see_players int_cart_sword_imposs)

    ;; This is a loud-ass door, the first two squads hear you come in
    (ai_magically_see_players int_cart_evolved)
    (ai_magically_see_players int_cart_classic)
    
    ;; Cortana: "this is it"
    (ai_conversation int_cart_entered)

    ;; Wait for a player to enter room, if one hasn't already
    (sleep_until (volume_test_players_any int_cart_entrance))
    (sleep 60)

    ;; They still see you
    (ai_magically_see_players int_cart_evolved)
    (ai_magically_see_players int_cart_classic)
    
    ;; Sword guy migrates in if players ignored him
    (ai_migrate int_cart_sword_imposs int_cart_hunters/hunter_chase_entrance)

    ;; Wait for first generator (with timeout)
    (print_debug "m_int_cart_main: awaiting first generator")

    ;; Helpful hint
    (print_debug "m_int_cart_main: deploying helpful hints")
    
    ;; Wait for 72 ticks to align navpoints with Cortana saying "there"
    (ai_conversation int_cart_gen_hint)
    (sleep 72)

    (activate_team_nav_point_flag "go_here" player int_cart_gen_brute_nav 0)
    (activate_team_nav_point_flag "go_here" player int_cart_gen_evolved_nav 0)
    (activate_team_nav_point_flag "go_here" player int_cart_gen_classic_nav 0)

    ;; Objective
    (objective_set dia_gen0 obj_gen0)
    (sleep 60)
    
    ;; Battle music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15_cart_arena")
    
    ;; This definitely needs to turn off
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_13_int")
    
    ;; Let's get some checkpoints in here
    (set m_int_cart_checkpoint_start true)
    
    ;; Hunters are already here on legendary
    (if (game_is_impossible)
        (m_int_cart_hunters_init)
    )

    (sleep_until (= 1 m_int_cart_gen_count))
    (print_debug "m_int_cart_main: first generator active")

    ;; Hooray
    (game_save_no_timeout)

    ;; End approach music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_14_cart_door")

    ;; Pat player on head
    (ai_conversation int_cart_gen_first)
    
    ;; Objective
    (objective_set dia_gen1 obj_gen1)

    ;; Ah fuck, these guys again
    (if (not (game_is_impossible))
        (m_int_cart_hunters_init)
    )

    ;; Wait for second generator
    (print_debug "m_int_cart_main: awaiting second generator")
    (sleep_until (= 2 m_int_cart_gen_count))
    (print_debug "m_int_cart_main: second generator active")

    ;; Hooray
    (game_save_no_timeout)

    ;; Pat player on head
    (ai_conversation int_cart_gen_second)
    
    ;; Objective
    (objective_set dia_gen2 obj_gen2)

    ;; Epic tense final music
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15_cart_arena")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15a_cart_arena_end")
    
    ;; Hunters know what to do
    (m_int_cart_hunters_side)
    
    ;; Wait for final generator
    (print_debug "m_int_cart_main: awaiting final generator")
    (sleep_until (= 3 m_int_cart_gen_count))
    (print_debug "m_int_cart_main: final generator active")

    ;; Hooray
    (game_save_no_timeout)

    ;; It's all over. There was nothing you could do.
    (m_int_cart_brute_end)
    (m_int_cart_evolved_end)
    (m_int_cart_classic_end)
    
    ;; Objective
    (objective_set dia_gen3 obj_gen3)

    ;; Switch the thing! (Sleep 114 to time with Cortana saying "that")
    (ai_conversation int_cart_switchit)
    (sleep 114)
    (activate_team_nav_point_flag "go_here" player int_cart_cutscene_end_0 0.3)

    ;; No more battle music, just tension music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15_cart_arena")

    ;; Wait for a player to get back to the top
    (print_debug "m_int_cart_main: awaiting player on upper floor")
    (sleep_until (volume_test_players_any int_cart_upper) 1)
    
    ;; Hunters know what to do, they run away
    (m_int_cart_hunters_end)
    
    ;; Sides, you guys fucked up
    (m_int_cart_sides_end)
    
    ;; Wait for map room activation
    (print_debug "m_int_cart_main: awaiting map room activation")
    (sleep_until (!= 0 (device_get_position int_shaft_c_cart_switch)) 1)

    ;; No more helpful hint
    (deactivate_team_nav_point_flag player int_cart_cutscene_end_0)

    ;; No more tension music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15a_cart_arena_end")

    ;; Here you go
    (m_int_cart_cutscene)

    ;; Hooray
    (game_save_no_timeout)
    
    ;; New objective
    (set mission_state mission_cartographer_activated)
    (print_debug "m_int_cart_main: map room activated")
)

;; ---
;; SPECIAL DIFFICULTY
;; ---

(global boolean special_drop_grunts false)
(global short special_grunt_drop_timer 45)
(global real special_intensity_scale 0)

;; CO-OP: If more players are added, maybe add more cheifs? Or maybe that's a bad idea...
(global unit master_cheif_0 none)
(global unit master_cheif_1 none)

(script static real m_int_cart_get_cheif_strength
    (cond
        (
            (and
                (!= none master_cheif_0)
                (!= none master_cheif_1)
            )
            (min (unit_get_shield master_cheif_0) (unit_get_shield master_cheif_1))
        )
        (
            (!= none master_cheif_0)
            (unit_get_shield master_cheif_0)
        )
        (
            (!= none master_cheif_1)
            (unit_get_shield master_cheif_1)
        )
        (
            true
            0
        )
    )
)

(global boolean m_int_cart_fuckery_start false)
(script continuous m_int_cart_special_fuckery
    (sleep_until m_int_cart_fuckery_start 1)

    ;; Random fuckery
    (if (random_chance_50)
        (begin_random
            (hud_show_shield 1)
            (hud_show_health 1)
            (hud_show_motion_sensor 1)
            (hud_show_shield 0)
            (hud_show_health 0)
            (hud_show_motion_sensor 0)
            (sleep 105)
        )
        (sleep (* 150 (m_int_cart_get_cheif_strength)))
    )

    (sleep 30)
)

(global boolean m_int_cart_special_start false)
(script continuous m_int_cart_special_updater
    (sleep_until m_int_cart_special_start 1)

    ;; He always knows where you are.
    (ai_magically_see_players int_cart_cyborg)
    
    ;; Count down timer if we're allowed to drop Grunts
    (if special_drop_grunts
        (set special_grunt_drop_timer (- special_grunt_drop_timer 1))
    )
    
    ;; Boss is still alive?
    (if (> (ai_living_count int_cart_cyborg) 0)
        (begin
            ;; Scale the music and fight light as his shields drop
            (set special_intensity_scale (max special_intensity_scale (- 1.01 (m_int_cart_get_cheif_strength))))
            (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode" special_intensity_scale)
            (device_set_power secret_cart_light (- special_intensity_scale 0.5))
            (cinematic_screen_effect_set_convolution 1 2 0 (* special_intensity_scale 7) 0)
            
            ;; Rescue him if he falls down the pit, to ensure the mission is not rendered unwinnable
            (if (volume_test_object int_cart_cyborg_rescue master_cheif_0)
                (object_teleport master_cheif_0 int_cart_cyborg_rescue_flag)
            )
            (if (volume_test_object int_cart_cyborg_rescue master_cheif_1)
                (object_teleport master_cheif_1 int_cart_cyborg_rescue_flag)
            )
        )
    )
    
    ;; Drop Grunts and reset timer if it's time
    (if (< special_grunt_drop_timer 1)
        (begin
            (ai_place int_cart_special_grunts)
            (set special_grunt_drop_timer
                (+
                    (random_range 0 60)
                    45
                )
            )
        )
    )
)

(script dormant m_int_cart_special_captain
    (sleep (random_range 170 210))

    ;; Good to see you, Master Cheif
    (if (< 0 (unit_get_health captain_nightmare))
        (sound_impulse_start "sound\dialog\x20\keyes01" captain_nightmare 1.0)
    )
)

(script dormant m_int_cart_special
    ;; Await player approach
    (sleep_until (volume_test_players_any int_cart_door_outer))
    (print_debug "m_int_cart_special: player approaching")

    ;; Turn on approach music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_14_cart_door")
    
    ;; Await player midpoint
    (sleep_until (volume_test_players_any int_hallways_lobby_exit))
    (print_debug "m_int_cart_special: player at midpoint")
    
    ;; Fuck with players a little more
    (player_enable_input false)
    (sleep 75)
    
    (show_hud false)
    (skip_second)
    
    ;; Inline an even angrier phantom_of_the_map
    (fade_out 1 0 0 0)
    (sound_impulse_start "cmt\sounds\sfx\scenarios\b30_revamp\ambience\sounds\detail_howls_low" none 1)
    (sleep 60)
    
    ;; Make sure nobody gets locked out
    (volume_teleport_players_not_inside int_hallways_lobby_exit int_cart_entrance_teleport)
    
    ;; Return control
    (player_enable_input true)
    (device_set_position_immediate int_shaft_b_lobby_door 0)
    
    (cinematic_screen_effect_start true)
    (cinematic_screen_effect_set_convolution 1 2 15 0 3)
    (fade_in 1 0 0 90)
    (sleep 90)
    
    (cinematic_screen_effect_stop)
    (show_hud true)
    
    ;; Hooray
    (game_save_no_timeout)

    ;; Await a player at threshold
    (sleep_until (volume_test_players_any int_cart_entrance))
    
    ;; Cortana: "this is it"
    (ai_conversation int_cart_entered)
    (object_create_containing secret_cart)
    
    ;; Special updater for the special difficulty
    (set m_int_cart_special_start true)
    (wake m_int_cart_classic_objs)
    (wake m_int_cart_evolved_objs)
    (wake m_int_cart_brute_objs)
    
    ;; Wait for a bit
    (print_debug "m_int_cart_special: awaiting first generator")
    (skip_second)
    
    ;; Wait for ~80 ticks to align navpoints with cortana saying "there"
    (print_debug "m_int_cart_special: deploying helpful? hints")
    (ai_conversation int_cart_gen_hint_special)
    
    ;; Objective
    (objective_set dia_gen0_ez obj_gen0_ez)
    
    (sleep_until (= 1 m_int_cart_gen_count))
    (print_debug "m_int_cart_special: first generator active")

    ;; Something's not right
    (ai_conversation int_cart_gen_first_special)
    
    ;; Objective
    (objective_set dia_gen1_ez obj_gen1_ez)

    ;; Wait for second generator
    (print_debug "m_int_cart_special: awaiting second generator")
    (sleep_until (= 2 m_int_cart_gen_count))
    (print_debug "m_int_cart_special: second generator active")

    ;; I'm scared and confused
    (ai_conversation int_cart_gen_second_special)
    
    ;; Objective
    (objective_set dia_gen2_ez obj_gen2_ez)
    
    ;; Wait for final generator
    (print_debug "m_int_cart_special: awaiting final generator")
    (sleep_until (= 3 m_int_cart_gen_count))
    (print_debug "m_int_cart_special: final generator active")

    ;; The seal is broken.
    (device_set_position grimdome 1)

    ;; Hooray
    ;; Special instant save. If players somehow are able to mess this up then they deserve the endless death loop
    (game_save_totally_unsafe)

    ;; End the tension music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_14_cart_door")
    
    ;; Battle music
    (sound_looping_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode" none 0)
    
    ;; It's not over though...
    (ai_place int_cart_cyborg/master_cheif)
    (set master_cheif_0 (unit (list_get (ai_actors int_cart_cyborg/master_cheif) 0)))
    (cinematic_screen_effect_start true)
    
    ;; Just in case
    (ai_allegiance_remove human sentinel)
    (ai_magically_see_players int_cart_cyborg/master_cheif)
    
    ;; You found it! Now you have to take it
    (unit_doesnt_drop_items master_cheif_0)

    ;; Wait until 20% shields gone
    (sleep_until (< (m_int_cart_get_cheif_strength) 0.8))

    ;; CO-OP: Place additional cheif(s)
    (if (game_is_cooperative)
        (begin
            (ai_place int_cart_cyborg/master_cheif_echo)
            (set master_cheif_1 (unit (list_get (ai_actors int_cart_cyborg/master_cheif_echo) 0)))
            (unit_doesnt_drop_items master_cheif_1)
        )
    )

    ;; Wait until 40% shields gone
    (sleep_until (< (m_int_cart_get_cheif_strength) 0.6))
    (set m_int_cart_fuckery_start true)
    
    ;; Wait until 60% shields gone
    (sleep_until (< (m_int_cart_get_cheif_strength) 0.4))
    
    ;; Special weather for the special difficulty
    (set special_drop_grunts true)
    
    ;; Wait until 80% shields gone
    (sleep_until (< (m_int_cart_get_cheif_strength) 0.2))
    
    ;; Special detail sounds
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode")
    
    ;; Wait until he's dead
    (sleep_until (= (ai_living_count int_cart_cyborg) 0) 1)

    ;; This is what you wanted
    (sleep 20)
    (fade_out 0 0 0 0)
    (game_save_cancel)
    
    ;; The Grunts' job is done, don't let them ruin the mood
    (set special_drop_grunts false)
    (ai_erase int_cart_special_grunts)
    (garbage_collect_now)
    (sleep 35)
    
    ;; There's no going back now 
    (teleport_players int_cart_nightmare_0 int_cart_nightmare_1)
    (object_create nightmare_zone)
    (object_create captain_nightmare)
    (sleep 35)

    ;; There's only one thing left to do
    (fade_in 0 0 0 0)
    (wake m_int_cart_special_captain)

    ;; Wait until it's done
    (sleep_until (>= 0 (unit_get_health captain_nightmare)) 1)
    (object_create the_silent_battle_rifle)

    ;; CO-OP: If more players are added, test for all of them here
    (sleep_until
        (or
            (unit_has_weapon (player0) "cmt\weapons\evolved\_egg\battle_rifle_silent\battle_rifle_silent")
            (unit_has_weapon (player1) "cmt\weapons\evolved\_egg\battle_rifle_silent\battle_rifle_silent")
        )
    )
    
    ;; It's over.
    (teleport_players int_cart_acquired_0 int_cart_acquired_1)
    (object_destroy nightmare_zone)
    (object_destroy captain_nightmare)

    ;; Music off
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_15b_cart_arena_easymode")
    
    ;; Watchers leave the scene, their task fulfilled
    (object_destroy_containing secret_cart)
    
    ;; Reset fuckery
    (sleep -1 m_int_cart_special_fuckery)
    (hud_show_shield 1)
    (hud_show_health 1)
    (hud_show_motion_sensor 1)
    (cinematic_screen_effect_stop)

    ;; Updater may end
    (sleep -1 m_int_cart_special_updater)
    
    ;; Thanks Cortana
    (sleep 120)
    (ai_conversation int_exit_special_leave)
    
    ;; Hooray
    (sleep 60)
    (game_save_no_timeout)
    
    ;; New objective
    (set mission_state mission_cartographer_activated)
    (print_debug "m_int_cart_special: picked up the silent battle rifle")
)

;; ---
;; Mission hooks

(script static void m_int_cart_startup
    ;; Special script for the special difficulty
    (if (game_is_easy)
        (wake m_int_cart_special)
        (wake m_int_cart_main)
    )
)

(script static void m_int_cart_cleanup
    (sleep -1 m_int_cart_special)
    (sleep -1 m_int_cart_main)
    (sleep -1 m_int_cart_checkpoint_bastard)
)
