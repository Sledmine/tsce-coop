;; 08_b30_revamp_mission_ext.hsc
;; Top-level mission for the island exterior. This continues until one of these things happens:
;; - Security is locked, moving players to the "override" mission
;; - The cartographer shaft is entered, moving players to the "int" mission
;; ---

;; ---
;; BEACH_1
;; ---

;; ---
;; Encounter state

;; DO NOT CHANGE THESE!
(global short b1_init 0)
(global short b1_triggered 1)
(global short b1_approached 2)
(global short b1_entered 3)
(global short b1_cship_flying 4)
(global short b1_cship_harassing 5)
(global short b1_leaving 6)
(global short b1_finishing 7)
(global short b1_finished 8)
(global short m_ext_beach_1_state b1_init)

(global short b1e_init 0)
(global short b1e_triggered 1)
(global short b1e_entered 2)
(global short b1e_finishing 3)
(global short b1e_finished 4)
(global short m_ext_beach_1_exit_state b1e_init)

;; ---
;; BSP auto-migration

(script continuous m_ext_beach_1_automig
    (sleep_until (= bsp_index_ext_lz (structure_bsp_index)) 1)
    
    ;; Beach_1
    (ai_migrate ext_beach_1_exit_cc/left ext_beach_1_exit/left_a)
    (ai_migrate ext_beach_1_exit_cc/right ext_beach_1_exit/right_c)
    (ai_migrate ext_beach_1_exit_cc/camp ext_beach_1_exit/camp_ef)

    ;; Ghosts
    (ai_migrate ext_beach_1_ghost_1_cc ext_beach_1_ghost_1/f)
    (ai_migrate ext_beach_1_ghost_2_cc ext_beach_1_ghost_1/f)
    (ai_vehicle_encounter ext_beach_1_ghost_1 ext_beach_1_ghost_1/f)
    (ai_vehicle_encounter ext_beach_1_ghost_2 ext_beach_1_ghost_2/f)
    
    (sleep_until (= bsp_index_ext_capp (structure_bsp_index)) 1)
    
    ;; Beach_1
    (ai_migrate ext_beach_1_exit/left ext_beach_1_exit_cc/left_a)
    (ai_migrate ext_beach_1_exit/right ext_beach_1_exit_cc/right_c)
    (ai_migrate ext_beach_1_exit/camp ext_beach_1_exit_cc/camp_ef)
    
    ;; Ghosts
    (ai_migrate ext_beach_1_ghost_1 ext_beach_1_ghost_1_cc/f)
    (ai_migrate ext_beach_1_ghost_2 ext_beach_1_ghost_1_cc/f)
    (ai_vehicle_encounter ext_beach_1_ghost_1 ext_beach_1_ghost_1_cc/f)
    (ai_vehicle_encounter ext_beach_1_ghost_2 ext_beach_1_ghost_2_cc/f)
)

;; ---
;; Phantom harassment

(global real m_ext_beach_1_cship_time 0)
(global boolean m_ext_beach_1_imposs_clear false)

(global boolean m_ext_beach_1_cship_start false)
(script continuous m_ext_beach_1_cship_harass
    (sleep_until m_ext_beach_1_cship_start 1)

    (if (and
            (<  m_ext_beach_1_cship_time 2700)  ;; 30 * 90
            (!= none (vehicle_gunner ext_beach_1_cship))
        )
        (begin
            (print_debug "m_ext_beach_1_cship_harass: loop")
            (if X_DBG_enabled
                (begin
                    (inspect m_ext_beach_1_cship_time)
                    (inspect m_ext_beach_1_imposs_clear)
                )
            )

            ;; Play the idle animation
            (phantom_hover_and_bank ext_beach_1_cship)

            ;; Track how much time we've been hovering
            (set m_ext_beach_1_cship_time (+ phantom_bank_time m_ext_beach_1_cship_time))
        )
        (begin
            (print_debug "m_ext_beach_1_cship_harass: leaving")
            (vehicle_hover ext_beach_1_cship false)
            
            ;; If we're on legendary and this is the first time we're flying away, 
            ;; do the second harassment routine
            (if (and
                    (game_is_impossible)
                    (not m_ext_beach_1_imposs_clear)
                )
                (begin
                    (print_debug "m_ext_beach_1_cship_harass: reposition for legendary")
                    
                    ;; Reset harassment counter + move to second position
                    (set m_ext_beach_1_cship_time 0)
                    (recording_play_and_hover ext_beach_1_cship ext_beach_1_cship_imposs)
                    (sleep (recording_time ext_beach_1_cship))
                )
            )
            
            ;; If we're either not on legendary or on legendary + flying away for a second time,
            ;; actually go away
            (if (not (game_is_impossible))
                (begin
                    (recording_play_and_delete ext_beach_1_cship ext_beach_1_cship_harass_out)
                    (sleep_forever)
                )
            )
            (if m_ext_beach_1_imposs_clear
                (begin
                    (recording_play_and_delete ext_beach_1_cship ext_beach_1_cship_imposs_out)
                    (sleep_forever)
                )
            )
            (set m_ext_beach_1_imposs_clear true)
        )
    )
)

;; ---
;; Main area

(global boolean m_ext_beach_1_start false)
(script continuous m_ext_beach_1_updater
    (sleep_until m_ext_beach_1_start 1)

    ;; Move Covenant to the appropriate zone based on where the players are
    (cond
        (
            (volume_test_players_all ext_beach_1_1)
            (ai_migrate ext_beach_1/rock ext_beach_1/rock_jk)
            (ai_migrate ext_beach_1/rock_crushed ext_beach_1/rock_j)
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_b)
        )
        ( 
            (volume_test_players_all ext_beach_1_2)
            (ai_migrate ext_beach_1/rock ext_beach_1/rock_hi)
            (ai_migrate ext_beach_1/rock_crushed ext_beach_1/rock_h)
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_c)
        )
        (
            (volume_test_players_all ext_beach_1_3)
            (ai_migrate ext_beach_1/rock ext_beach_1/rock_mo)
            (ai_migrate ext_beach_1/rock_crushed ext_beach_1/rock_l)
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_b)
        )
        (
            (volume_test_players_all ext_beach_1_4)
            (ai_migrate ext_beach_1/rock ext_beach_1/rock_mp)
            (ai_migrate ext_beach_1/rock_crushed ext_beach_1/rock_l)
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_c)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            (ai_migrate ext_beach_1/rock ext_beach_1/rock_all)
            (ai_migrate ext_beach_1/rock_crushed ext_beach_1/rock_crushed_all)
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_all)
        )
    )
)

(script dormant b30r_m_ext_beach_1
    ;; Wait for a player to approach beach 1
    (sleep_until
        (or
            (volume_test_players_any ext_beach_1_approach)
            (volume_test_players_any ext_canyon_approach)
            (volume_test_players_any ext_cave_falls)
        )
    )
    (set m_ext_beach_1_state b1_triggered)

    ;; Our hog adventure is either ending, or beginning
    (if (<= b1e_triggered m_ext_beach_1_exit_state)
        (m_ext_hog_adventure_end_music)
        (m_ext_hog_adventure_start_music)
    )
    
    ;; Place the AI dudes
    (ai_place ext_beach_1)
    
    ;; Special units for the special difficulty
    (if (game_is_easy)
        (ai_migrate ext_beach_1/mini_grunts_easy ext_beach_1/mini_grunts)
        (ai_erase ext_beach_1/mini_grunts_easy)
    )

    ;; If a player is coming the normal way, the mini squad goes to intercept
    (if (volume_test_players_any ext_beach_1_approach)
        (begin
            (ai_migrate ext_beach_1/mini ext_beach_1/mini_advance)
            
            ;; Special cowardice for the special difficulty
            (if (game_is_easy)
                (ai_set_current_state ext_beach_1/mini flee)
            )
        )
    )

    ;; Create the dropship
    (create_ext_beach_1_cship)
    (unit_set_desired_flashlight_state ext_beach_1_cship_grav true)
    (unit_open ext_beach_1_cship_grav)

    ;; Create + set up the Ghost(s)
    (object_create_anew ext_beach_1_ghost_1)
    (ai_vehicle_encounter ext_beach_1_ghost_1 ext_beach_1_ghost_1/b)
    (ai_place ext_beach_1_ghost_1/pilot)
    (unit_enter_vehicle ext_beach_1_ghost_1 ext_beach_1_cship "small_cargo01")
    (vehicle_load_magic ext_beach_1_ghost_1 "driver" (ai_actors ext_beach_1_ghost_1/pilot))
    (object_create_anew ext_beach_1_ghost_2)
    (ai_vehicle_encounter ext_beach_1_ghost_2 ext_beach_1_ghost_2/c)
    (ai_place ext_beach_1_ghost_2/pilot)
    (unit_enter_vehicle ext_beach_1_ghost_2 ext_beach_1_cship "small_cargo02")
    (vehicle_load_magic ext_beach_1_ghost_2 "driver" (ai_actors ext_beach_1_ghost_2/pilot))

    ;; Get the Phantom ready to drop the Ghosts
    (object_teleport ext_beach_1_cship ext_beach_1_cship_flag)
    (vehicle_hover ext_beach_1_cship true)

    ;; Wait for a player to enter the outer combat zone
    (sleep_until
        (or
            (volume_test_players_any ext_beach_1_mini)
            (volume_test_players_any ext_beach_1_exit)
            (volume_test_players_any ext_beach_1_main)
        )
    )
    (set m_ext_beach_1_state b1_approached)

    ;; Drop the Ghosts
    (unit_exit_vehicle ext_beach_1_ghost_1)
    (unit_exit_vehicle ext_beach_1_ghost_2)
    (unit_set_desired_flashlight_state ext_beach_1_cship_grav false)
    (unit_close ext_beach_1_cship_grav)

    ;; Wait for a player to arrive at the main area
    (sleep_until
        (or
            (volume_test_players_any ext_beach_1_exit)
            (volume_test_players_any ext_beach_1_main)
        )
    )
    (set m_ext_beach_1_state b1_entered)

    ;; AI conversation - "Look, a Ghost!"
    (ai_conversation ext_beach_1_ghost)

    ;; Wake the Covenant management script
    (set m_ext_beach_1_start true)
    (ai_migrate ext_beach_1/camp ext_beach_1/camp_ep)
    (ai_migrate ext_beach_1/far ext_beach_1/far_g)

    ;; Have Ghosts pursue the player
    (ai_follow_target_players ext_beach_1_ghost_1)
    (ai_follow_target_players ext_beach_1_ghost_2)
    (ai_follow_distance ext_beach_1_ghost_1 5)
    (ai_follow_distance ext_beach_1_ghost_2 5)
    (ai_automatic_migration_target ext_beach_1_ghost_1 true)
    (ai_automatic_migration_target ext_beach_1_ghost_2 true)
    (ai_follow_target_players ext_beach_1_ghost_1_cc)
    (ai_follow_target_players ext_beach_1_ghost_2_cc)
    (ai_follow_distance ext_beach_1_ghost_1_cc 5)
    (ai_follow_distance ext_beach_1_ghost_2_cc 5)
    (ai_automatic_migration_target ext_beach_1_ghost_1_cc true)
    (ai_automatic_migration_target ext_beach_1_ghost_2_cc true)

    ;; Save the game
    (game_save_no_timeout)

    ;; ait a little while
    (sleep 120)
    (set m_ext_beach_1_state b1_cship_flying)

    ;; Have the cship fly away or go to harassment position on heroic+
    (vehicle_hover ext_beach_1_cship false)
    (if (< normal (game_difficulty_get_real))
        (begin
            (recording_play_and_hover ext_beach_1_cship ext_beach_1_cship_harass)
            (sleep (recording_time ext_beach_1_cship))
            (set m_ext_beach_1_cship_start true)
            
            ;; Wait for the cship to be in harassment position
            (set m_ext_beach_1_state b1_cship_harassing)
        )
        (recording_play_and_delete ext_beach_1_cship ext_beach_1_cship_out)
    )

    ;; Wait for a player to push through and start doing serious damage, or for all players to be cowards
    (sleep_until
        (or
            (and
                (volume_test_players_any ext_beach_1_main)
                (< (ai_living_count ext_beach_1) 7)
            )
            (not (volume_test_players_any ext_beach_1_main))
        )
    )
    (set m_ext_beach_1_state b1_leaving)

    ;; Order the cship to leave
    (set m_ext_beach_1_cship_time 2700)  ;; 30 * 90

    ;; Save the game
    (game_save_no_timeout)

    ;; Wait for a player to mop up or move on
    (sleep_until
        (or
            (not (volume_test_players_any ext_beach_1_main))
            (< (ai_living_count ext_beach_1) 4)
        )
    )
    (set m_ext_beach_1_state b1_finishing)

    ;; Save the game
    (game_save_no_timeout)

    ;; Don't bother updating the Covenant squads anymore
    (sleep -1 m_ext_beach_1_updater)

    ;; Token few minutes to make cleanup non-obvious
    (sleep 3000)
    (set m_ext_beach_1_state b1_finished)
    (if (= b1e_finished m_ext_beach_1_exit_state)
        (m_ext_beach_1_cleanup)
    )
)

;; ---
;; Exit area

(global boolean m_ext_beach_1_exit_start false)
(script continuous m_ext_beach_1_exit_updater
    (sleep_until m_ext_beach_1_exit_start 1)

    ;; Move Covenant to the appropriate zone based on where the players are
    (cond
        (   
            (volume_test_players_all ext_beach_1_exit_left)
            (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_a)
            (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_c)
        )
        (
            (volume_test_players_all ext_beach_1_exit_right)
            (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_b)
            (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_d)
        )
        (
            (volume_test_players_all ext_beach_1_exit_center)
            (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_b)
            (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_c)
        )
        (
            (or
                (volume_test_players_all ext_canyon_intro)
                (volume_test_players_all ext_canyon_approach)
            )
            (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_f)
            (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_h)
            (ai_migrate ext_beach_1_exit/camp ext_beach_1_exit/camp_ef)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_ab)
            (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_cd)
        )
    )
)

(script dormant b30r_m_ext_beach_1_exit
    ;; Wait for a player to be in the right place
    (sleep_until
        (or
            (volume_test_players_any ext_beach_1_4)
            (volume_test_players_any ext_beach_1_exit)
            (volume_test_players_any ext_canyon_intro)
        )
    )
    (set m_ext_beach_1_exit_state b1e_triggered)

    ;; Place the AI dudes
    (ai_place ext_beach_1_exit)
    (ai_migrate ext_beach_1_exit/left ext_beach_1_exit/left_b)
    (ai_migrate ext_beach_1_exit/right ext_beach_1_exit/right_c)

    ;; Place the turrets on legendary only
    (if (= impossible (game_difficulty_get_real))
        (object_create ext_beach_1_exit_turret_1)
    )
    (ai_vehicle_encounter ext_beach_1_exit_turret_1 ext_beach_1_exit)
    (ai_vehicle_encounter ext_beach_1_exit_turret_2 ext_beach_1_exit)
    (ai_go_to_vehicle ext_beach_1_exit/camp_grunts ext_beach_1_exit_turret_1 "gunner")
    (ai_go_to_vehicle ext_beach_1_exit/shade_pilot_imposs ext_beach_1_exit_turret_2 "gunner")

    ;; Wake the AI management script
    (set m_ext_beach_1_exit_start true)

    ;; Wait for a player to kick moderate ass
    (sleep_until
        (or
            (volume_test_players_any ext_canyon_approach)
            (volume_test_players_any ext_beach_1_mini)
            (< (ai_living_count ext_beach_1_exit) 10)
        )
    )
    (set m_ext_beach_1_exit_state b1e_entered)

    ;; Our hog adventure is either ending, or beginning
    (if (>= b1_triggered m_ext_beach_1_state)
        (m_ext_hog_adventure_start_music)
        (m_ext_hog_adventure_end_music)
    )

    ;; Make a break for the turret, Jimmy!
    (ai_go_to_vehicle ext_beach_1_exit ext_beach_1_exit_turret_1 "gunner")

    ;; Save the game
    (game_save_no_timeout)

    ;; Wait for a player to totally kill them
    (sleep_until
        (or
            (volume_test_players_any ext_canyon_main_1)
            (volume_test_players_any ext_canyon_main_2)
            (volume_test_players_any ext_cart_approach)
            (volume_test_players_any ext_beach_1_approach)
            (= 1 (ai_living_count ext_beach_1_exit))
        )
    )
    (set m_ext_beach_1_exit_state b1e_finishing)

    ;; Order the cship to leave (again)
    (set m_ext_beach_1_cship_time 2700)  ;; 30 * 90
    
    ;; Don't bother updating the Covenant squads anymore
    (sleep -1 m_ext_beach_1_exit_updater)

    ;; Save the game
    (game_save_no_timeout)

    ;; Token few minutes to make cleanup non-obvious
    (sleep 3000)
    (set m_ext_beach_1_exit_state b1e_finished)
    (if (= b1_finished m_ext_beach_1_state)
        (m_ext_beach_1_cleanup)
    )
)

;; ---
;; Mission hooks

(script static void m_ext_beach_1_startup
    ;; Wake progression scripts
    (wake b30r_m_ext_beach_1)
    (wake b30r_m_ext_beach_1_exit)
)

(script static void m_ext_beach_1_cleanup
    ;; Kill progression scripts
    (sleep -1 b30r_m_ext_beach_1)
    (sleep -1 b30r_m_ext_beach_1_exit)

    ;; Goodbye, fuckers
    (ai_erase ext_beach_1)
    (ai_erase ext_beach_1_exit)
    (ai_erase ext_beach_1_exit_cc)
    (object_destroy ext_beach_1_cship)
    (sleep -1 m_ext_beach_1_cship_harass)
    (sleep -1 m_ext_beach_1_automig)
)

;; ---
;; CANYON
;; ---

(global boolean m_ext_canyon_nook_awake false)

(script static void m_ext_canyon_wake_nook
    (if (not m_ext_canyon_nook_awake)
        (begin
            (ai_set_current_state ext_canyon/nook guard)
            (ai_magically_see_players ext_canyon/nook)
            (set m_ext_canyon_nook_awake true)
        )
    )
)

(global boolean m_ext_canyon_start false)
(script continuous m_ext_canyon_update
    (sleep_until m_ext_canyon_start 1)

    ;; Move dudes around and about
    (cond
        (
            (volume_test_players_any ext_cart_main)

            ;; Wake the nook if it was not previously awake
            (if (not m_ext_canyon_nook_awake)
                (begin
                    (ai_set_current_state ext_canyon/nook guard)
                    (ai_magically_see_players ext_canyon/nook)
                    (set m_ext_canyon_nook_awake true)
                )
            )
            ;; Move the tree to meet this player
            (ai_migrate ext_canyon/shaft ext_canyon/shaft_pq)
        )
        (
            (volume_test_players_any ext_cart_visible)

            ;; Wake the nook if it was not previously awake
            (m_ext_canyon_wake_nook)
            ;; Move the tree to meet this player
            (ai_migrate ext_canyon/tree_command ext_canyon/tree_command_kj)
            ;; Move the shaft to meet this player
            (ai_migrate ext_canyon/shaft ext_canyon/shaft_no)
        )
        (
            (volume_test_players_any ext_canyon_main_3)

            ;; Wake the nook if it was not previously awake
            (m_ext_canyon_wake_nook)
            ;; Move the tree to meet this player
            (ai_migrate ext_canyon/tree_command ext_canyon/tree_command_kj)
        )
        (
            (volume_test_players_any ext_canyon_main_2)

            ;; Move the nook if it is awake
            (if m_ext_canyon_nook_awake
                (ai_migrate ext_canyon/nook ext_canyon/nook_h)
            )
            ;; Move the watch to meet this player
            (ai_set_current_state ext_canyon/watch guard)
            (ai_migrate ext_canyon/watch ext_canyon/watch_ih)
            ;; Move the tree to meet this player
            (ai_set_current_state ext_canyon/tree guard)
            (ai_set_current_state ext_canyon/tree_command guard)
            (ai_migrate ext_canyon/tree_command ext_canyon/tree_command_lm)
        )
        (
           (volume_test_players_any ext_canyon_main_1)

            ;; Move the nook if it is awake
            (if m_ext_canyon_nook_awake
                (ai_migrate ext_canyon/nook ext_canyon/nook_ed)
            )
            ;; Move the watch to meet this player
            (ai_set_current_state ext_canyon/watch guard)
            (ai_magically_see_players ext_canyon/watch)
            (ai_migrate ext_canyon/watch ext_canyon/watch_gf)

        )
        (
            (volume_test_players_any ext_canyon_intro)
            
            ;; Wake the nook if it was not previously awake
            (m_ext_canyon_wake_nook)
            ;; Give a tick for nook to wake up
            (skip_frame)
            ;; Move the nook to meet this player
            (ai_migrate ext_canyon/nook ext_canyon/nook_bc)
        ) 
    )

    ;; Move dudes across BSP lines
    (if (= bsp_index_ext_capp (structure_bsp_index))
        (begin
            ;; Canyon
            (ai_migrate ext_canyon_lz/nook ext_canyon/nook_bc)
            (ai_migrate ext_canyon_lz/watch ext_canyon/watch_gf)
            (ai_migrate ext_canyon_lz/tree ext_canyon/tree_grunts_2)
            (ai_migrate ext_canyon_lz/tree_command ext_canyon/tree_command_kj)
            (ai_migrate ext_canyon_lz/shaft ext_canyon/shaft_pq)
            
            ;; Ghosts
            (ai_migrate ext_canyon_ghost_lz ext_canyon_ghost/squad_a)
            (ai_vehicle_encounter ext_canyon_ghost ext_canyon_ghost/squad_a)
            (ai_follow_target_players ext_canyon_ghost_lz/squad_a)
            (ai_follow_distance ext_canyon_ghost_lz 5)
        )
        (begin
            ;; Canyon
            (ai_migrate ext_canyon/nook ext_canyon_lz/nook_bc)
            (ai_migrate ext_canyon/watch ext_canyon_lz/watch_gf)
            (ai_migrate ext_canyon/tree ext_canyon_lz/tree_grunts_2)
            (ai_migrate ext_canyon/tree_command ext_canyon_lz/tree_command_kj)
            (ai_migrate ext_canyon/shaft ext_canyon_lz/shaft_pq)
            
            ;; Ghosts
            (ai_migrate ext_canyon_ghost ext_canyon_ghost_lz/squad_a)
            (ai_vehicle_encounter ext_canyon_ghost ext_canyon_ghost_lz/squad_a)
            (ai_follow_target_players ext_canyon_ghost/squad_a)
            (ai_follow_distance ext_canyon_ghost 5)
        )
    )
)

(script dormant m_ext_canyon
    ;; Wait for a player to enter canyon
    (sleep_until
        (or
            (volume_test_players_any ext_canyon_approach)
            (volume_test_players_any ext_cart_visible)
        )
    )

    ;; Place dudes
    (ai_place ext_canyon_lz)

    ;; Update script handles the rest
    (set m_ext_canyon_start true)

    ;; Set up Ghost (heroic+)
    (if (>= hard (game_difficulty_get_real))
        (begin
            (object_create ext_canyon_ghost)
            (ai_place ext_canyon_ghost_lz/pilot)
            (ai_go_to_vehicle ext_canyon_ghost_lz/pilot ext_canyon_ghost "driver")
            (ai_vehicle_encounter ext_canyon_ghost ext_canyon_ghost_lz/squad_a)
            (ai_follow_target_players ext_canyon_ghost_lz/squad_a)
            (ai_follow_distance ext_canyon_ghost_lz 5)
        )
    )

    ;; Wait for the player to kick ass - there is no escape from the fortress of the canyon encounter except that
    (sleep_until
        (and
            (= bsp_index_ext_capp (structure_bsp_index))
            (< (ai_living_count ext_canyon) 3)
            (< (ai_living_count ext_canyon_lz) 3)
        )
    )

    ;; Save game
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_ext_canyon_startup
    (wake m_ext_canyon)
)

(script static void m_ext_canyon_cleanup
    (sleep -1 m_ext_canyon_update)
    (sleep -1 m_ext_canyon)
    
    (ai_erase ext_canyon)
    (ai_erase ext_canyon_lz)
    (object_destroy ext_canyon_ghost)
)

;; ---
;; CAVE
;; ---

;; Magic checkpoints when the players are in the known-safe zone in the tunnel,
;; just before entering the cart ridge area
(script dormant ultimate_checkpoint_man
    ;; First checkpoint any time a player passes through
    (sleep_until (volume_test_players_any ext_cart_return_approaching) 1)
    (game_save_totally_unsafe)
    
    ;; Second checkpoint on return
    (sleep_until
        (and
            mission_security_unlocked
            (volume_test_players_any ext_cart_return_approaching)
        )
        1
    )
    (game_save_totally_unsafe)
)

;; ---
;; Bonus cave encounter

(script dormant m_ext_cave
    ;; Wait for a player to enter cave
    (sleep_until
        (or
            (volume_test_players_any ext_cave_lz)
            (volume_test_players_any ext_cave_falls)
        )
    )

    ;; Probably took you a while to get here
    (game_save_no_timeout)
    
    ;; Place dudes
    (ai_place ext_cave)
    
    ;; If you weren't on an adventure before, you are now
    (m_ext_hog_adventure_start_music)

    ;; Some BSP thing idk
    (sleep_until (= bsp_index_ext_cave (structure_bsp_index)))
    
    ;; Set up turret
    (ai_go_to_vehicle ext_cave ext_cave_turret_1 "ball-gunner")

    ;; Wait for the players to kick ass
    ;; There is no escape from the fortress of the cave encounter except that
    (sleep_until
        (< (ai_living_fraction ext_cave) 0.5)
    )
    
    ;; Go again!!!!!
    (ai_go_to_vehicle ext_cave ext_cave_turret_1 "ball-gunner")
    
    (game_save_no_timeout)
    (sleep_until
        (< (ai_living_fraction ext_cave) 0.25)
    )
    (game_save_no_timeout)
)

;; ---
;; beach_2

(global boolean m_ext_beach_2_cship_start false)
(script continuous m_ext_beach_2_cship
    (sleep_until m_ext_beach_2_cship_start 1)

    (recording_kill ext_beach_1_cship)
    (object_teleport ext_beach_1_cship beach_2_easy_cship_flag)
    (recording_play ext_beach_1_cship ext_cart_cship_out)
    (sleep 80)
)

(script dormant m_ext_beach_2
    ;; Wait for approach
    (sleep_until 
        (or
            (volume_test_players_any ext_cave_exit)
            (volume_test_players_any ext_cart_returning)
        )
    1)
    
    ;; Wait for proper BSP
    (sleep_until (= bsp_index_ext_lid (structure_bsp_index)) 1)
    
    ;; Those cave jumps are pretty precarious, so give the players a checkpoint
    (game_save_totally_unsafe)

    ;; Place the beach garrison
    (ai_place ext_beach_2)
    (object_create ext_beach_2_ghost_1)
    (object_create ext_beach_2_ghost_2)
    
    ;; Hold on
    (skip_frame)
    (sleep_until (= bsp_index_ext_lid (structure_bsp_index)) 1)
    (ai_magically_see_players ext_beach_2)
    
    ;; Ghost boys, do your things
    (ai_go_to_vehicle ext_beach_2/pilot_1 ext_beach_2_ghost_1 "driver")
    (ai_go_to_vehicle ext_beach_2/pilot_2 ext_beach_2_ghost_2 "driver")
    
    (ai_vehicle_enterable_distance ext_beach_2_ghost_1 10)
    (ai_vehicle_enterable_distance ext_beach_2_ghost_2 10)
    (ai_vehicle_encounter ext_beach_2_ghost_1 ext_beach_2_ghost_1/a)
    (ai_vehicle_encounter ext_beach_2_ghost_2 ext_beach_2_ghost_2/a)
    (ai_follow_target_players ext_beach_2_ghost_1)
    (ai_follow_target_players ext_beach_2_ghost_2)
    (ai_follow_distance ext_beach_2_ghost_1 3)
    (ai_follow_distance ext_beach_2_ghost_2 3)
    
    ;; Wait until a player leaves the beach
    (sleep_until (volume_test_players_any ext_beach_2_leaving) 1)
    
    ;; You did it man, good job
    (game_save_no_timeout)

    ;; Lag wants to splatter people now
    (ai_attack ext_beach_2/fodder_guys)
    
    ;; Aghhghhgh
    (ai_magically_see_players ext_beach_2/fodder_guys)
    
    ;; I knew these hog adventure scripts would pay off
    (m_ext_hog_adventure_end_music)
)

(script dormant m_ext_beach_2_returning
    ;; Wait for approach
    (sleep_until (volume_test_players_any ext_cave_exit) 1)
    (sleep_until (= bsp_index_ext_lid (structure_bsp_index)) 1)
    (skip_second)
    
    ;; Special Phantom for the special difficulty
    (if (game_is_easy)
        (begin
            (create_ext_beach_1_cship)
            (set m_ext_beach_2_cship_start true)
        )
    )
    
    ;; Always a second line + Wraith
    (ai_place return_beach_2/second_line)
    (ai_place return_beach_2/wraith_pilot)

    ;; Existing units know you're around
    (ai_set_current_state ext_beach_2 search)
    
    ;; The Wraith bullshit that makes it do something or other
    (object_create_anew return_beach_2_wraith)
    (ai_vehicle_enterable_distance return_beach_2_wraith 20 )
    (ai_vehicle_enterable_team return_beach_2_wraith covenant)
    (vehicle_load_magic return_beach_2_wraith "driver" (ai_actors return_beach_2/wraith_pilot ))
    (ai_vehicle_encounter return_beach_2_wraith r_beach_2_wrth_ext_cart-sapp/f )
    
    ;; If the players cleared the area, some replacements come in
    (if (< 3 (ai_living_count ext_beach_2))
        (sleep_forever)
    )
    
    ;; (Here they are)
    (ai_place return_beach_2/replacement_leader)
    (ai_place return_beach_2/replacement_followers)
    (ai_place return_beach_2/replacement_jackals)
    (ai_place return_beach_2/replacement_grunts)
    
    ;; Wait for a player to start leaving
    (sleep_until (volume_test_players_any ext_beach_2_leaving) 1)
    
    ;; You did it man, good job
    (game_save_no_timeout)
)

;; ---
;; cliffa_lid

(script dormant m_ext_lid
    ;; Wait until a player leaves the beach
    (sleep_until 
        (or
            (volume_test_players_any ext_beach_2_leaving)
            (volume_test_players_any ext_cart_return_approaching)
        )
    1)
    
    ;; You did it man, good job
    (game_save_no_timeout)
    
    ;; Warp in lid guards
    (ai_place ext_lid)
    
    ;; Elite replaces exit Grunts on legendary (Elite itself will spawn via squad counts)
    (if (game_is_impossible)
        (ai_erase ext_lid/exit_grunts)
    )
    
    ;; AA Wraith justifies a checkpoint, right
    (game_save_no_timeout)
    
    ;; Wait for a player to enter the lid area
    (sleep_until (volume_test_players_any ext_lid_entered))
    
    ;; The special easy Phantom can go away now
    (object_destroy ext_beach_1_cship)
    (sleep -1 m_ext_beach_2_cship)
    
    ;; You did it man, good job
    (game_save_no_timeout)
    
    ;; Entrance guards reinforce center
    (ai_migrate ext_lid/entrance ext_lid/lid_jackals)
    
    ;; Exit units attack down
    (ai_attack ext_lid/exit)

    ;; Wait for a player to start leaving
    (sleep_until (volume_test_players_any ext_cart_returning))
    
    ;; You did it man, good job
    (game_save_no_timeout)
    
    ;; Center Elite chases
    (ai_migrate ext_lid/lid_elite ext_lid/exit_grunts)
)

(script dormant m_ext_lid_returning
    (sleep_until (volume_test_players_any ext_beach_2_leaving) 1)
    (skip_second)
    
    ;; Existing units know you're around
    (ai_set_current_state ext_lid search)
    
    ;; These special chumps always show up
    (if (game_is_easy)
        (ai_place return_lid/easy)
    )
    
    ;; If the players cleared the area, some replacements come in
    (if (< 3 (ai_living_count ext_lid))
        (sleep_forever)
    )
    
    ;; (Here they are)
    (ai_place return_lid/spawn)
    (ai_follow_target_players return_lid )
    
    ;; Wait for a player to start leaving
    (sleep_until (volume_test_players_any ext_cart_returning))
    
    ;; You did it man, good job
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_ext_cave_startup
    ;; Let's begin
    (wake m_ext_cave)
    (wake m_ext_beach_2)
    (wake m_ext_lid)

    ;; Sigh.
    (wake ultimate_checkpoint_man)
)

(script static void m_ext_cave_cleanup
    ;; Don't need this anymore
    (sleep -1 m_ext_beach_2)
    (ai_erase ext_beach_2)

    ;; Don't need this anymore
    (sleep -1 m_ext_lid)
    (ai_erase ext_lid)

    ;; Don't need this anymore
    (sleep -1 m_ext_lid_returning)
    (sleep -1 m_ext_beach_2_returning)
    (ai_erase return_lid)
    (ai_erase return_beach_2)
    (object_destroy return_beach_2_wraith)
)

(script static void m_ext_cave_mark_return
    ;; No more cave. You had your chance.
    (ai_erase ext_cave)
    (sleep -1 m_ext_cave)

    ;; Some guys might do stuff here too
    (wake m_ext_lid_returning)
    (wake m_ext_beach_2_returning)
)

;; ---
;; CART FIELD
;; ---

;; ---
;; Updaters

;; This guy keeps the checkpoints coming
(global boolean m_ext_cart_checkpoints_start false)
(script continuous m_ext_cart_checkpoint_bastard
    (sleep_until m_ext_cart_checkpoints_start 1)
    (sleep_until
        (and
            (not (game_safe_to_save))
            (volume_test_players_any ext_cart_main)
        )
    )
    (sleep_until
        (game_safe_to_save)
    )
    (game_save_no_timeout)
    (sleep 900)
)

(global boolean ext_cart_frontal_approach false)
(global boolean ext_cart_secret_placed false)

;; Helper scripts for ext_cart entrance dudes
(script static void send_ext_cart_entrance_left
    (ai_migrate ext_cart_entrance/ledge_left ext_cart_entrance/left_platform_far)
    (ai_migrate ext_cart_entrance/ledge_right ext_cart_entrance/right_platform_near)
    (ai_migrate ext_cart_entrance/ledge_center ext_cart_entrance/center_left)
)

;; Helper script for ext_cart entrance dudes
(script static void send_ext_cart_entrance_right
    (ai_migrate ext_cart_entrance/ledge_right ext_cart_entrance/right_platform_far)
    (ai_migrate ext_cart_entrance/ledge_left ext_cart_entrance/left_platform_near)
    (ai_migrate ext_cart_entrance/ledge_center ext_cart_entrance/center_right)
)

(global boolean m_ext_cart_updater_start false)
(script continuous m_ext_cart_updater
    (sleep_until m_ext_cart_updater_start 1)

    ;; Move the left dudes to whoever's farthest up the field
    (cond
        (
            (volume_test_players_any ext_cart_platform_left)
            
            (if (> 4 (ai_living_count ext_cart_field/left))
                (ai_migrate ext_cart_field/left ext_cart_entrance/left_platform_far)
            )
            (if (> 4 (ai_living_count ext_cart_field/left_advance))
                (ai_migrate ext_cart_field/left ext_cart_field/left_defensive)
            )
            (ai_magically_see_players ext_cart_entrance/sniper)
        )
        (
            (volume_test_players_any ext_cart_side_left)
            
            (ai_migrate ext_cart_field/left ext_cart_field/treeline_retreat)
            (ai_migrate ext_cart_field/left_advance ext_cart_field/treeline_retreat_edge)
            (ai_migrate ext_cart_field/center ext_cart_field/center_right_defensive)
        )
        (
            (volume_test_players_any ext_cart_terrain_front)
            
            (ai_migrate ext_cart_field/left ext_cart_field/treeline_elites)
            (ai_migrate ext_cart_field/left_advance ext_cart_field/treeline_advance_elites)
        )
    )
    
    ;; Move the right dudes to whoever's farthest up the field
    (cond
        (
            (volume_test_players_any ext_cart_platform_right)
            
            (if (> 4 (ai_living_count ext_cart_field/center))
                (ai_migrate ext_cart_field/center ext_cart_entrance/right_platform_far)
            )
            (if (> 4 (ai_living_count ext_cart_field/center_advance))
                (ai_migrate ext_cart_field/center ext_cart_field/right_defensive)
            )
            (ai_magically_see_players ext_cart_entrance/sniper)
        )
        (
            (volume_test_players_any ext_cart_side_right)
            
            (ai_migrate ext_cart_field/center ext_cart_field/center_right_defensive)
            (ai_migrate ext_cart_field/center_advance ext_cart_field/center_advance_rear)
        )
        (
            (volume_test_players_any ext_cart_terrain_front)
            
            (ai_migrate ext_cart_field/center_advance ext_cart_field/center_advance_front)
        )
    )
    
    ;; Move the entrance dudes to reinforce the left if under full assault
    (if
        (or
            (volume_test_players_all ext_cart_platform_left)
            (volume_test_players_all ext_cart_side_left)
        )
        (send_ext_cart_entrance_left)
    )
    
    ;; Move the entrance dudes to reinforce the right if under full assault
    (if
        (or
            (volume_test_players_all ext_cart_platform_right)
            (volume_test_players_all ext_cart_side_right)
        )
        (send_ext_cart_entrance_right)
    )
    
    ;; Prioritize the vulnerable underside if anyone's going for it
    (if (volume_test_players_any ext_cart_under)
        (begin
            (ai_migrate ext_cart_field/left ext_cart_field/treeline_elites)
            (ai_migrate ext_cart_field/left_advance ext_cart_field/treeline_side)
            (ai_migrate ext_cart_field/center ext_cart_field/center_right)
            (if (not ext_cart_secret_placed)
                (begin
                    (set ext_cart_secret_placed true)
                    (ai_place ext_cart_secret)
                    (ai_attack ext_cart_secret/secret)
                    (ai_set_current_state ext_cart_secret/secret guard)
                )
            )
        )
    )
)

;; ---
;; Main encounter

(global boolean m_ext_cart_cship_idle true)

;; cship flavor
(global boolean m_ext_cart_cship_start false)
(script continuous m_ext_cart_cship_flavor
    (sleep_until m_ext_cart_cship_start 1)

    (if m_ext_cart_cship_idle
        (phantom_hover_and_bank ext_cart_cship)
        (begin
            ;; Un-hover the phantom, send it away, end the script
            (vehicle_hover ext_cart_cship false)
            (recording_play_and_delete ext_cart_cship ext_cart_cship_out)
            (sleep_forever)
        )
    )
)

(script dormant m_ext_cart
    ;; Wait for a player to be in position
    (sleep_until
        (or
            (volume_test_players_any ext_cart_approach)
            (volume_test_players_any ext_cart_terrain_front)
            (volume_test_players_any ext_cart_smallgorge)
        )
    )
    
    ;; Save game
    (game_save_no_timeout)

    ;; The hog adventure is definitely over
    (m_ext_hog_adventure_end_music)

    ;; Gah
    (if (not (game_is_easy))
        (object_create magic_shotgun)
    )
    
    ;; Place the enemy dudes
    (ai_place ext_cart_field)
    
    ;; Special tower for the special difficulty
    (if (not (game_is_easy))
        (ai_erase ext_cart_field/grunt_tower_easy)
    )

    ;; cship flavor event
    (create_ext_cart_cship)
    (object_teleport ext_cart_cship ext_cart_cship_flag)
    (vehicle_hover ext_cart_cship true)
    (set m_ext_cart_cship_start true)

    ;; Wait for a player to be at the Cartographer
    (sleep_until
        (or
            (volume_test_players_any ext_cart_visible)
            (volume_test_players_any ext_cart_crap1)
        )
        10
    )
    
    ;; Start approach music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")
    
    ;; Special sound pitch for the special difficulty
    (if (game_is_easy)
        (begin
            (sound_looping_set_scale "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found" 0.1)
            (phantom_of_the_map)
        )
    )

    ;; Don't be obvious
    (sleep (random_range 30 90))

    ;; Seen conversation
    (if (game_is_easy)
        (ai_conversation ext_cart_seen_special)
        (ai_conversation ext_cart_seen)
    )
    
    ;; Players have found the Cartographer
    (set mission_state mission_cartographer_found)

    ;; Save game
    (game_save_no_timeout)
    
    ;; Checkpoints become hard to manage, so get this guy to handle them for us
    (set m_ext_cart_checkpoints_start true)
    
    ;; Different initial configuration based on players' position
    (if (volume_test_players_any ext_cart_visible)
        (begin
            (set ext_cart_frontal_approach true)
        )
        (begin
            (set ext_cart_frontal_approach false)
            (ai_migrate ext_cart_field/left ext_cart_field/treeline_retreat)
            (ai_migrate ext_cart_field/left_advance ext_cart_field/treeline_retreat_edge)
            (ai_place ext_cart_entrance)
            (ai_set_current_state ext_cart_entrance search)
            (send_ext_cart_entrance_left)
            
            ;; Special Wraith for the special difficulty
            (if (game_is_easy)
                (begin
                    (ai_erase ext_cart_entrance/right_platform_elites)
                    (object_create_anew cart_wraith_easy)
                    (ai_go_to_vehicle ext_cart_entrance/wraith_pilot_easy cart_wraith_easy "driver")
                )
                (ai_erase ext_cart_entrance/wraith_pilot_easy)
            )
        )
    )

    ;; Set up guards
    (ai_migrate ext_cart_field/center ext_cart_field/center_rear)
    (ai_migrate ext_cart_field/center_advance ext_cart_field/center_advance_front)

    (ai_set_current_state ext_cart_field/center guard)
    (ai_set_current_state ext_cart_field/center_advance guard)
    (ai_set_current_state ext_cart_field/left guard)

    ;; Wake AI management script
    (set m_ext_cart_updater_start 1)
    
    ;; Save game
    (game_save_no_timeout)

    ;; Wait for a player to be at the cartographer
    (sleep_until
        (volume_test_players_any ext_cart_main)
        10
    )
    
    ;; Arrival conversation
    (if (not (game_is_easy))
        (ai_conversation ext_cart_arrival)
    )

    ;; Have the flavor ship leave
    (set m_ext_cart_cship_idle false)

    ;; Place interior guys if they were not already placed
    (if ext_cart_frontal_approach
        (begin
            (ai_place ext_cart_entrance)
            
            ;; Special Wraith for the special difficulty
            (if (game_is_easy)
                (begin
                    (ai_erase ext_cart_entrance/right_platform_elites)
                    (object_create_anew cart_wraith_easy)
                    (skip_frame)
                    (ai_go_to_vehicle ext_cart_entrance/wraith_pilot_easy cart_wraith_easy "driver")
                )
                (ai_erase ext_cart_entrance/wraith_pilot_easy)
            )
        )
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Activate the turret
    (ai_go_to_vehicle ext_cart_entrance/ledge_center ext_cart_turret_front "gunner")

    ;; Wait for a player to get to the structure
    (sleep_until
        (or
            (volume_test_players_any ext_cart_side_left)
            (volume_test_players_any ext_cart_side_right)
            (volume_test_players_any override_cliffs_entrance)
            (volume_test_players_any ext_cart_entrance_past)
            (volume_test_players_any ext_cart_secret_inside)
        )
        10
    )

    ;; Retreat some of the outer field guys
    (ai_retreat ext_cart_field/left_advance)
    (ai_retreat ext_cart_field/center_advance)

    ;; Save game
    (game_save_no_timeout)
    
    ;; Wait for a player to get inside & attack, or wipe out the Covenant, or be pushed back
    (sleep_until
        (or
            (and
                (volume_test_players_any ext_cart_entrance)
                (> 4 (ai_status ext_cart_entrance/interior))
            )
            (= 0 (ai_living_count ext_cart_entrance/interior))
            (volume_test_players_any ext_cart_entrance_past)
            (volume_test_players_any override_cliffs_entrance)
            (volume_test_players_any ext_cart_returning)
        )
        15
        3600
    )

    ;; Save game
    (game_save_no_timeout)

    ;; Make sure that the entrance guys go on the defensive
    (ai_defend ext_cart_entrance/ledge_left)
    (ai_defend ext_cart_entrance/ledge_right)
    (ai_defend ext_cart_entrance/ledge_center)

    ;; Kill the ext management script
    (sleep -1 m_ext_cart_updater)

    ;; Turn off the music but wait a little so it's not so obvious
    (sleep (random_range 90 150))
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")

    ;; If a player is in the shaft area, have the extra line
    (if
        (or
            (volume_test_players_any ext_cart_platform_left)
            (volume_test_players_any ext_cart_platform_right)
            (volume_test_players_any ext_cart_entrance)
            (volume_test_players_any ext_cart_entrance_past)
            (volume_test_players_any ext_cart_entrance_hall)
            (volume_test_players_any override_lock_window)
        )
        (begin
            ;; The shaft entered conversation begins
            (if (game_is_easy)
                (ai_conversation ext_cart_entered_special)
                (ai_conversation ext_cart_entered)
            )

            ;; Wait for the conversation to finish
            (sleep_until
                (< 4 (ai_conversation_status ext_cart_entered))
                1
            )

            ;; Set objective
            (if (game_is_easy)
                (objective_set dia_found_ez obj_found_ez)
                (objective_set dia_found obj_found)
            )

            (ai_conversation ext_cart_deep)
        )
    )
    
    ;; Save game, we're done
    (game_save_no_timeout)
)

;; ---
;; Mission hooks

(script static void m_ext_cart_startup   
    (wake m_ext_cart)
)

(script static void m_ext_cart_cleanup
    ;; Kill progression scripts
    (sleep -1 m_ext_cart)
    
    ;; Kill other things
    (sleep -1 m_ext_cart_updater)
    (sleep -1 m_ext_cart_cship_flavor)
    
    ;; Prevent music excess
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")
    
    ;; Uh
    (object_destroy ext_cart_cship)
    
    ;; What more do they want!?
)

;; ---
;; MAIN MISSION
;; ---

;; ---
;; Pelican drop helpers

;; "i hope lag isn't mad that i'm using another global" - dafi
(global boolean m_ext_drop_hog_dropped false)

;; "no, i'm not. in fact, here i am using another two" - lag, soon after
(global vehicle m_ext_drop_pod_veh none)
(global string m_ext_drop_pod_marker none)

(script static void m_ext_drop_pods_assemble
    (object_create ext_drop_pod_1)
    (object_create ext_drop_pod_2)
    (object_create ext_drop_pod_3)
    (object_create ext_drop_pod_4)
)

(script static void m_ext_drop_pods_detach
    (if (game_is_easy)
        (object_create ext_drop_pod_w1s)
        (object_create ext_drop_pod_w1)
    )
    (sleep 15)

    (if (game_is_easy)
        (object_create ext_drop_pod_w3s)
        (object_create ext_drop_pod_w3)
    )
    (sleep 15)

    (object_create ext_drop_pod_w4)
    (sleep 15)

    (object_create ext_drop_pod_w2)
)

(script static void m_ext_drop_pod_drop
    (effect_new_on_object_marker 
        "cmt\scenery\_shared\h_drop_pod\effects\h_drop_pod_detach" 
        insertion_pelican_2 
        m_ext_drop_pod_marker
    )

    (skip_half_second)
    (objects_detach insertion_pelican_2 m_ext_drop_pod_veh)
)

(global boolean m_ext_drop_secret_start false)
(script continuous m_ext_drop_secret
    (sleep_until m_ext_drop_secret_start 1)

    ;; CO-OP: If more players are added, check them all here
    (if (and
            (not (unit_has_weapon (player0) "cmt\weapons\evolved\dmr\dmr"))
            (not (unit_has_weapon (player1) "cmt\weapons\evolved\dmr\dmr"))
        )
        (object_teleport ext_drop_pod_w1s ext_drop_secret)
    )
)

(script dormant m_ext_drop_pod
    ;; Set up the pod Pelican
    (object_create_anew insertion_pelican_2)
    (unit_set_enterable_by_player insertion_pelican_2 false)

    ;; Set up the pods
    (m_ext_drop_pods_assemble)
    (objects_attach insertion_pelican_2 "droppodl01" ext_drop_pod_1 "attach")
    (objects_attach insertion_pelican_2 "droppodr03" ext_drop_pod_2 "attach")
    (objects_attach insertion_pelican_2 "droppodl03" ext_drop_pod_3 "attach")
    (objects_attach insertion_pelican_2 "droppodr01" ext_drop_pod_4 "attach")
    (unit_close insertion_pelican_2)

    ;; Fly in
    (object_teleport insertion_pelican_2 pod_peli_flag)
    (recording_play_and_hover insertion_pelican_2 pod_pelican_in)

    ;; Make sure a player's not going to get smashed
    (sleep_until
        (or
            (not (volume_test_players_any ext_drop_pod_vol))
            (game_is_easy)
        )
    )
    
    ;; Then drop the pods when it's time
    (sleep_until (< (recording_time insertion_pelican_2) 50))
    
    (set m_ext_drop_pod_marker "droppodl03")
    (set m_ext_drop_pod_veh ext_drop_pod_3)
    (m_ext_drop_pod_drop)
    
    (set m_ext_drop_pod_marker "droppodr03")
    (set m_ext_drop_pod_veh ext_drop_pod_2)
    (m_ext_drop_pod_drop)
    
    (set m_ext_drop_pod_marker "droppodr01")
    (set m_ext_drop_pod_veh ext_drop_pod_4)
    (m_ext_drop_pod_drop)
    
    (set m_ext_drop_pod_marker "droppodl01")
    (set m_ext_drop_pod_veh ext_drop_pod_1)
    (m_ext_drop_pod_drop)
    
    ;; Wait a bit, then give the player a waypoint in case they haven't noticed the magnificent bounty awaiting them
    (sleep 100)
    (if (or
            (volume_test_players_any lz_beach_final)
            (volume_test_players_any lz_beach_threshold)
            (volume_test_players_any lz_beach_main)
        )
        (activate_team_nav_point_flag "weapon_ord" player drop_pod_lz 0.3)
    )
    
    ;; Detach guns once pods have landed
    (m_ext_drop_pods_detach)
    
    ;; Done - fly away
    (vehicle_hover insertion_pelican_2 false)
    (recording_play_and_delete insertion_pelican_2 pod_pelican_out)
)

(script dormant m_ext_drop_hog
    ;; Set up the hog Pelican
    (create_insertion_pelican_1)
    (unit_set_enterable_by_player insertion_pelican_1 false)
    
    ;; Special hog for the special difficulty
    (if (game_is_easy)
        (begin
            (object_create_anew ext_drop_rhog)
            (objects_attach insertion_pelican_1 "cargo" ext_drop_rhog "cargo")
        )
        (begin
            (object_create_anew ext_drop_hog)
            (objects_attach insertion_pelican_1 "cargo" ext_drop_hog "cargo")
        )
    )
    (unit_close insertion_pelican_1)
    
    ;; Fill it with marines
    (ai_place lz_marines_holding/init)
    (ai_place lz_marines_holding/init_rider)
    (vehicle_load_magic insertion_pelican_1 "rider" (ai_actors lz_marines_holding/init))
    (vehicle_load_magic insertion_pelican_1 "rider" (ai_actors lz_marines_holding/init_rider))
    
    ;; Fly in
    (object_teleport insertion_pelican_1 hog_peli_flag)
    (recording_play_and_hover insertion_pelican_1 hog_pelican_in)
    
    ;; Then drop the hog once in position (and make sure a player isn't going to get crushed)
    (sleep_until
        (and
            (< (recording_time insertion_pelican_1) 1)
            (or
                (not (volume_test_players_any ext_drop_hog_vol))
                (game_is_easy)
            )
        )
    )
    (objects_detach insertion_pelican_1 ext_drop_hog)
    (objects_detach insertion_pelican_1 ext_drop_rhog)

    (if (or
            (volume_test_players_any lz_beach_final)
            (volume_test_players_any lz_beach_threshold)
            (volume_test_players_any lz_beach_main)
        )
        (if (game_is_easy)
            (activate_team_nav_point_object "vehicle_ord" player ext_drop_rhog 0.5)
            (activate_team_nav_point_object "vehicle_ord" player ext_drop_hog 0.5)
        )
    )
    
    ;; Have the Marines get out + migrate
    (skip_second)
    (unit_open insertion_pelican_1)
    (sleep 60)
    (custom_animation insertion_pelican_1 "cmt\vehicles\_shared\pelican\pelican" "cinematic-dip" true)
    (sleep 60)
    (vehicle_unload insertion_pelican_1 "rider")
    (sleep 45)
    (ai_command_list lz_marines_holding/init move_forwards)
    (ai_command_list lz_marines_holding/init_rider move_forwards)
    
    ;; Mark the hog as having been dropped
    (set m_ext_drop_hog_dropped true)
    
    ;; Hurry...
    (if (not (game_is_easy))
        (begin
            (object_create_anew ext_drop_pod_w1s)
            (set m_ext_drop_secret_start true)
        )
    )
    
    ;; Counter Marine misbehavior
    (skip_second)
    (ai_set_current_state lz_marines_holding/init "move_random")
    (ai_set_current_state lz_marines_holding/init_rider "move_random")

    ;; Is it too late?
    ;; CO-OP: If more players are added, check them all here
    (sleep 90)
    (if
        (and    
            (not (unit_has_weapon (player0) "cmt\weapons\evolved\dmr\dmr"))
            (not (unit_has_weapon (player1) "cmt\weapons\evolved\dmr\dmr"))
            (not (game_is_easy))
        )
        (begin
            (object_destroy ext_drop_pod_w1s)
            (sleep -1 m_ext_drop_secret)
        )
        (object_create_containing "dmr_pack")
    )
    
    ;; Fly off after everybody's gotten out
    (sleep 115)
    (vehicle_hover insertion_pelican_1 false)
    (recording_play_and_delete insertion_pelican_1 hog_pelican_out)

    (sleep 140)
    (unit_close insertion_pelican_1)
    (ai_migrate lz_marines_holding lz_marines_holding/lz)
)

(script dormant m_ext_drop_words
    ;; Incoming
    (ai_conversation jeep_delivery)
    
    ;; Wait for the hog to be dropped
    (sleep_until m_ext_drop_hog_dropped)

    ;; Have Cortana ask for Marine assistance
    ;; CO-OP: Don't do this in co-op, so the players have room to configure themselves
    (if (and
            (not (game_is_cooperative))
            (< (list_count (vehicle_riders ext_drop_hog)) 2)
        )
        (ai_conversation jeep_load)
    )
    (sleep_until (< 1 (ai_conversation_line jeep_load)) 1)
    
    ;; Wait for people to stop saying their lines
    (sleep 90)
    
    ;; Tell the player to get a move on
    (if (game_is_easy)
        (ai_conversation jeep_go_special)
        (ai_conversation jeep_go)
    )

    ;; Objective text
    (if (game_is_easy)
        (objective_set dia_find_ez obj_find_ez)
        (objective_set dia_find obj_find)
    )
)

;; ---
;; Main drop sequence

;; Fake version of the drop that runs on skipping m_ext
(script dormant m_ext_drop_skip
    ;; The players must be in the right BSP to drop the pods
    (sleep_until (= bsp_index_ext_lz (structure_bsp_index)))

    ;; Drop the pods
    (m_ext_drop_pods_assemble)
    (object_teleport ext_drop_pod_1 "ext_skip_drop1")
    (object_teleport ext_drop_pod_2 "ext_skip_drop2")
    (object_teleport ext_drop_pod_3 "ext_skip_drop3")
    (object_teleport ext_drop_pod_4 "ext_skip_drop4")
    (skip_second)
    (m_ext_drop_pods_detach)
)

(script dormant m_ext_drop
    ;; Players won't get Foehammer's goodie bag without clearing the LZ
    (sleep_until mission_lz_cleared)

    ;; If the players have gone on ahead, we'll just do a fake version
    (if (!= bsp_index_ext_lz (structure_bsp_index))
        (begin
            (wake m_ext_drop_skip)
            (wake m_ext_drop_words)

            ;; Even here, there is a special hog for the special difficulty
            (if (game_is_easy)
                (object_create_anew ext_drop_rhog)
                (object_create_anew ext_drop_hog)
            )

            (object_teleport ext_drop_rhog ext_skip_drop_hog)
            (object_teleport ext_drop_hog ext_skip_drop_hog)

            ;; Place the dudes
            (ai_place lz_marines/left_marines)
            (ai_migrate lz_marines lz_marines_holding)
            (sleep_forever)
        )
    )

    ;; Wait for players to not be in a moronic place
    (sleep_until
        (volume_test_players_all lz_beach_final)
        5
        150
    )

    ;; Make Marines be okay
    (ai_migrate lz_marines lz_marines_holding/lz)
    (ai_migrate lz_marines_holding lz_marines_holding/lz)
    (ai_renew lz_marines_holding)
    (ai_command_list lz_marines_holding/lz move_forwards)
    (skip_second)

    ;; Have the Pelicans come in for resupply
    (wake m_ext_drop_pod)
    
    (sleep 70)
    (wake m_ext_drop_words)
    
    ;; Wait a little before dropping the hog so the guns drop first
    (sleep 250)
    (wake m_ext_drop_hog)

    ;; Wait for hog to be dropped
    (sleep_until m_ext_drop_hog_dropped)

    ;; Tell the Marines to come over and help out
    ;; CO-OP: Don't do this in co-op, so the players have room to configure themselves
    (if (not (game_is_cooperative))
        (begin
            ;; Wait for assistance request
            (skip_second)
            (sleep_until (< 1 (ai_conversation_line jeep_load)) 1)

            ;; Load the Marines
            (ai_go_to_vehicle lz_marines_holding/init_rider ext_drop_hog "passenger")
            (ai_go_to_vehicle lz_marines_holding/lz ext_drop_hog "gunner")
        )
    )

    ;; Wait for people to stop saying their lines
    (sleep 90)
    (ai_migrate lz_marines_holding/init_rider lz_marines_holding/lz)

    ;; Non-shotgun Marines can now enter the hog
    (if (not (game_is_cooperative))
        (ai_go_to_vehicle lz_marines_holding ext_drop_hog "passenger")
    )

    ;; Wait for a player to go do shit
    (sleep_until
        (or
            (volume_test_players_any ext_beach_1_approach)
            (volume_test_players_any lz_beach_side)
            (vehicle_test_seat_list ext_drop_hog "w-driver" (players))
            (!= bsp_index_ext_lz (structure_bsp_index))
        )
        5
        1800
    )
    
    ;; No more nav point
    (deactivate_team_nav_point_object player ext_drop_hog)
    (deactivate_team_nav_point_object player ext_drop_rhog)
    (deactivate_team_nav_point_flag player drop_pod_lz)
    
    ;; Wait a bit for new music trigger
    (skip_second)

    (if (vehicle_test_seat_list ext_drop_hog "w-driver" (players))
        ;; Begin the hog adventure!
        (m_ext_hog_adventure_start_music)
    )

    ;; Done
    (game_save_no_timeout)
)

;; ---
;; The mission-wide Warthog adventure

;; 0 - Init
;; 1 - Active
;; 2 - End
(global short m_ext_hog_adventure_state 0)

(script dormant m_ext_hog_adventure_music
    (sleep_until (= 1 m_ext_hog_adventure_state))

    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01_insertion")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01a_insertion_end")

    ;; What are you doing, you silly player
    (sleep_until mission_lz_cleared 1)

    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_02_warthog_adventure")
    (sleep_until  
        (= 2 m_ext_hog_adventure_state)
        30
        5400    ;; (180 * 30)
    )
    (set m_ext_hog_adventure_state 2)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_02_warthog_adventure")
)

(script static void m_ext_hog_adventure_start_music
    (set m_ext_hog_adventure_state 1)
)

(script static void m_ext_hog_adventure_end_music
    (set m_ext_hog_adventure_state 2)
)

;; ---
;; Mission hooks

(script static void m_ext_launch
    ;; End checkpoint launch setup
    (checkpoint_launch bsp_index_ext_lz m_ext_spawn_0 m_ext_spawn_1)
)

(script static void m_ext_start
    ;; Launch mission if we have to
    (if (= b30r_launch_ext mission_launch_index)
        (m_ext_launch)
    )
    
    ;; The rest of the mission follows
    (m_ext_beach_1_startup)
    (m_ext_canyon_startup)
    (m_ext_cart_startup)
    (m_ext_cave_startup)
    
    ;; Enable the adventurous music cues
    (wake m_ext_hog_adventure_music)

    ;; Enable LZ-cleared drop sequence
    (wake m_ext_drop)
)

(script static void m_ext_clean
    ;; Clean up the individual sub-missions
    (m_ext_beach_1_cleanup)
    (m_ext_canyon_cleanup)
    (m_ext_cart_cleanup)
    (m_ext_cave_cleanup)
)

(script static void m_ext_return
    ;; You missed your chance for the drop, pal
    (sleep -1 m_ext_drop)

    ;; Hog adventure definitely cannot continue
    (m_ext_hog_adventure_end_music)

    ;; But we will be returning to the cave
    (m_ext_cave_mark_return)
)

(script static void m_ext_skip
    ;; Drop happened
    (ai_place lz_marines/left_marines)
    (ai_migrate lz_marines lz_marines_holding)
    (wake m_ext_drop_skip)

    ;; You found the Cartographer
    (set mission_state mission_cartographer_found)

    ;; The adventure is over
    (m_ext_hog_adventure_end_music)

    ;; Not the cave though. You'll be coming back to the cave.
    (m_ext_cave_startup)
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - Return
;; 4 - End
(global long m_ext_ctrl_state 0)

(script dormant m_ext_control
    (if (!= m_ext_ctrl_state 1)
        (m_ext_skip)
        (m_ext_start)
    )

    ;; For simplicity, we assume the return steps have happened before cleaning
    (sleep_until (>= m_ext_ctrl_state 3))
    (m_ext_return) 

    (sleep_until (>= m_ext_ctrl_state 4))
    (m_ext_clean)
)

(script static void m_ext_startup
    (if (= 0 m_ext_ctrl_state)
        (begin
            (set m_ext_ctrl_state 1)
            (wake m_ext_control)
        )
    )
)

(script static void m_ext_mark_return
    (set m_ext_ctrl_state 3)
)

(script static void m_ext_cleanup
    (set m_ext_ctrl_state 4)
)

(script static void m_ext_mark_skip
    (m_ext_startup)
    (set m_ext_ctrl_state 2)
)