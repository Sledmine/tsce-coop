;; 04_b30_revamp.hsc
;; Scripts and helpers specific to the b30_revamp scenario, but independent of the mission state
;; ---

;; ---
;; BSP indices, for convenience & clarity
;; DO NOT CHANGE THESE!

(global short bsp_index_empty 0)
(global short bsp_index_ext_lz 1)
(global short bsp_index_ext_capp 2)
(global short bsp_index_ext_cart 2)
(global short bsp_index_ext_sapp 3)
(global short bsp_index_ext_pool 4)
(global short bsp_index_ext_pit 4)
(global short bsp_index_ext_bridge 5)
(global short bsp_index_ext_ufo 4)
(global short bsp_index_ext_crash 5)
(global short bsp_index_ext_cave 6)
(global short bsp_index_ext_lid 3)
(global short bsp_index_int_sec_servers 7)
(global short bsp_index_int_shaft_a 8)
(global short bsp_index_int_shaft_b 9)
(global short bsp_index_int_shaft_c 10)
(global short bsp_index_debug_room 11)

;; ---
;; X_CAR implementation

(script static void (X_CAR_test_list (unit my_unit))
    ;; Ghosts
    (evolved_test_ghost ext_beach_1_ghost_1 my_unit)
    (evolved_test_ghost ext_beach_1_ghost_2 my_unit)
    (evolved_test_ghost ext_canyon_ghost my_unit)
    (evolved_test_ghost ext_canyon_bonus_ghost my_unit)
    (evolved_test_ghost ext_cart_bonus_ghost_1 my_unit)
    (evolved_test_ghost ext_cart_bonus_ghost_2 my_unit)
    (evolved_test_ghost ext_beach_2_ghost_1 my_unit)
    (evolved_test_ghost ext_beach_2_ghost_2 my_unit)
    (evolved_test_ghost ext_beach_2_bonus_ghost my_unit)
    (evolved_test_ghost ext_lid_bonus_ghost_1 my_unit)
    (evolved_test_ghost ext_cave_bonus_ghost_1 my_unit)
    (evolved_test_ghost ext_cave_bonus_ghost_2 my_unit)

    ;; Hogs
    (evolved_test_hog ext_drop_hog my_unit)
    (evolved_test_hog override_cliffs_dump_hog my_unit)
    (evolved_test_hog return_downed_dump_hog my_unit)
    (evolved_test_rhog ext_drop_rhog my_unit)

    ;; Shades
    (evolved_test_shade lz_turret_high my_unit)
    (evolved_test_shade lz_turret_low my_unit)
    (evolved_test_shade ext_beach_1_turret_camp my_unit)
    (evolved_test_shade ext_beach_1_turret_far my_unit)
    (evolved_test_shade ext_beach_1_exit_turret_1 my_unit)
    (evolved_test_shade ext_beach_1_exit_turret_2 my_unit)
    (evolved_test_shade return_cart_turret_left my_unit)
    (evolved_test_shade return_cart_turret_right my_unit)
    (evolved_test_shade ext_cart_turret_front my_unit)
    (evolved_test_shade sec_turret_low my_unit)
    (evolved_test_shade sec_turret_high my_unit)
    (evolved_test_shade bridge_turret_1 my_unit)
    (evolved_test_shade return_downed_turret my_unit)
    (evolved_test_shade ext_cave_turret_1 my_unit)
    (evolved_test_shade return_cliffs_turret my_unit)

    ;; Wraiths
    (evolved_test_wraith coolmode_wraith my_unit)
    (evolved_test_wraith return_cart_wraith_1 my_unit)
    (evolved_test_wraith return_cart_wraith_2 my_unit)
    (evolved_test_wraith return_downed_wraith my_unit)
    (evolved_test_wraith return_beach_2_wraith my_unit)
)

;; ---
;; X_HOG implementation

(script continuous b30_revamp_hog_tests
    (X_HOG_test ext_drop_hog 0)
    (X_HOG_test override_cliffs_dump_hog 1)
    (X_HOG_test return_downed_dump_hog 2)
    (X_HOG_test ext_drop_rhog 3)
)

;; ---
;; AI vehicle passenger migration
;; If we don't do these things, Marines in your vehicles freeze and go braindead, and Elites get on your Wraith's wings

(global short ai_vmig_bsp_index -1)

(script continuous ai_vmig_bsp
    ;; Wait for the bsp to change
    (print_debug "ai_vmig_bsp: awaiting BSP change")
    (sleep_until (!= ai_vmig_bsp_index (structure_bsp_index)) 1)

    ;; Follow me, men!!!!
    (print_debug "ai_vmig_bsp: BSP changed, initializing migration")
    (if X_DBG_enabled
        (begin
            (inspect (structure_bsp_index))
            (inspect ai_vmig_bsp_index)
        )
    )

    ;; This seems to make things more stable
    (print_debug "ai_vmig_bsp: (skipping frame to allow ai reconnection)")
    (skip_frame)

    ;; Update the current bsp index
    (print_debug "ai_vmig_bsp: updating migration targets for new bsp")
    (set ai_vmig_bsp_index (structure_bsp_index))

    ;; Update the various AI references
    ;;
    ;; Note that we won't migrate the cartographer Wraiths, because they aren't accessible to the covenant outside of
    ;; the encounter that initially spawns them.
    ;;
    ;; We also won't migrate the coolmode wraith because it's not accessible to covenant ever.
    (cond
        (
            (= ai_vmig_bsp_index bsp_index_ext_lz)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_lz")
            (set X_VMG_target marines_ext_lz-capp/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_ext_cart)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_cart")
            (set X_VMG_target marines_ext_capp-cart/a)

            ;; update which encounter the Wraiths belong to
            (print_debug "ai_vmig_bsp: updating wraith encounters for bsp_index_ext_cart")
            (ai_vehicle_encounter return_downed_wraith r_downed_wrth_ext_capp-cart/a)
            (ai_vehicle_encounter return_beach_2_wraith r_beach_2_wrth_ext_capp-cart/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_ext_sapp)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_sapp")
            (set X_VMG_target marines_ext_cart-sapp/a)

            ;; Update which encounter the Wraiths belong to
            (print_debug "ai_vmig_bsp: updating wraith encounters for bsp_index_ext_sapp")
            (ai_vehicle_encounter return_downed_wraith r_downed_wrth_ext_cart-sapp/a)
            (ai_vehicle_encounter return_beach_2_wraith r_beach_2_wrth_ext_cart-sapp/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_ext_pool)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_sapp")
            (set X_VMG_target marines_ext_sapp-sec/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_ext_bridge)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_bridge")
            (set X_VMG_target marines_ext_sec-cave/a)

            ;; Update which encounter the Wraiths belong to
            (print_debug "ai_vmig_bsp: updating wraith encounters for bsp_index_ext_bridge")
            (ai_vehicle_encounter return_downed_wraith r_downed_wrth_ext_sec-cave/a)
            (ai_vehicle_encounter return_beach_2_wraith r_beach_2_wrth_ext_sec-cave/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_ext_cave)

            ;; update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_ext_cave")
            (set X_VMG_target marines_ext_cave/a)

            ;; Update which encounter the Wraiths belong to
            (print_debug "ai_vmig_bsp: updating wraith encounters for bsp_index_ext_cave")
            (ai_vehicle_encounter return_downed_wraith r_downed_wrth_ext_cave/a)
            (ai_vehicle_encounter return_beach_2_wraith r_beach_2_wrth_ext_cave/a)
        )
        (
            (= ai_vmig_bsp_index bsp_index_int_shaft_a)

            ;; Update Marine destination
            (print_debug "ai_vmig_bsp: updating marine target for bsp_index_int_shaft_a")
            (set X_VMG_target marines_int_shaft_a/a)
        )
    )

    ;; This also seems to improve stability...?
    (print_debug "ai_vmig_bsp: reconnecting AI")
    (skip_frame)
    (ai_reconnect)
)

(script static void (setup_ai_vmig_target (ai target))
    ;; The AI will follow the player
    (ai_follow_target_players target)
    (ai_follow_distance target 3)

    ;; The AI will automatically migrate to this encounter if needed
    (ai_automatic_migration_target target true)
)

(script startup b30r_mission_ai_vmig_startup
    (print_debug "b30r_mission_ai_vmig_startup")

    ;; Set up marine migration encounters
    (print_debug "b30r_mission_ai_vmig_startup: setting up marine migration targets")
    (setup_ai_vmig_target marines_ext_lz-capp)
    (setup_ai_vmig_target marines_ext_capp-cart)
    (setup_ai_vmig_target marines_ext_cart-sapp)
    (setup_ai_vmig_target marines_ext_sapp-sec)
    (setup_ai_vmig_target marines_ext_sec-cave)
    (setup_ai_vmig_target marines_ext_cave)
    (setup_ai_vmig_target marines_int_shaft_a)
)

;; ---
;; Ambient devices & AI

;; :(
(script continuous thumpers
    (device_set_position_immediate 3_lodvol_override_shaft_elev 0)
    (device_set_position 3_lodvol_override_shaft_elev 1)

    (sleep (random_range 180 600))

    (device_set_position_immediate 4_lodvol_override_shaft_elev 0)
    (device_set_position 4_lodvol_override_shaft_elev 1)

    (sleep (random_range 180 600))

    (device_set_position_immediate 5_lodvol_override_shaft_elev 0)
    (device_set_position 5_lodvol_override_shaft_elev 1)

    (sleep (random_range 180 600))
)

;; >:(
(script continuous set_pit_elev_sync
    (sleep_until (volume_test_players_any override_pit_elevator_top))
    (device_group_set position_ext_sec_pit_elevator 1)

    (sleep_until (volume_test_players_any override_pit_left))
    (device_group_set position_ext_sec_pit_elevator 0)
)

;; The fantastic doors
(script startup int_cart_unlock_classic
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_classc)))

    (device_one_sided_set int_shaft_c_classic_door_inner false)
    (device_one_sided_set int_shaft_c_classic_door_outer false)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_c_i true)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_c_o true)
    (device_group_set hack_int_shaft_c_doors_c_i 1)
    (device_group_set hack_int_shaft_c_doors_c_o 1)
)

(script startup int_cart_unlock_evolved
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_evolve)))

    (device_one_sided_set int_shaft_c_evolved_door_inner false)
    (device_one_sided_set int_shaft_c_evolved_door_outer false)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_e_i true)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_e_o true)
    (device_group_set hack_int_shaft_c_doors_e_i 1)
    (device_group_set hack_int_shaft_c_doors_e_o 1)
)

(script startup int_cart_unlock_brute
    (sleep_until (= 1 (device_group_get power_int_shaft_c_gen_brute)))

    (device_one_sided_set int_shaft_c_brute_door_l_inner false)
    (device_one_sided_set int_shaft_c_brute_door_l_outer false)
    (device_one_sided_set int_shaft_c_brute_door_r_inner false)
    (device_one_sided_set int_shaft_c_brute_door_r_outer false)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_b_l_i true)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_b_l_o true)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_b_r_i true)
    (device_group_change_only_once_more_set hack_int_shaft_c_doors_b_r_o true)
    (device_group_set hack_int_shaft_c_doors_b_l_i 1)
    (device_group_set hack_int_shaft_c_doors_b_l_o 1)
    (device_group_set hack_int_shaft_c_doors_b_r_i 1)
    (device_group_set hack_int_shaft_c_doors_b_r_o 1)
)

;; The unbelievable ring
(script continuous int_cart_holo_ring
    ;; Set cartographer power to (sum of generator power) / 3
    (device_group_set power_cartographer
        (/
            (+
                (device_group_get power_int_shaft_c_gen_brute)
                (device_group_get power_int_shaft_c_gen_evolve)
                (device_group_get power_int_shaft_c_gen_classc)
            )
            3
        )
    )

    ;; Toggle ring on full power - holoball gives way to full ring
    ;; We have to use a hack device group for power, because device_set_power is immediate and there is no non-immediate equivalent.
    (if (and
            (= 1 (device_group_get power_cartographer))
            (= 0 (device_group_get hack_int_shaft_c_holo_ring))
        )
        (begin
            (device_group_set hack_int_shaft_c_holo_ring 1)
            (device_set_position int_shaft_c_holo_glows 1)
        )
    )

    ;; Sync the ring's security segment color to the security hologram's state
    ;; NOTE: object_set_shield only works here because:
    ;; - The holo ring has a max shield value of 1, dodging the function's busted math.
    ;; - Even if this goes wrong, we're only intersested in "zero" or "not zero" values, for which this suffices.
    (object_set_shield int_shaft_c_holo_ring (device_group_get position_ext_sec_security_holo))
)

;; We need to spawn and de-spawn our finned little friends
(script startup fish
    (sleep_until (= bsp_index_int_shaft_b (structure_bsp_index)))
    (ai_place fish)
    (ai_disregard (ai_actors fish) true)
)

(script continuous fish2
    (sleep_until (= bsp_index_int_shaft_c (structure_bsp_index)))
    (ai_place fish2)
    (ai_disregard (ai_actors fish2) true)
    (sleep_until (!= bsp_index_int_shaft_c (structure_bsp_index)))
    (ai_erase fish2)
)

;; Secretly speed up the big elevator on the way back up
(script startup shaft_a_elev
    ;; Wait until the cartographer is on
    (sleep_until (= 1 (device_group_get power_cartographer)) 1)

    ;; Secretly replace the elevator object
    (object_destroy int_shaft_a_elevator)
    (object_create int_shaft_a_elevator_fast)
    
    ;; Secretly cycle the position to force the game to update the root bounding radius
    (device_group_set_immediate position_int_shaft_a_elevator 0)
    (device_group_set_immediate position_int_shaft_a_elevator 1)
)

;; ---
;; LOD volumes
;; The map quite literally has too many objects in it for its own good. We need to secretly spawn / de-spawn some
;; (e.g. devices, because they're always active regardless of BSP) to free up object slots, so that the map doesn't break.

;; halo_tag_test, meanwhile, will do extra checks & warn if trying to create already-extant objects.
;; Doing this constantly leads to unplayable hitching, so compensate by tracking which LOD volumes are
;; active, and only de/spawning objects if needed.
(global long b30r_lod_volumes_state 0)

(script static void (b30r_lod_volumes_check (trigger_volume volume) (string name_containing) (long state_index))
    (if (volume_test_players_any volume)
        (if (!= (bit_test b30r_lod_volumes_state state_index) 1)
            (begin
                (object_create_containing name_containing)
                (set b30r_lod_volumes_state (bit_toggle b30r_lod_volumes_state state_index true))
            )
        )
        (if (= (bit_test b30r_lod_volumes_state state_index) 1)
            (begin
                (object_destroy_containing name_containing)
                (set b30r_lod_volumes_state (bit_toggle b30r_lod_volumes_state state_index false))
            )
        )
    )
)

(script continuous b30r_lod_volumes
    (if (= bsp_index_ext_crash (structure_bsp_index))
        (if (!= (bit_test b30r_lod_volumes_state 1) 1)
            (begin
                (object_create_containing "holy shit")
                (set b30r_lod_volumes_state (bit_toggle b30r_lod_volumes_state 1 true))
            )
        )
        (if (= (bit_test b30r_lod_volumes_state 1) 1)
            (begin
                (object_destroy_containing "holy shit")
                (set b30r_lod_volumes_state (bit_toggle b30r_lod_volumes_state 1 false))
            )
        )
    )
    
    (b30r_lod_volumes_check lodvol_lz "lodvol_lz" 2)
    (b30r_lod_volumes_check lodvol_ext_beach_1 "lodvol_ext_beach_1" 3)
    (b30r_lod_volumes_check lodvol_ext_canyon "lodvol_ext_canyon" 4)
    (b30r_lod_volumes_check lodvol_ext_cart "lodvol_ext_cart" 5)
    (b30r_lod_volumes_check lodvol_override_cliffs_falls "lodvol_override_cliffs_falls" 6)
    (b30r_lod_volumes_check lodvol_override_cliffs_dmp "lodvol_override_cliffs_dmp" 7)
    (b30r_lod_volumes_check lodvol_override_pool "lodvol_override_pool" 8)
    (b30r_lod_volumes_check lodvol_return_falls "lodvol_return_falls" 9)
    (b30r_lod_volumes_check lodvol_override_shaft_elev "lodvol_override_shaft_elev" 10)
    (b30r_lod_volumes_check lodvol_int_hallways_water "lodvol_int_hallways_water" 11)
    (b30r_lod_volumes_check lodvol_int_hallways_cat "lodvol_int_hallways_cat" 12)
    (b30r_lod_volumes_check lodvol_int_hallways_lob "lodvol_int_hallways_lob" 13)
    (b30r_lod_volumes_check lodvol_int_hallways_mid "lodvol_int_hallways_mid" 14)
    (b30r_lod_volumes_check lodvol_cart "lodvol_cart" 15)
)

;; Turns off lod volumes, spawning all objects to compensate. Just `wake b30r_lod_volumes` to re-enable the system!
(script static void b30r_lod_volumes_disable
    (object_create_containing "lodvol_lz")
    (object_create_containing "lodvol_ext_beach_1")
    (object_create_containing "lodvol_ext_canyon")
    (object_create_containing "lodvol_override_cliffs_falls")
    (object_create_containing "lodvol_override_cliffs_dmp")
    (object_create_containing "lodvol_override_pool")
    (object_create_containing "lodvol_return_falls")
    (object_create_containing "lodvol_override_shaft_elev")
    (object_create_containing "lodvol_int_hallways_water")
    (object_create_containing "lodvol_int_hallways_cat")
    (object_create_containing "lodvol_int_hallways_lob")
    (object_create_containing "lodvol_int_hallways_mid")
    (object_create_containing "lodvol_cart")
)

;; ---
;; Murder witch
;; A malevolent witch who kills units that wander into the death volumes.
;; Even so, isn't this witch merciful in the end? That may be essential to the nature of witches in this world.

(script static void (b30r_murder_witch_unit_test (unit my_unit))
    (if
        (if
            (>= (structure_bsp_index) bsp_index_int_shaft_a)
            ;; checking for interior BSPs
            (or
                (volume_test_object int_shaft_a_death           my_unit)
                (volume_test_object int_shaft_b_elev_death      my_unit)
            )
            ;; checking for exterior BSPs
            (or
                (volume_test_object ext_a_cart_elev_death       my_unit)
                (volume_test_object ext_a_lz_elev_death         my_unit)
                (volume_test_object ext_b_underwater_death      my_unit)
                (volume_test_object ext_b_cliff_death           my_unit)
                (volume_test_object ext_b_cliff_nub_death       my_unit)
                (volume_test_object ext_c_cliff_death           my_unit)
                (volume_test_object ext_c_pit_elev_death        my_unit)
                (volume_test_object ext_c_ufo_elev_death        my_unit)
                (volume_test_object ext_e_cave_death            my_unit)
                (volume_test_object ext_e_cave_nub_death        my_unit)
                (volume_test_object ext_c_cliff_side_death      my_unit)
                (volume_test_object ext_e_cave_pool_death       my_unit)
            )
        )
        (unit_kill my_unit)
    )
)

(global short b30r_murder_witch_ai_idx 0)
(script static void (b30r_murder_witch_check_ai (ai my_ai))
    ;; Loop on the AI units until...
    (set b30r_murder_witch_ai_idx 0)
    (sleep_until
        ;; ...there are units to evaluate.
        (begin
            ;; Evalute the current unit index for death
            (b30r_murder_witch_unit_test (ai_actor my_ai b30r_murder_witch_ai_idx))

            ;; Move to the next one; exit the loop if we're out of units
            (set b30r_murder_witch_ai_idx (+ 1 b30r_murder_witch_ai_idx))
            (>= b30r_murder_witch_ai_idx (ai_living_count my_ai))
        )
        1
    )
)

(script continuous b30r_murder_witch
    ;; Check beach_2, since they can fall over the edge
    (b30r_murder_witch_check_ai ext_beach_2)

    ;; Same for beach_2_return
    (b30r_murder_witch_check_ai return_beach_2)

    ;; Same for marines who may be nearby
    (b30r_murder_witch_check_ai marines_ext_cart-sapp)

    ;; Same for anyone on a wraith
    (b30r_murder_witch_check_ai r_downed_wrth_ext_cart-sapp)

    ;; ...and the other one.
    (b30r_murder_witch_check_ai r_beach_2_wrth_ext_cart-sapp)

    ;; The players were the witch's true targets all along
    (b30r_murder_witch_unit_test (player0))
    (b30r_murder_witch_unit_test (player1))

    ;; Sleep for some vaguely reasonable amount of time
    (sleep 5)
)

;; ---
;; Phantom of the map
;; This was originally defined with the "phantom (dropship) helpers" down in the mission, as a joke.
;; For the sake of organization it doesn't live there anymore, but I hope you can appreciate the comedy value even so.

;; This allows us to sleep for (cinematic_screen_effect_stop) without blocking the phantom_of_the_map caller
(script continuous phantom_of_the_map_helper
    (sleep -1)
    
    (fade_in 0.666 0 0 75)
    (cinematic_screen_effect_start true)
    (cinematic_screen_effect_set_convolution 1 2 15 0 2.5)
    (sound_impulse_start "cmt\sounds\sfx\scenarios\b30_revamp\ambience\sounds\detail_howls_low" none 1)
    
    (sleep 75)
    (cinematic_screen_effect_stop)
)

(script static void phantom_of_the_map
    (wake phantom_of_the_map_helper)
)

;; ---
;; Secrets

(script static boolean (b30r_secret_teleport (object_definition weapon_tag) (cutscene_flag destination))
    ;; CO-OP: If more players are added, test for all of them here
    (if (or
            (unit_has_weapon (player0) weapon_tag)
            (unit_has_weapon (player1) weapon_tag)
        )
        (begin
            (teleport_players destination destination)
            (phantom_of_the_map)
            (skip_frame)
            (effect_new_on_object_marker "cmt\scenarios\singleplayer\b30_revamp\effects\secret_teleport" (player0) "body")
            (effect_new_on_object_marker "cmt\scenarios\singleplayer\b30_revamp\effects\secret_teleport" (player1) "body")

            true
        )
        false
    )
)

(script continuous b30r_secret_teleport_brute_shot
    (if (b30r_secret_teleport
            "cmt\weapons\evolved\_egg\brute_shot_super\brute_shot_super"
            secret_bruteshot_teleport
        )
        (sleep_forever)
        (sleep 30)
    )
)

(script continuous b30r_secret_teleport_dmr
    (if (b30r_secret_teleport
            "cmt\weapons\evolved\_egg\dmr_super\dmr_super"
            secret_dmr_teleport
        )
        (sleep_forever)
        (sleep 30)
    )
)

(script continuous b30r_fun_preserver
    (if (not (game_is_easy))
        (sleep -1)
    )

    (if (or debug_ice_cream_flavor_status_bandanna cheat_infinite_ammo)
        (begin
            (set debug_ice_cream_flavor_status_bandanna false)
            (set cheat_infinite_ammo false)
            (sound_impulse_start "cmt\sounds\sfx\ui\misc\cheater" none 1)
        )
    )
)

(script continuous safety_first
    (if (not (game_is_easy))
        (sleep -1)
    )
    
    ;; CO-OP: If more players are added, test for and extricate all of them here
    (sleep_until
        (or
            (= X_CAR_id_player0 "hog_gunner_rocket")
            (= X_CAR_id_player1 "hog_gunner_rocket")
        )
    )
    
    (if (= X_CAR_id_player0 "hog_gunner_rocket")
        (unit_exit_vehicle (player0))
    )
    (if (= X_CAR_id_player1 "hog_gunner_rocket")
        (unit_exit_vehicle (player1))
    )
)

(script startup m_int_hallways_shh
    (sleep_until (volume_test_players_any lroom_secret_smartass))
    (object_create secret_shredder)
)

(script startup ho_ho_ho
    (sleep_until (volume_test_players_any ho_ho_ho))

    (if (game_is_impossible)
        (begin
            (object_create secret_jingle_music)
            (object_create secret_jingle_grunt_1)
            (object_create secret_jingle_grunt_2)
            (ai_attach secret_jingle_grunt_1 jingle)
            (ai_attach secret_jingle_grunt_2 jingle)
            (ai_braindead jingle true)
            (ai_command_list jingle jingle_jump)
        )
    )
)

(script continuous beware_of_rift
    (sleep_until (and (game_saving) (volume_test_players_any rift)) 1)
    (game_save_cancel)
    (sleep_until (not (volume_test_players_any rift)) 1)
    (game_save_no_timeout)
)

;; ---
;; Entry point

(script startup b30r_main
    ;; Start black, no input allowed. Just in case.
    (snap_to_black)
    (player_enable_input false)

    ;; Give the game 1 tick to do whatever it needs to before we start messing everything up
    (skip_frame)

    ;; Start up mission scripts
    (b30r_mission_startup)

    ;; This is the dumbest thing I've had to do for this entire port. I can't believe this shit.
    ;; ABSOLUTE trash. Disgusting GARBAGE.
    (HACK_sound_gain_hack_very_evil)
)
