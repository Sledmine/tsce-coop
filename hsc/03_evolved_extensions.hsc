;; 03_evolved_extensions.hsc
;; Modular extensions specific to Evolved content
;; ---

;; --- EXTENSION: X_HOG ---
;; Warthog healthpacks
;; REQUIRES: None
;; 
;; Allows Warthog drivers to access up to two (2) free health restores per Warthog, represented
;; by two healthpacks in the model.
;;
;; This was a lot less complicated in Open Sauce, but it's a consequential feature for Evolved
;; gameplay, so it needed to be ported somehow.
;;
;; This is an Evolved-specific extension because several assumptions are made. If any of these are untrue,
;; this extension will break, or be useless:
;;   1. Non-regenerating player health meaningfully exists.
;;   2. There's a Warthog, using TSC:E's model, or an equivalent with removable healthpack permutations.
;;   3. All Warthogs carry exactly 2 virtual healthpacks.
;;   4. There are no more than 16 Warthogs in the scenario.
;;   5. The only possible Warthog passengers are players, and Marines.
;;   6. Player units have 80 shields & 80 health.
;;   7. Marine majors are the highest Marine rank, and have 50 shields & 100 health.
;;   8. Health packs use stock sounds & FX.

;; Vitality info
;; We need this because HCE can't dynamically report the max vitality of units
;; We need max vitality because HCE can't set unit vitality in a normalized 0-1 range

;; Player base vitality (read-only)
(global real X_HOG_max_health_player 80)
(global real X_HOG_max_shield_player 80)

;; Marine base vitality (read-only)
;; NOTE: We can't currently distinguish Marine minors / majors, so use the majors' health value
(global real X_HOG_max_health_marine 100)
(global real X_HOG_max_shield_marine 50)

(script static real X_HOG_get_marine_health
    (cond
        (
            (= (game_difficulty_get_real) normal)
            X_HOG_max_health_marine
        )
        (
            (= (game_difficulty_get_real) hard)
            (* X_HOG_max_health_marine 1.2)
        )
        (
            (= (game_difficulty_get_real) impossible)
            (* X_HOG_max_health_marine 1.4)
        )
        (
            (= (game_difficulty_get_real) easy)
            (* X_HOG_max_health_marine 1.4)
        )
    )
)

(script static real X_HOG_get_marine_shield
    (cond
        (
            (= (game_difficulty_get_real) normal)
            X_HOG_max_shield_marine
        )
        (
            (= (game_difficulty_get_real) hard)
            (* X_HOG_max_shield_marine 1.2)
        )
        (
            (= (game_difficulty_get_real) impossible)
            (* X_HOG_max_shield_marine 1.4)
        )
        (
            (= (game_difficulty_get_real) easy)
            (* X_HOG_max_shield_marine 1.4)
        )
    )
)

;; Warthog state management

;; You won't see hacks of this caliber on halo maps dot org!! Store all hogs' healthpack state in a bit field.
;; Assume exactly 2 health packs per hog. This lets us avoid things like "recursion" and "stack overflow."
(global long X_HOG_state 0)

(script static long (X_HOG_get_bits (long healthpack_index))
    ;; let health_pack_count = 2
    ;; let bit_offset = curr_hog_index * health_pack_count
    ;; let shifted_to_origin = X_HOG_state >> bit_offset
    ;; return shifted_to_origin & (0b11)
    (bitwise_and
        (bitwise_right_shift X_HOG_state (* healthpack_index 2))
        3
    )
)

(script static long (X_HOG_get_consumed (long healthpack_index))
    ;; match (X_HOG_get_bits) with
    ;; | 0b11 -> 2 health packs
    ;; | 0b01 -> 1 health pack
    ;; | _ -> 0 health packs
    (cond
        (
            (= (X_HOG_get_bits healthpack_index) 3)
            2
        )
        (
            (= (X_HOG_get_bits healthpack_index) 1)
            1
        )
        (
            true
            0
        )
    )
)

(script static void (X_HOG_consume (long healthpack_index))
    ;; let health_pack_count = 2
    ;; let bit_offset = (curr_hog_index * health_pack_count)
    ;; let new_healthpack_state =
    ;;     match (X_HOG_get_bits) with
    ;;    | 0b00 -> old_healthpack_state | (0b01 << bit_offset)
    ;;    | 0b01 -> old_healthpack_state | (0b11 << bit_offset)
    (cond
        (
            (= (X_HOG_get_bits healthpack_index) 0)
            (set X_HOG_state
                (bitwise_or
                    X_HOG_state
                    (bitwise_left_shift 1 (* healthpack_index 2))
                )
            )
        )
        (
            (= (X_HOG_get_bits healthpack_index) 1)
            (set X_HOG_state
                (bitwise_or
                    X_HOG_state
                    (bitwise_left_shift 3 (* healthpack_index 2))
                )
            )
        )
    )
)

;; Warthog testing & application

;; Internal helper for stack size & conciseness
(global unit X_HOG_rider none)

(script static boolean (X_HOG_rider_can_heal (vehicle hog) (short rider_index))
    (set X_HOG_rider (unit (list_get (vehicle_riders hog) rider_index)))
    (and
        (!= none X_HOG_rider)
        (> 1.0 (unit_get_health X_HOG_rider))
    )
)

(script static void (X_HOG_rider_heal (vehicle hog) (short rider_index))
    (set X_HOG_rider (unit (list_get (vehicle_riders hog) rider_index)))
    
    ;; Figure out if this is a player or a Marine
    ;; CO-OP: If more players are added, test for all of them here
    (if (or
            (= (player0) X_HOG_rider)
            (= (player1) X_HOG_rider)
        )
        ;; It's a player, restore player health & play the appropriate FX
        (begin
            (unit_set_current_vitality X_HOG_rider
                X_HOG_max_health_player
                (* (unit_get_shield X_HOG_rider) X_HOG_max_shield_player)
            )
            (damage_object "cmt\globals\_shared\damage_effects\fx_health_regen_flash" X_HOG_rider)
            (sound_impulse_start "sound\sfx\ui\pickup_health" X_HOG_rider 1)
        )
        ;; It's a Marine, just restore Marine health
        (unit_set_current_vitality X_HOG_rider
            (X_HOG_get_marine_health)
            (* (unit_get_shield X_HOG_rider) (X_HOG_get_marine_shield))
        )
    )
)

(script static void (X_HOG_test (vehicle hog) (long index))
    ;; Has someone toggled this hog's flashlight?
    (if (!= 0 (unit_get_current_flashlight_state hog))
        (begin
            ;; Reset the flashlight state
            (unit_set_desired_flashlight_state hog 0)
            
            ;; Does this hog have packs left, and at least one rider in need of healing?
            (if (and
                    (> 2 (X_HOG_get_consumed index))
                    (or
                        (X_HOG_rider_can_heal hog 0)
                        (X_HOG_rider_can_heal hog 1)
                        (X_HOG_rider_can_heal hog 2)
                    )
                )
                (begin
                    ;; Heal all riders
                    (X_HOG_rider_heal hog 0)
                    (X_HOG_rider_heal hog 1)
                    (X_HOG_rider_heal hog 2)
                    
                    ;; Record the pack as consumed
                    (X_HOG_consume index)
                    
                    ;; Set the appropriate model permutation
                    (if (= 1 (X_HOG_get_consumed index))
                        (object_set_permutation hog "healthpacks" "healthpack_01")
                        (object_set_permutation hog "healthpacks" "healthpack_02")
                    )
                )
                ;; Can't heal, play the failure sound
                (sound_impulse_start "sound\sfx\ui\flag_failure" (list_get (vehicle_riders hog) 0) 1)
            )
        )
    )
)

;; --- EXTENSION: X_WST ---
;; Weapon stat tracker
;; REQUIRES: X_DBG, X_WPN
;;
;; This was a development utility for tracking how long player0 was using each core weapon.
;; We don't really have a use for it now, but it was helpful for iterating on design, so why not
;; preserve it for posterity. It'll only start updating if X_DBG_enabled (debug mode is on).
;;
;; This uses the magic f0 - f4 variables so that usage tracking persists between checkpoints.
;; Since that's not enough variables for all our weapons, each variable tracks two weapons at
;; once, by designating a "low" (0+) and "high" (10000+) range, extracted upon read with a bit
;; of math trickery.
;;
;; f5 is not used so that it can remain reserved for other purposes.

(script continuous X_WST_update
    (if (not X_DBG_enabled)
        (sleep -1)
    )
    
    (if (not (game_all_quiet))
        (begin
            (if (or
                    (= X_WPN_id_primary_player0 "ar")
                    (= X_WPN_id_primary_player0 "argl")
                )
                (set f0 (+ f0 1))
            )
            (if (= X_WPN_id_primary_player0 "br")
                (set f0 (+ f0 10000))
            )
            (if (= X_WPN_id_primary_player0 "cbn")
                (set f1 (+ f1 1))
            )
            (if (= X_WPN_id_primary_player0 "ne")
                (set f1 (+ f1 10000))
            )
            (if (= X_WPN_id_primary_player0 "hp")
                (set f2 (+ f2 1))
            )
            (if (= X_WPN_id_primary_player0 "pp")
                (set f2 (+ f2 10000))
            )
            (if (= X_WPN_id_primary_player0 "pr")
                (set f3 (+ f3 1))
            )
            (if (= X_WPN_id_primary_player0 "shrd")
                (set f3 (+ f3 10000))
            )
            (if (= X_WPN_id_primary_player0 "spkr")
                (set f4 (+ f4 1))
            )
            (if (or
                    (= X_WPN_id_primary_player0 "bs")
                    (= X_WPN_id_primary_player0 "rl")
                    (= X_WPN_id_primary_player0 "sg")
                    (= X_WPN_id_primary_player0 "sr")
                )
                (set f4 (+ f4 10000))
            )
        )
    )
)

(script static void X_WST_reset
    (set f0 0)
    (set f1 0)
    (set f2 0)
    (set f3 0)
    (set f4 0)
)

(script static void (X_WST_print_low (string name) (real var))
    (print name)
    (inspect (- var (* (/ var 10000) 10000)))
)

(script static void (X_WST_print_high (string name) (real var))
    (print name)
    (inspect (/ var 10000))
)

(script static void X_WST_print
    (print "--------------------")
    (print "Weapon usage time (seconds):")
    
    (X_WST_print_low "Assault Rifle" f0)
    (X_WST_print_high "Battle Rifle" f0)
    (X_WST_print_low "Auto-Carbine" f1)
    (X_WST_print_high "Needler" f1)
    (X_WST_print_low "Pistol" f2)
    (X_WST_print_high "Plasma Pistol" f2)
    (X_WST_print_low "Plasma Rifle" f3)
    (X_WST_print_high "Shredder" f3)
    (X_WST_print_low "Spiker" f4)
    (X_WST_print_high "Power Weapons" f4)
)