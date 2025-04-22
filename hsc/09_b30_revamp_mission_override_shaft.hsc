;; 09_b30_revamp_mission_override_shaft.hsc
;; Sub-mission for "override", isolated to this file because it's monstrously large
;; ---

;; ---
;; HUNTER ELEVATOR
;; ---

;; Terminology notes:
;; "L1" - Level 1, the bottom level
;; "L2" - Level 2, the top level
;; "hall" - The ramp hallway connecting the levels

;; CO-OP: Broadly speaking, the Hunters will change floors only if *all* players are not on the other floor.
;; If at least one player is on their floor, they'll just continue focusing on that player.
;; If both players are in the hall, they'll hang back and wait to see if they need to change floors.

;; ---
;; Common state tracking

;; DO NOT CHANGE THESE!
(global short encounter_alert 0)
(global short hunters_active 1)
(global short hunters_1dead 2)
(global short hunters_2dead 3)
(global short hunters_initialized 4)
(global short player_in_hall 5)
(global short hunter_level_curr 6)
(global short hunter_level_dest 7)
(global short player_hall_prev 8)

;; Hunter state
(global long m_o_shaft_elev_statebits 0)

;; Whether the encounter as a whole has been alerted
(script static boolean m_o_shaft_encounter_alert (= (bit_test m_o_shaft_elev_statebits encounter_alert) 1))
(script static void m_o_shaft_encounter_set_alert (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits encounter_alert true)))

;; Marks the last-known position of the players
(script static void m_o_shaft_player_set_hall (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits player_hall_prev true)))
(script static void m_o_shaft_player_set_nonhall (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits player_hall_prev false)))

;; Gets the last-known is-in-hall state of the players
(script static boolean m_o_shaft_player_hall_prev (= (bit_test m_o_shaft_elev_statebits player_hall_prev) 1))

;; ---
;; Hunter management

;; Store hunter AIs in vars for convenience
(global ai m_o_shaft_hunter_a none) ;; Guard
(global ai m_o_shaft_hunter_b none) ;; Chase

;; Whether the encounter has activated the Hunters
(script static boolean m_o_shaft_hunters_active (= (bit_test m_o_shaft_elev_statebits hunters_active) 1))
(script static void m_o_shaft_hunters_set_active (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunters_active true)))

;; Whether the encounter has passed the initial Hunter cycle
(script static boolean m_o_shaft_hunters_initialized (= (bit_test m_o_shaft_elev_statebits hunters_initialized) 1))
(script static void m_o_shaft_hunters_set_init (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunters_initialized true)))

;; Whether the encounter knows that one or both Hunters are dead
(script static boolean m_o_shaft_hunters_1dead (= (bit_test m_o_shaft_elev_statebits hunters_1dead) 1))
(script static void m_o_shaft_hunters_set_1dead (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunters_1dead true)))
(script static boolean m_o_shaft_hunters_2dead (= (bit_test m_o_shaft_elev_statebits hunters_2dead) 1))
(script static void m_o_shaft_hunters_set_2dead (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunters_2dead true)))

;; Marks the current floor level of the Hunters
(script static void m_o_shaft_hunters_set_curr_l2 (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunter_level_curr true)))
(script static void m_o_shaft_hunters_set_curr_l1 (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunter_level_curr false)))

;; Gets the current floor level of the Hunters
(script static short m_o_shaft_hunter_level_curr
    ;; Hack for the stack! On MCC, (bit_test) returns integer 0 (bit is unset) or 1 (bit is set).
    ;; So, we can simply add 1 to get the level number
    (+ (bit_test m_o_shaft_elev_statebits hunter_level_curr) 1)
)

;; Marks the desired floor level of the Hunters
(script static void m_o_shaft_hunters_set_dest_l2 (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunter_level_dest true)))
(script static void m_o_shaft_hunters_set_dest_l1 (set m_o_shaft_elev_statebits (bit_toggle m_o_shaft_elev_statebits hunter_level_dest false)))

;; Gets the desired floor level of the Hunters
(script static short m_o_shaft_hunter_level_dest
    ;; Same stack hack as (m_o_shaft_hunter_level_curr)
    (+ (bit_test m_o_shaft_elev_statebits hunter_level_dest) 1)
)

;; Whether Hunters are physically at either elevator
(script static boolean m_o_shaft_hunters_at_l1_elev (volume_test_objects_all override_shaft_elev_bot (ai_actors override_shaft_elev/hunters)))
(script static boolean m_o_shaft_hunters_at_l2_elev (volume_test_objects_all override_shaft_elev_top (ai_actors override_shaft_elev/hunters)))

;; Whether Hunters are physically at either level
(script static boolean m_o_shaft_hunter_a_at_l1 (volume_test_objects override_shaft_elev_fullbot (ai_actors m_o_shaft_hunter_a)))
(script static boolean m_o_shaft_hunter_b_at_l1 (volume_test_objects override_shaft_elev_fullbot (ai_actors m_o_shaft_hunter_b)))

(script static boolean m_o_shaft_hunter_a_at_l2
    (or
        (volume_test_objects override_shaft_elev_fulltop (ai_actors m_o_shaft_hunter_a))
        (volume_test_objects override_shaft_elev_hall_top (ai_actors m_o_shaft_hunter_a))
    )
)
(script static boolean m_o_shaft_hunter_b_at_l2
    (or
        (volume_test_objects override_shaft_elev_fulltop (ai_actors m_o_shaft_hunter_b))
        (volume_test_objects override_shaft_elev_hall_top (ai_actors m_o_shaft_hunter_b))
    )
)

(script dormant m_o_shaft_elev_rumble_move
    (sleep 30)
    
    ;; The player_effect knobs are prepared at the start of m_o_shaft_elev
    (player_effect_start 1 0.3)
    (player_effect_stop 0.5)
)

(script dormant m_o_shaft_elev_rumble_stop
    (sleep 30)
    
    ;; The player_effect knobs are prepared at the start of m_o_shaft_elev
    (player_effect_start 0.5 0.3)
    (player_effect_stop 0.5)
)

(script static void m_o_shaft_elev_hunters_up
    ;; Teleport them to the starting points
    ;; CO-OP: Don't teleport in co-op unless they can't be caught in the act
    (if
        (or
            (not (game_is_cooperative))
            (not (volume_test_players_any override_shaft_elev_fulltop))
        )
        (begin
            (object_teleport (list_get (ai_actors m_o_shaft_hunter_a) 0) m_o_shaft_hunter_a_l1)
            (object_teleport (list_get (ai_actors m_o_shaft_hunter_b) 0) m_o_shaft_hunter_b_l1)
        )
    )

    ;; Move the elevator
    (print_debug "m_o_shaft_elev_hunters_up: activating lift")
    (device_set_position ext_cave_hunter_lift 1)
    
    ;; Add an intimidating rumble
    (wake m_o_shaft_elev_rumble_move)

    ;; We have to secretly teleport them under the force field.
    (sleep_until (< 0.125 (device_get_position ext_cave_hunter_lift)) 1)
    (object_teleport (list_get (ai_actors m_o_shaft_hunter_a) 0) m_o_shaft_hunter_a_l1)
    (object_teleport (list_get (ai_actors m_o_shaft_hunter_b) 0) m_o_shaft_hunter_b_l1)

    ;; Await its arrival
    (print_debug "m_o_shaft_elev_hunters_up: waiting for lift")
    (sleep_until (< 0.885 (device_get_position ext_cave_hunter_lift)) 1)

    ;; Let them move again
    (print_debug "m_o_shaft_elev_hunters_up: lift arrived, un-freezing and migrating hunters")
    (ai_command_list_advance m_o_shaft_hunter_a)
    (ai_command_list_advance m_o_shaft_hunter_b)

    ;; Migrate and update AI
    (ai_migrate m_o_shaft_hunter_a override_shaft_elev/hunter_guard_top)
    (ai_migrate m_o_shaft_hunter_b override_shaft_elev/hunter_chase_top)
    (set m_o_shaft_hunter_a override_shaft_elev/hunter_guard_top)
    (set m_o_shaft_hunter_b override_shaft_elev/hunter_chase_top)
    
    ;; A softer rumble for landing
    (wake m_o_shaft_elev_rumble_stop)

    ;; Mark complete
    (m_o_shaft_hunters_set_curr_l2)
)

(script static void m_o_shaft_elev_hunters_down
    ;; Teleport them to the starting points, unless they fell down
    ;; CO-OP: Don't teleport in co-op unless they can't be caught in the act
    (if
        (or
            (not (game_is_cooperative))
            (not (volume_test_players_any override_shaft_elev_fullbot))
        )
        (begin
            (if (m_o_shaft_hunter_a_at_l2)
                (object_teleport (list_get (ai_actors m_o_shaft_hunter_a) 0) m_o_shaft_hunter_a_l2_u)
            )
            (if (m_o_shaft_hunter_b_at_l2)
                (object_teleport (list_get (ai_actors m_o_shaft_hunter_b) 0) m_o_shaft_hunter_b_l2_u)
            )
        )
    )

    ;; Move the elevator
    (print_debug "m_o_shaft_elev_hunters_down: activating lift")
    (device_set_position ext_cave_hunter_lift 0)
    
    ;; Add an intimidating rumble
    (wake m_o_shaft_elev_rumble_move)

    ;; We have to secretly teleport them under the force field.
    (sleep_until (> 0.75 (device_get_position ext_cave_hunter_lift)) 1)
    (if (m_o_shaft_hunter_a_at_l2)
        (object_teleport (list_get (ai_actors m_o_shaft_hunter_a) 0) m_o_shaft_hunter_a_l2)
    )
    (if (m_o_shaft_hunter_b_at_l2)
        (object_teleport (list_get (ai_actors m_o_shaft_hunter_b) 0) m_o_shaft_hunter_b_l2)
    )

    ;; Await its arrival
    (print_debug "m_o_shaft_elev_hunters_down: waiting for lift")
    (sleep_until (> 0.125 (device_get_position ext_cave_hunter_lift)) 1)

    ;; Let them move again
    (print_debug "m_o_shaft_elev_hunters_down: lift arrived, un-freezing and migrating hunters")
    (ai_command_list_advance m_o_shaft_hunter_a)
    (ai_command_list_advance m_o_shaft_hunter_b)

    ;; Migrate and update AI
    (ai_migrate m_o_shaft_hunter_a override_shaft_elev/hunter_guard)
    (ai_migrate m_o_shaft_hunter_b override_shaft_elev/hunter_chase)
    (set m_o_shaft_hunter_a override_shaft_elev/hunter_guard)
    (set m_o_shaft_hunter_b override_shaft_elev/hunter_chase)
    
    ;; A softer rumble for landing
    (wake m_o_shaft_elev_rumble_stop)

    ;; Mark complete
    (m_o_shaft_hunters_set_curr_l1)
)

(script continuous m_o_shaft_elev_l1_to_l2
    ;; Wait until we need to move
    (print_debug "m_o_shaft_elev_l1_to_l2: waiting for move command")
    (sleep_until
        (and
            (= 1 (m_o_shaft_hunter_level_curr))
            (= 2 (m_o_shaft_hunter_level_dest))
        )
        1
    )

    ;; Move the Hunters to the elevator via command list, advancing anything they were previously doing
    (print_debug "m_o_shaft_elev_l1_to_l2: move command received, moving hunters to elevator")
    (ai_command_list_advance override_shaft_elev/hunters)
    (ai_command_list m_o_shaft_hunter_a ov_shaft_elev_hunter_1_b)
    (ai_command_list m_o_shaft_hunter_b ov_shaft_elev_hunter_2_b)
    (ai_allow_charge override_shaft_elev/hunters false)

    ;; Just a little delay so they don't insta-teleport in front of the players
    (if (not (m_o_shaft_hunters_at_l1_elev))
        (sleep 90)
    )

    ;; Wait for an advance condition
    (sleep_until
        (cond
            ;; If the Hunters get to the elevator, or all players advance before they do, move them up
            (
                (or
                    (m_o_shaft_hunters_at_l1_elev)
                    (volume_test_players_all override_shaft_elev_fulltop)
                )
                (print_debug "m_o_shaft_elev_l1_to_l2: hunters at elevator or players at level 2, sending up")
                (m_o_shaft_elev_hunters_up)
                (ai_allow_charge override_shaft_elev/hunters true)
                true
            )
            ;; If we don't need to move to a new level anymore, forget about it
            (
                (or
                    (volume_test_players_any override_shaft_elev_fullbot)
                    (= 1 (m_o_shaft_hunter_level_dest))
                )
                (print_debug "m_o_shaft_elev_l1_to_l2: hunters no longer need to move up, cancelling")
                (m_o_shaft_hunters_set_dest_l1)
                (ai_command_list_advance override_shaft_elev/hunters)
                (ai_allow_charge override_shaft_elev/hunters true)
                true
            )
            ;; If neither condition is met, keep waiting
            (
                true
                false
            )
        )
        1 ;; ...run the check every frame
    )
    (print_debug "m_o_shaft_elev_l1_to_l2: finished moving hunters")
)

(script continuous m_o_shaft_elev_l2_to_l1
    ;; Wait until we need to move
    (print_debug "m_o_shaft_elev_l2_to_l1: waiting for move command")
    (sleep_until
        (and
            (= 2 (m_o_shaft_hunter_level_curr))
            (= 1 (m_o_shaft_hunter_level_dest))
        )
        1
    )

    ;; Move the Hunters to the elevator via command list, advancing anything they were previously doing
    ;; (Unless one fell down and is already wandering around looking for the other. Poor thing)
    ;; Additionally, if this is their first trip down, use the initital (_i) command list variant, which doesn't let
    ;; them fire at the players while riding down.
    (print_debug "m_o_shaft_elev_l2_to_l1: move command received, moving hunters to elevator")
    (ai_command_list_advance override_shaft_elev/hunters)
    (if (m_o_shaft_hunter_a_at_l2)
        (if (m_o_shaft_hunters_initialized)
            (ai_command_list m_o_shaft_hunter_a ov_shaft_elev_hunter_1_t)
            (ai_command_list m_o_shaft_hunter_a ov_shaft_elev_hunter_1_t_i)
        )
    )
    (if (m_o_shaft_hunter_b_at_l2)
        (if (m_o_shaft_hunters_initialized)
            (ai_command_list m_o_shaft_hunter_b ov_shaft_elev_hunter_2_t)
            (ai_command_list m_o_shaft_hunter_b ov_shaft_elev_hunter_2_t_i)
        )
    )
    (ai_allow_charge override_shaft_elev/hunters false)

    ;; Just a little delay so they don't insta-teleport in front of the players
    (if (not (m_o_shaft_hunters_at_l2_elev))
        (sleep 90)
    )

    ;; Wait for an advance condition
    (sleep_until
        (cond
            ;; If the Hunters get to the elevator, or all players advance before they do, move them down
            (
                (or
                    (m_o_shaft_hunters_at_l2_elev)
                    (volume_test_players_all override_shaft_elev_fullbot)
                )
                (print_debug "m_o_shaft_elev_l2_to_l1: hunters at elevator or player at level 1, sending down")
                (m_o_shaft_elev_hunters_down)
                (ai_allow_charge override_shaft_elev/hunters true)
                true
            )
            ;; If we don't need to move to a new level anymore, forget about it
            (
                (or
                    (volume_test_players_any override_shaft_elev_fulltop)
                    (= 2 (m_o_shaft_hunter_level_dest))
                )
                (print_debug "m_o_shaft_elev_l2_to_l1: hunters no longer need to move down, cancelling")
                (m_o_shaft_hunters_set_dest_l2)
                (ai_command_list_advance override_shaft_elev/hunters)
                (ai_allow_charge override_shaft_elev/hunters true)
                true
            )
            ;; If neither condition is met, keep waiting
            (
                true
                false
            )
        )
        1 ;; ...run the check every frame
    )
    (print_debug "m_o_shaft_elev_l2_to_l1: finished moving hunters")
)

(script dormant m_o_shaft_elev_hunters
    (print_debug "m_o_shaft_elev_hunters: awake")

    ;; Place the dudez and initialize our internal state tracking
    (if (game_is_easy)
        (begin
            ;; Special dudez for the special difficulty
            (ai_place override_shaft_elev/hunter_guard_easy)
            (ai_place override_shaft_elev/hunter_chase_easy)
            (ai_migrate override_shaft_elev/hunter_guard_easy override_shaft_elev/hunter_guard)
            (ai_migrate override_shaft_elev/hunter_chase_easy override_shaft_elev/hunter_chase)
        )
        (begin
            (ai_place override_shaft_elev/hunter_guard)
            (ai_place override_shaft_elev/hunter_chase)
        )
    )
    (set m_o_shaft_hunter_a override_shaft_elev/hunter_guard)
    (set m_o_shaft_hunter_b override_shaft_elev/hunter_chase)
    (m_o_shaft_hunters_set_curr_l2) ;; (They start on the top, obviously)
    (m_o_shaft_hunters_set_dest_l2)

    ;; Freeze the Hunters in place until they're ready for their big moment
    (ai_braindead override_shaft_elev/hunters true)

    ;; Wait until the main script signals that it's time for them
    (print_debug "m_o_shaft_elev_hunters: waiting for hunters to be activated")
    (sleep_until (m_o_shaft_hunters_active) 1)

    ;; Enable elevator management and move them down
    (print_debug "m_o_shaft_elev_hunters: hunters activated")
    (m_o_shaft_hunters_set_dest_l1)

    ;; Wait for the Hunters to arrive on the ground floor, for atmosphere points
    (print_debug "m_o_shaft_elev_hunters: awaiting hunter descent")
    (sleep_until (<= (device_get_position ext_cave_hunter_lift) 0.1) 1)

    ;; Turn on their brains and let them go to town
    (print_debug "m_o_shaft_elev_hunters: hunters descended, enable brains")
    (ai_braindead override_shaft_elev/hunters false)
    (m_o_shaft_hunters_set_init)

    ;; Wait until one of our beautiful friends is taken from us
    (print_debug "m_o_shaft_elev_hunters: awaiting hunter death")
    (sleep_until (< (ai_living_count override_shaft_elev/hunters) 2) 1)

    ;; Mark that a hunter is dead
    (print_debug "m_o_shaft_elev_hunters: first hunter dead")
    (m_o_shaft_hunters_set_1dead)

    ;; We don't want to move the survivor around until we know the elevator isn't moving
    (print_debug "m_o_shaft_elev_hunters: waiting for elevator to be stable")
    (sleep_until (= (m_o_shaft_hunter_level_curr) (m_o_shaft_hunter_level_dest)) 1)

    ;; Stop the elevator management, advance any command lists, and migrate survivors to the appropriate location
    (print_debug "m_o_shaft_elev_hunters: elevator stable, migrating survivor")
    (sleep -1 m_o_shaft_elev_l2_to_l1)
    (sleep -1 m_o_shaft_elev_l1_to_l2)
    (ai_command_list_advance override_shaft_elev/hunters)
    (ai_migrate override_shaft_elev/hunters override_shaft_elev/hunter_remnant)
    (set m_o_shaft_hunter_a override_shaft_elev/hunter_remnant)
    (set m_o_shaft_hunter_b override_shaft_elev/hunter_remnant)

    ;; Make the survivor guard the top level if they're there
    (if (= 2 (m_o_shaft_hunter_level_curr))
        (ai_defend override_shaft_elev/hunter_remnant)
    )

    ;; Wait until they are both but a sweet memory
    (print_debug "m_o_shaft_elev_hunters: awaiting total hunter death")
    (sleep_until (= (ai_living_count override_shaft_elev/hunters) 0))

    ;; That's all the elevator Hunters had to offer us in this life
    (print_debug "m_o_shaft_elev_hunters: both hunters dead")
    (m_o_shaft_hunters_set_2dead)
)

;; ---
;; Jackal management

;; Response to when a Hunter dies
(script static void m_o_shaft_elev_jackals_h_dead
    (print_debug "m_o_shaft_elev_jackals_h_dead: jackals responding to hunter death")

    ;; Move the Jackals to the bottom. Use a command list to help make sure they actually do it.
    (print_debug "m_o_shaft_elev_jackals_h_dead: moving jackals to bottom position")
    (ai_command_list_advance override_shaft_elev/jackals)
    (skip_frame)
    (ai_migrate override_shaft_elev/jackals_guard_top override_shaft_elev/jackals_guard_bottom)
    (ai_migrate override_shaft_elev/jackals_forward_top override_shaft_elev/jackals_forward_bottom)
    (ai_command_list override_shaft_elev/jackals ov_shaft_elev_jackals_mig_d)

    ;; Wait until they're in the hallway (or a player is in the hallway) to regain senses
    (print_debug "m_o_shaft_elev_jackals_h_dead: waiting for jackals / player to arrive")
    (sleep_until
        (or
            (volume_test_objects override_shaft_elev_hall_top (ai_actors override_shaft_elev/jackals))
            (volume_test_players_any override_shaft_elev_hall)
        )
        15
    )

    ;; Once folks are in position, enable combat
    (print_debug "m_o_shaft_elev_jackals_h_dead: combat engaged")
    (ai_command_list_advance override_shaft_elev/jackals)
    (ai_braindead override_shaft_elev/jackals_forward_top false)
    (ai_braindead override_shaft_elev/jackals_forward_bottom false)
)

;; Response to when the player enters the hall
(script static void m_o_shaft_elev_jackals_p_hall
    (print_debug "m_o_shaft_elev_jackals_p_hall: jackals responding to player in hall")

    ;; Allow Jackals to engage in combat, giving them a hint with magic sight.
    (print_debug "m_o_shaft_elev_jackals_h_dead: combat engaged")
    (ai_command_list_advance override_shaft_elev/jackals)
    (ai_braindead override_shaft_elev/jackals_forward_top false)
    (ai_braindead override_shaft_elev/jackals_forward_bottom false)
    (skip_frame)
    (ai_magically_see_players override_shaft_elev/jackals_guard_top)
    (ai_magically_see_players override_shaft_elev/jackals_forward_top)
    (skip_frame)

    ;; Set up a special command list to allow one of them to specifically ambush the player.
    (print_debug "m_o_shaft_elev_jackals_h_dead: playing ambush command lists")
    (ai_command_list override_shaft_elev/jackals_forward_top ov_shaft_elev_jackals_mig_t_l)
)

(script dormant m_o_shaft_elev_jackals
    (print_debug "m_o_shaft_elev_jackals: awake")

    ;; Depending on difficulty, these might be the famous apes we all know and love instead
    ;; After spawning, freeze the top Jackals in place until they're ready for their big moment
    (cond
        (
            (game_is_impossible)

            (ai_place override_shaft_elev/brute_guard_imposs)
            (ai_place override_shaft_elev/brutes_forward_imposs)
            (ai_migrate override_shaft_elev/brute_guard_imposs override_shaft_elev/jackals_guard_top)
            (ai_migrate override_shaft_elev/brutes_forward_imposs override_shaft_elev/jackals_forward_top)
        )
        (
            (game_is_easy)

            (ai_place override_shaft_elev/brutes_easy)
        )

        (
            true

            (ai_place override_shaft_elev/jackals_guard_top)
            (ai_place override_shaft_elev/jackals_forward_top)
        )
    )
    (ai_braindead override_shaft_elev/jackals_forward_top true)

    ;; Wait for the encounter to be alerted
    (print_debug "m_o_shaft_elev_jackals: waiting for encounter to be alerted")
    (sleep_until (m_o_shaft_encounter_alert))

    ;; Send the Jackals up
    (print_debug "m_o_shaft_elev_jackals: encounter alerted, sending jackals to top")
    (ai_command_list_by_unit (ai_actor override_shaft_elev/jackals_guard_top 0) ov_shaft_elev_jackals_up_0)
    (ai_command_list_by_unit (ai_actor override_shaft_elev/jackals_guard_top 1) ov_shaft_elev_jackals_up_1)

    ;; Wait for a Hunter to die or a player to hit the hall
    (print_debug "m_o_shaft_elev_jackals: waiting for signal to advance")
    (sleep_until
        (cond
            (
                (m_o_shaft_hunters_1dead)
                (m_o_shaft_elev_jackals_h_dead)
                true
            )
            (
                (volume_test_players_any override_shaft_elev_hall)
                (m_o_shaft_elev_jackals_p_hall)
                true
            )
            (
                true
                false
            )
        )
    )
)

;; ---
;; Auto-migration

;; Which unit in the encounter we're checking for potential rescue
(global short m_o_shaft_elev_rescue_idx 0)
(global unit m_o_shaft_elev_rescue_unit none)

;; "try denying it -- i took control of their minds and made them run away! try proving that i didn't use magic!!"
;; Whisper into the brains of wayward units and move them out of dangerous pathfinding zones.
(global boolean m_o_shaft_elev_rescue_start false)
(script continuous m_o_shaft_elev_rescue_witch
    (sleep_until m_o_shaft_elev_rescue_start 1)

    ;; If none are left alive, the witch's work here is done
    (if (= 0 (ai_living_count override_shaft_elev))
        (sleep -1)
        (if (>= m_o_shaft_elev_rescue_idx (ai_living_count override_shaft_elev))
            (set m_o_shaft_elev_rescue_idx 0)
        )
    )
    
    ;; Track the unit in question
    (set m_o_shaft_elev_rescue_unit (ai_actor override_shaft_elev m_o_shaft_elev_rescue_idx))

    ;; If an actor is in a danger zone, tell them to go to safety
    (cond
        (
            ;; Danger zone 1 (the glass alcove on the first floor)
            (volume_test_object override_shaft_elev_danger1 m_o_shaft_elev_rescue_unit)

            ;; Issue the command
            (print_debug "m_o_shaft_elev_rescue_witch: rescuing unit from danger zone 1")
            (if X_DBG_enabled
                (inspect m_o_shaft_elev_rescue_idx)
            )
            (ai_command_list_by_unit m_o_shaft_elev_rescue_unit ov_shaft_elev_rescue_1)

            ;; Wait a bit before trying again
            (print_debug "m_o_shaft_elev_rescue_witch: pausing to let unit move")
            (skip_second)
        )
        (
            ;; Danger zone 2 (the inner part of the ramp windows)
            (volume_test_object override_shaft_elev_danger2 m_o_shaft_elev_rescue_unit)

            ;; This one is tricky - wait a second to be _sure_ the unit is stuck and needs rescuing
            (print_debug "m_o_shaft_elev_rescue_witch: may need to rescue unit from danger zone 2...")
            (if X_DBG_enabled
                (inspect m_o_shaft_elev_rescue_idx)
            )
            (skip_second)
            (if (volume_test_object override_shaft_elev_danger2 m_o_shaft_elev_rescue_unit)
                (begin
                    ;; Issue the command
                    (print_debug "m_o_shaft_elev_rescue_witch: rescuing unit from danger zone 2")
                    (ai_command_list_by_unit m_o_shaft_elev_rescue_unit ov_shaft_elev_rescue_2)

                    ;; Wait a bit before trying again
                    (print_debug "m_o_shaft_elev_rescue_witch: pausing to let unit move")
                    (skip_second)
                )
            )
        )
        (
            ;; Danger zone 3 (hunters only, by the entrance crate on the left)
            (volume_test_objects override_shaft_elev_danger3 (ai_actors override_shaft_elev/hunters))

            ;; Toggle off the big pathfinding blocker to allow Hunter passage
            (print_debug "m_o_shaft_elev_rescue_witch: secretly disabling hunter-blocking pathfinding")
            (object_destroy "ov_shaft_enter_crateblocker1")

            ;; If all players are still above, use magic to make them get un-stuck
            (if (volume_test_players_all override_shaft_elev_fulltop)
                (begin
                    (if (volume_test_objects override_shaft_elev_danger3 (ai_actors m_o_shaft_hunter_a))
                        (ai_command_list m_o_shaft_hunter_a ov_shaft_elev_rescue_3)
                    )
                    (if (volume_test_objects override_shaft_elev_danger3 (ai_actors m_o_shaft_hunter_b))
                        (ai_command_list m_o_shaft_hunter_b ov_shaft_elev_rescue_3)
                    )
                )
            )

            ;; Wait for danger to pass
            (print_debug "m_o_shaft_elev_rescue_witch: waiting for danger to pass")
            (sleep_until
                (not (volume_test_objects override_shaft_elev_danger3 (ai_actors override_shaft_elev/hunters)))
                30
                300 ;; 10-second timeout so we don't block other rescue operations
            )

            ;; Restore the real blocker
            (print_debug "m_o_shaft_elev_rescue_witch: danger passed; secretly restoring real nutblocker")
            (object_create "ov_shaft_enter_crateblocker1")
        )
        (
            ;; Not actually a zone: a Hunter falls from the top floor and all players are still up there
            (and
                (volume_test_objects override_shaft_elev_fullbot (ai_actors override_shaft_elev/hunters))
                (volume_test_players_all override_shaft_elev_fulltop)
            )

            ;; Grant magic sight. Furthermore, use a special command list to move units out of danger.
            (print_debug "m_o_shaft_elev_rescue_witch: hunter fell below players, granting magic sight")
            (ai_magically_see_players override_shaft_elev/hunters)
        )
    )

    ;; Kill either player if under a descending lift
    ;; CO-OP: If more players are added, kill them here
    ;; (This should really just use a radial damage effect, to catch all unfortunate units generically)
    (if
        (and
            (>= 0.4 (device_get_position ext_cave_hunter_lift))
            (<= 0.25 (device_get_position ext_cave_hunter_lift))
            (= 1 (m_o_shaft_hunter_level_dest))
        )
        (begin
            (if (volume_test_object override_shaft_elev_bot (player0))
                (damage_object "cmt\globals\evolved\damage_effects\guaranteed_death" (player0))
            )
            (if (volume_test_object override_shaft_elev_bot (player1))
                (damage_object "cmt\globals\evolved\damage_effects\guaranteed_death" (player1))
            )
        )
    )

    ;; Check the next actor on the next frame
    (set m_o_shaft_elev_rescue_idx (+ 1 m_o_shaft_elev_rescue_idx))

    ;; Basically an arbitrary check rate
    (sleep 10) 
)

(global boolean m_o_shaft_elev_automig_start false)
(script continuous m_o_shaft_elev_automig
    (sleep_until m_o_shaft_elev_automig_start 1)

    ;; If Hunters want to be on L1 and all players are on or approaching L2, send them up
    (if
        (and
            (not (m_o_shaft_hunters_1dead))
            (= 1 (m_o_shaft_hunter_level_dest))
            (or
                (volume_test_players_all override_shaft_elev_hall_top)
                (volume_test_players_all override_shaft_elev_fulltop)
                (and
                    (volume_test_players_any override_shaft_elev_hall_top)
                    (volume_test_players_any override_shaft_elev_fulltop)
                )
            )
        )
        (begin
            (print_debug "m_o_shaft_elev_automig: hunters at L1 / players at L2, sending hunters up")
            (m_o_shaft_hunters_set_dest_l2)
        )
    )

    ;; If Hunters want to be on L2 and all players are on or approaching L1, send them down
    (if
        (and
            (not (m_o_shaft_hunters_1dead))
            (= 2 (m_o_shaft_hunter_level_dest))
            (or
                (volume_test_players_all override_shaft_elev_hall_bot)
                (volume_test_players_all override_shaft_elev_fullbot)
                (and
                    (volume_test_players_any override_shaft_elev_hall_bot)
                    (volume_test_players_any override_shaft_elev_fullbot)
                )
            )
        )
        (begin
            (print_debug "m_o_shaft_elev_automig: hunters at L2 / players at L1, sending hunters down")
            (m_o_shaft_hunters_set_dest_l1)
        )
    )

    ;; Don't do auto-migration if the hunters are in transit. It causes too many problems.
    (sleep_until (= (m_o_shaft_hunter_level_curr) (m_o_shaft_hunter_level_dest)) 1)

    ;; If all players are newly in the hall
    (if
        (and
            (not (m_o_shaft_player_hall_prev))
            (volume_test_players_all override_shaft_elev_hall)
        )
        (begin
            ;; Record the state change
            (print_debug "m_o_shaft_elev_automig: player newly in hall")
            (m_o_shaft_player_set_hall)

            ;; Have the Hunter pair back off and prepare to head up/down if they're still a pair
            (if (not (m_o_shaft_hunters_1dead))
                (begin
                    (print_debug "m_o_shaft_elev_automig: hunters backing off")
                    (ai_defend override_shaft_elev/hunters)
                    (ai_allow_charge override_shaft_elev/hunters false)

                    ;; We need to force lower-level hunters out of the hall
                    (print_debug "m_o_shaft_elev_automig: L1 hunters moving away")
                    (ai_command_list override_shaft_elev/hunter_guard ov_shaft_elev_hunter_backoff)
                    (ai_command_list override_shaft_elev/hunter_chase ov_shaft_elev_hunter_backoff)
                    (ai_command_list override_shaft_elev/hunter_guard_top ov_shaft_elev_hunter_backoff_t)
                    (ai_command_list override_shaft_elev/hunter_chase_top ov_shaft_elev_hunter_backoff_t)
                )
            )
        )
    )

    ;; If any player is newly _not_ in the hall
    (if
        (and
            (m_o_shaft_player_hall_prev)
            (not (volume_test_players_all override_shaft_elev_hall))
        )
        (begin
            ;; Record the state change
            (print_debug "m_o_shaft_elev_automig: player newly outside hall")
            (m_o_shaft_player_set_nonhall)

            ;; Have the Hunter pair resume their attack
            (if (not (m_o_shaft_hunters_1dead))
                (begin
                    (print_debug "m_o_shaft_elev_automig: hunters attacking")
                    (ai_attack override_shaft_elev/hunters)
                    (ai_allow_charge override_shaft_elev/hunters true)
                )
            )
        )
    )
    
    (cond
        (
            (volume_test_players_any override_shaft_elev_fullbot)
            
            ;; Grunts guard the bottom if anyone's there
            (print_debug "m_o_shaft_elev_automig: grunts taking bottom floor positions")
            (ai_migrate override_shaft_elev/grunts_main_top override_shaft_elev/grunts_guard_main)
            (ai_migrate override_shaft_elev/grunts_back_top override_shaft_elev/grunts_guard_back)
        )
        (
            (volume_test_players_any override_shaft_elev_fulltop)
            
            ;; Jackals guard the top if anyone's there
            (print_debug "m_o_shaft_elev_automig: jackalsquad taking top floor positions")
            (ai_migrate override_shaft_elev/jackals_guard_bottom override_shaft_elev/jackals_guard_top)
            (ai_migrate override_shaft_elev/jackals_forward_bottom override_shaft_elev/jackals_forward_top)
        )
    )    

    (cond
        (
            (volume_test_players_all override_shaft_elev_fullbot)
            
            ;; Jackals move to the bottom if nobody's up top
            (print_debug "m_o_shaft_elev_automig: jackalsquad taking bottom floor positions")
            (ai_migrate override_shaft_elev/jackals_guard_top override_shaft_elev/jackals_guard_bottom)
            (ai_migrate override_shaft_elev/jackals_forward_top override_shaft_elev/jackals_forward_bottom)
        )
        (
            (volume_test_players_all override_shaft_elev_fulltop)
            
            ;; Grunts move to the top if nobody's at the bottom
            (print_debug "m_o_shaft_elev_automig: grunts taking top floor positions")
            (ai_migrate override_shaft_elev/grunts_guard_main override_shaft_elev/grunts_main_top)
            (ai_migrate override_shaft_elev/grunts_guard_back override_shaft_elev/grunts_back_top)
            (ai_migrate override_shaft_elev/grunts_guard_right override_shaft_elev/grunts_back_top)
            
            ;; A lone Hunter survivor will also defend
            (print_debug "m_o_shaft_elev_automig: hunter survivor defending")
            (if (m_o_shaft_hunters_1dead)
                (ai_defend override_shaft_elev/hunters)
            )
        )
    )

    ;; Loop back 3 times per second (probably good enough)
    (sleep 10)
)

;; ---
;; Overall progression

;; DO NOT CHANGE THESE!
(global short s_e_init 0)
(global short s_e_active 1)
(global short s_e_guards_alert 2)
(global short s_e_hunters_active 3)
(global short s_e_major_progress 4)
(global short s_e_one_hunter_dead 5)
(global short s_e_both_hunters_dead 6)
(global short s_e_finished 7)

;; Sub-mission state
(global short m_o_shaft_elev_state s_e_init)

;; Common script to kill all the things that progression depends on
(script static void m_o_shaft_elev_sleep_all
    (sleep -1 m_o_shaft_elev_l1_to_l2)
    (sleep -1 m_o_shaft_elev_l2_to_l1)
    (sleep -1 m_o_shaft_elev_hunters)
    (sleep -1 m_o_shaft_elev_jackals)
    (sleep -1 m_o_shaft_elev_rescue_witch)
    (sleep -1 m_o_shaft_elev_automig)
)

(script dormant m_o_shaft_elev
    ;; Wait for a player to advance past the corridors
    (print_debug "m_override_shaft: waiting for player at cave entrance")
    (sleep_until (volume_test_players_any override_shaft_door))

    ;; Boss battle time
    (print_debug "m_o_shaft_elev: player at cave entrance, activated")
    (set m_o_shaft_elev_state s_e_active)
    
    ;; Set player effect for use by the elevator
    (player_effect_set_max_translation 0 0 0)
    (player_effect_set_max_rotation 0 0 0)
    (player_effect_set_max_vibrate 0.4 0.2)

    ;; Checkpoint at start of battle
    (game_save_no_timeout)

    ;; Place core guard dudez
    (ai_place override_shaft_elev/grunts_guard_main)
    (ai_place override_shaft_elev/grunts_guard_back)
    (ai_place override_shaft_elev/grunts_guard_right)

    ;; Enable management of the various other dudez
    (wake m_o_shaft_elev_hunters)
    (wake m_o_shaft_elev_jackals)

    ;; Force move-random behavior for these guys. Why do we have to do it here? Nobody knows.
    (ai_set_current_state override_shaft_elev/grunts_guard_back "move_random")
    (ai_set_current_state override_shaft_elev/grunts_guard_right "move_random")
    (ai_set_current_state override_shaft_elev/jackals_guard_top "move_random")

    ;; Wait until a player gets close to the elevator
    ;; ...or until someone alerts the guards
    (print_debug "m_o_shaft_elev: waiting for player to alert encounter")
    (sleep_until
        (or
            (volume_test_players_any override_shaft_elev_near_r)
            (volume_test_players_any override_shaft_elev_near_b)
            (volume_test_players_any override_shaft_elev_hall)
            (> (ai_status override_shaft_elev) 3)
        )
        10
    )

    ;; Signal the dude management systems that the time is now
    (print_debug "m_o_shaft_elev: player moving or guards alerted")
    (set m_o_shaft_elev_state s_e_guards_alert)
    (m_o_shaft_encounter_set_alert)

    ;; Wait until a player gets close to the elevator
    ;; ...or until someone pops most of the guards
    (print_debug "m_o_shaft_elev: waiting to activate hunters")
    (sleep_until
        (or
            (volume_test_players_any override_shaft_elev_near_r)
            (volume_test_players_any override_shaft_elev_near_b)
            (volume_test_players_any override_shaft_elev_hall)
            (and
                (< (ai_living_count override_shaft_elev/grunts_guard_main) 2)
                (< (ai_living_count override_shaft_elev/grunts_guard_back) 2)
                (< (ai_living_count override_shaft_elev/grunts_guard_right) 2)
            )
        )
        10
    )

    ;; Activate auto-migration, save a checkpoint, and turn on the glorious music
    (print_debug "m_o_shaft_elev: player moving or guards mostly dead; hunters going into action")
    (set m_o_shaft_elev_state s_e_hunters_active)
    (set m_o_shaft_elev_rescue_start true)
    (set m_o_shaft_elev_automig_start true)
    (game_save_no_timeout)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_06_security")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07_hunters")

    ;; Here they come
    (m_o_shaft_hunters_set_active)

    ;; Pull back the guards
    (print_debug "m_o_shaft_elev: guards going on defensive")
    (ai_defend override_shaft_elev/grunts_guard_main)
    (ai_defend override_shaft_elev/grunts_guard_back)
    (ai_defend override_shaft_elev/grunts_guard_right)

    ;; Wait until a Hunter dies or a player makes a move for the hallway.
    (print_debug "m_o_shaft_elev: waiting for major progress")
    (sleep_until
        (or
            (m_o_shaft_hunters_1dead)
            (volume_test_players_any override_shaft_elev_hall_bot)
        )
    )

    ;; Either way, this is a landmark occasion.
    (print_debug "m_o_shaft_elev: major progress achieved")
    (set m_o_shaft_elev_state s_e_major_progress)
    (game_save_no_timeout)

    ;; Now we wait for a Hunter to die for real.
    (print_debug "m_o_shaft_elev: awaiting hunter death")
    (sleep_until (m_o_shaft_hunters_1dead))

    ;; This, too, is a landmark occasion.
    (print_debug "m_o_shaft_elev: a hunter was killed")
    (set m_o_shaft_elev_state s_e_one_hunter_dead)
    (game_save_no_timeout)
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07_hunters")

    ;; Wait until both Hunters are dead
    (print_debug "m_o_shaft_elev: awaiting total hunter death")
    (sleep_until (m_o_shaft_hunters_2dead))

    ;; You've done it. You've really, really done it
    (print_debug "m_o_shaft_elev: both hunters dead")
    (set m_o_shaft_elev_state s_e_both_hunters_dead)
    (game_save_no_timeout)

    ;; We have no use for dude management anymore. Make sure nobody goes braindead by mistake.
    ;; If any guards remain, they can attack again.
    (print_debug "m_o_shaft_elev: deactivating management scripts and making remaining guards attack")
    (m_o_shaft_elev_sleep_all)
    (ai_command_list_advance override_shaft_elev/jackals)
    (ai_braindead override_shaft_elev/jackals_forward_top false)
    (ai_braindead override_shaft_elev/jackals_forward_bottom false)
    (ai_attack override_shaft_elev/grunts_guard_main)
    (ai_attack override_shaft_elev/grunts_guard_back)
    (ai_attack override_shaft_elev/grunts_guard_right)

    ;; Wait a teensy bit to kill the music & make everyone realize it
    (sleep (random_range 30 90))
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07_hunters")

    ;; Only turn on the mysterious choir if the players haven't already unlocked security
    ;; (This covers a case where they skip the Hunters, hit the unlock, then kill them on the way back)
    (if (not mission_security_unlocked)
        (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07a_hunters_end")
    )

    ;; "Wait until room is graveyard, solemn and silent if not for the screaming and sobbing of the slain soldiers' souls,
    ;; skewering the senses with the shrill, screeching songs of their senseless sacrifice and"
    ;; (- dafi, ca. 2012 - 2013)
    (print_debug "m_o_shaft_elev: awaiting total death")
    (sleep_until
        (= (ai_living_count override_shaft_elev) 0)
    )

    ;; Save why not. You're a hero.
    (print_debug "m_o_shaft_elev: all units dead")
    (set m_o_shaft_elev_state s_e_finished)
    (game_save_no_timeout)
)

;; ---
;; SERVER ROOM
;; ---

;; Migration for server room
(global boolean m_o_shaft_server_updater_start false)
(script continuous m_o_shaft_server_updater
    (sleep_until m_o_shaft_server_updater_start 1)
    
    (cond
        (
            (volume_test_players_all override_shaft_server_a)
            
            (ai_migrate override_shaft_server/elites override_shaft_server/elites_b)
            (ai_migrate override_shaft_server/jackals override_shaft_server/jackals_f)
            (ai_migrate override_shaft_server/pester_grunts override_shaft_server/pester_a)
            (ai_migrate override_shaft_server/guard_grunts override_shaft_server/guard_front)
        )
        (
            (volume_test_players_all override_shaft_server_b)
            
            (ai_migrate override_shaft_server/elites override_shaft_server/elites_g)
            (ai_migrate override_shaft_server/jackals override_shaft_server/jackals_b)
            (ai_migrate override_shaft_server/pester_grunts override_shaft_server/pester_b)
            (ai_migrate override_shaft_server/guard_grunts override_shaft_server/guard_back)
        )
        (
            (volume_test_players_all override_shaft_server_c)
            
            (ai_migrate override_shaft_server/elites override_shaft_server/elites_f)
            (ai_migrate override_shaft_server/jackals override_shaft_server/jackals_c)
            (ai_migrate override_shaft_server/pester_grunts override_shaft_server/pester_c)
            (ai_migrate override_shaft_server/guard_grunts override_shaft_server/guard_back)
        )
        (
            (volume_test_players_all override_shaft_server_d)
            
            (ai_migrate override_shaft_server/elites override_shaft_server/elites_c)
            (ai_migrate override_shaft_server/jackals override_shaft_server/jackals_g)
            (ai_migrate override_shaft_server/pester_grunts override_shaft_server/pester_d)
            (ai_migrate override_shaft_server/guard_grunts override_shaft_server/guard_front)
        )
        (
            ;; CO-OP: If co-op players are scattered, move to a generic squad and let the AI figure it out
            (game_is_cooperative)
            
            (ai_migrate override_shaft_server/elites override_shaft_server/elites_all)
            (ai_migrate override_shaft_server/jackals override_shaft_server/jackals_all)
            (ai_migrate override_shaft_server/pester_grunts override_shaft_server/pester_all)
            (ai_migrate override_shaft_server/guard_grunts override_shaft_server/guard_all)
        )
    )

    (sleep 15)
)

(script dormant m_o_shaft_server
    (print_debug "m_o_shaft_server: awake")

    ;; Place AI
    ;; Special stealth for the special difficulty
    (print_debug "m_o_shaft_server: spawning AI")
    (if (game_is_easy)
        (ai_place override_shaft_server_easy)
        (ai_place override_shaft_server)
    )

    ;; Wait for a player to approach
    (print_debug "m_o_shaft_server: waiting for player to approach servers")
    (sleep_until (volume_test_players_any override_shaft_server_a) 1)

    ;; Uou're in the thick of it now, pal
    (print_debug "m_o_shaft_server: player approached servers")
    (game_save_no_timeout)

    ;; Wait for a player to alert guards (or use extreme stealth strats)
    (print_debug "m_o_shaft_server: waiting for player to alert guards or slip away")
    (sleep_until
        (or
            (< 4 (ai_status override_shaft_server))
            (volume_test_players_any override_shaft_transition)
        )
    )

    ;; Once the player has made it past, turn on server updates
    (print_debug "m_o_shaft_server: player alerted guards")
    (set m_o_shaft_server_updater_start true)

    ;; Wait for players to fuck them up or someone to move on
    (print_debug "m_o_shaft_server: waiting for completion")
    (sleep_until
        (or
            (= 0 (ai_living_count override_shaft_server))
            (volume_test_players_any override_shaft_transition)
        )
    )

    ;; All done
    (print_debug "m_o_shaft_server: server finished")
    (sleep -1 m_o_shaft_server_updater)

    ;; Give the players a treat
    (game_save_no_timeout)
)

;; ---
;; SHAFT B MAIN
;; ---

;; DO NOT CHANGE THESE!
(global short s_init 0)
(global short s_active 1)
(global short s_sv_done 2)
(global short s_corridor 3)
(global short s_control_approached 4)
(global short s_control_reached 5)
(global short s_control_deactivated 6)
(global short s_finished 7)

;; Sub-mission state
(global short m_override_shaft_state s_init)

(script dormant m_override_shaft
    (print_debug "m_override_shaft: awake")

    ;; Wait for a player to enter
    (print_debug "m_override_shaft: wait for the player to enter building")
    (sleep_until
        (volume_test_players_any override_shaft_server_entrance)
        10
    )

    ;; You did it. The first step in a grand journey
    (print_debug "m_override_shaft: player entered the building")
    (set m_override_shaft_state s_active)

    ;; Collect garbage and save the game, why not
    (garbage_collect_now)
    (game_save_no_timeout)

    ;; Turn on the server enemies, who will protect the servers even to their dying breaths
    (wake m_o_shaft_server)

    ;; Start music
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_06_security")

    ;; Wait for a player to make a mess of the whole situation
    (print_debug "m_override_shaft: waiting for server completion")
    (sleep_until
        (or
            (= 0 (ai_living_count override_shaft_server))
            (volume_test_players_any override_shaft_transition)
        )
        10
    )

    ;; Server room done. Set up the corridor and switch to the halfway-point music cue.
    (print_debug "m_override_shaft: server room done, setting up corridor")
    (set m_override_shaft_state s_sv_done)
    (ai_place override_shaft_corridor)
    (music_alt "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_06_security")

    ;; Wait for a player to enter the corridor
    (print_debug "m_override_shaft: waiting for player to enter corridor")
    (sleep_until (volume_test_players_any override_shaft_entrance) 10)

    ;; Players are dealing with corridor enemies
    (print_debug "m_override_shaft: players at corridor")
    (set m_override_shaft_state s_corridor)

    ;; Stop going away guy! We need you more than ever, even though you're dead
    ;; (Basically this is a critical supply drop for the boss fight, and it had a habit of de-spawning
    ;; before the fight started. so we need to make sure it's here.)
    (object_create_anew_containing elev_dude)

    ;; Wake elevator battle before the player arrives there
    (wake m_o_shaft_elev)

    ;; Wait for a player to approach elevator
    (print_debug "m_override_shaft: awaiting player at control elevator")
    (sleep_until (volume_test_players_any override_ufo_elev_bot))

    ;; A player is at the elevator. Kill any pre-approach music still playing.
    (print_debug "m_override_shaft: player at control elevator")
    (set m_override_shaft_state s_control_approached)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_06_security")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07_hunters")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07a_hunters_end")

    ;; Wait until a player activates security device
    ;; (We use the device specifically rather than the global mission flag so we can precisely time the music shutoff)
    (print_debug "m_override_shaft: awaiting security deactivation")
    (sleep_until (= 1 (device_group_get position_ext_sec_security_holo)) 1)

    ;; Security deactivated. Kill the security-approach music that may have been queued up.
    ;; (If it doesn't break the loop end should line up w/ the cutscene)
    (print_debug "m_override_shaft: security deactivated")
    (set m_override_shaft_state s_control_deactivated)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07a_hunters_end")

    ;; Done
    (print_debug "m_override_shaft: finished")
    (set m_override_shaft_state s_finished)
)

(script dormant m_override_shaft_clean
    (print_debug "m_override_shaft_clean: awake")

    ;; Turn off all scripts, stop all music, and erase all dudes.
    ;; This is dude erasure! Unbelievable in 2021
    (sleep -1 m_o_shaft_server_updater)
    (sleep -1 m_o_shaft_server)
    (m_o_shaft_elev_sleep_all)
    (sleep -1 m_o_shaft_elev)
    (sleep -1 m_override_shaft)
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_06_security")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07_hunters")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_07a_hunters_end")
    (ai_erase override_shaft_server)
    (ai_erase override_shaft_corridor)
    (ai_erase override_shaft_elev)
)

(script dormant m_override_shaft_return
    (print_debug "m_override_shaft_return: awake")

    ;; If player let a Hunter live
    (print_debug "m_override_shaft_return: checking for living hunters")
    (if (!= 0 (ai_living_count override_shaft_elev/hunters))
        (begin
            ;; For safety, we can't arrange for this to happen until we're in the cave BSP
            (print_debug "m_override_shaft_return: hunters still alive, they will wait for the player after the BSP switch")
            (sleep_until (= bsp_index_ext_cave (structure_bsp_index)))

            ;; BSP switched, arrange the scene:
            ;; - Send everyone to the top
            ;; - Advance command lists, otherwise the Hunters get stuck
            ;; - Move elevator too so people don't get suspicious
            (print_debug "m_override_shaft_return: waiting for BSP switch")
            (ai_command_list_advance override_shaft_elev)
            (ai_migrate override_shaft_elev/hunter_guard override_shaft_elev/hunter_guard_top)
            (ai_migrate override_shaft_elev/hunter_chase override_shaft_elev/hunter_chase_top)
            (ai_command_list override_shaft_elev/hunter_guard_top return_shaft_elev_hunter_1)
            (ai_command_list override_shaft_elev/hunter_chase_top return_shaft_elev_hunter_2)
            (ai_command_list override_shaft_elev/hunter_remnant return_shaft_elev_hunter_2)
            (m_o_shaft_hunters_set_curr_l2)
            (m_o_shaft_hunters_set_dest_l2)
            (device_set_position_immediate ext_cave_hunter_lift 1)

            ;; Wait for a player to approach, to grant magic sight
            ;; HACK: This should be a trigger volume, but we are out of trigger volumes.
            (sleep_until (> 2 (objects_distance_to_flag (players) i_should_be_a_trigger_volume)))
            (ai_magically_see_players override_shaft_elev)
        )
    )
)

;; ---
;; Mission hooks

(script static void m_override_shaft_startup
    (print_debug "m_override_shaft_startup")
    (wake m_override_shaft)
)

(script static void m_override_shaft_cleanup
    (print_debug "m_override_shaft_cleanup")
    (wake m_override_shaft_clean)
)

(script static void m_override_shaft_mark_return
    (print_debug "m_override_shaft_mark_return")
    (wake m_override_shaft_return)
)
