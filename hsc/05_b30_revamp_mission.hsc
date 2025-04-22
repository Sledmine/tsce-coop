;; 05_b30_revamp_mission.hsc
;; Top-level scripts for managing b30_revamp's mission state
;; ---

;; ---
;; Help text

(script static void (objective_set (hud_message menu_message) (hud_message help_message))
    (hud_set_objective_text menu_message)
    (set X_HLP_desired help_message)
)

(script dormant hog_help_text
    ;; Wait for a player to enter a hog
    (sleep_until
        (or
            (= X_CAR_id_player0 "hog_driver")
            (= X_CAR_id_player1 "hog_driver")
        )
    )
    
    ;; Explain how to use its health packs
    (set X_HLP_desired "help_hog")
)

;; ---
;; Dropships

;; Foehammer, who can become a cool ship that shoots rockets at aliens like a badass
(global vehicle insertion_pelican_1 none)
(script static void create_insertion_pelican_1
    (set insertion_pelican_1
        ;; If we're in comedy mode, use the comedy Pelican
        (if (game_is_easy)
            (begin
                (object_create_anew insertion_pelican_comedy_1)
                insertion_pelican_comedy_1
            )
            ;; Otherwise, decide whether to turn on dust FX based on whether the LZ is clear
            (if mission_lz_cleared
                (begin
                    (object_create_anew insertion_pelican_dust_1)
                    insertion_pelican_dust_1
                )
                (begin
                    (object_create_anew insertion_pelican_nodust_1)
                    insertion_pelican_nodust_1
                )
            )
        )
    )
)

;; Halo 3-style Phantom, doors only, no embedded gunners
(script static void create_ext_beach_1_cship
    (phantom_create_anew
        ext_beach_1_cship
        ext_beach_1_cship_grav
        ext_beach_1_cship_gun_l
        ext_beach_1_cship_gun_r
        ext_beach_1_cship_troop_l
        ext_beach_1_cship_troop_r
    )
)

;; Halo 2-style Phantom, cannons on both sides
(script static void create_ext_cart_cship
    (phantom_create_anew
        ext_cart_cship
        ext_cart_cship_grav
        ext_cart_cship_gun_l
        ext_cart_cship_gun_r
        ext_cart_cship_troop_l
        ext_cart_cship_troop_r
    )
)

;; Halo 3-style Phantom, doors only, Jackal sniper on right
(script static void create_override_cliffs_cship
    (phantom_create_anew
        override_cliffs_cship
        override_cliffs_cship_grav
        override_cliffs_cship_gun_l
        override_cliffs_cship_gun_r
        override_cliffs_cship_troop_l
        override_cliffs_cship_troop_r
    )
)

;; ---
;; The Trial of the Pistol

(script dormant magic
    (sleep_until
        (and
            ;; Wait until a player can see the magic, but nobody else can
            (= bsp_index_ext_lid (structure_bsp_index))
            (volume_test_players_any ext_beach_2_dumb)
            (< (ai_living_count ext_beach_2) 1)
        )
    )

    ;; We don't need any music that might be playing now anymore
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_02_warthog_adventure")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_03_cart_found")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_04_lockout")

    ;; Setup
    (object_create_anew magic_pelican)
    (object_create_anew magic_drop_pod)
    (object_create_anew secret_pistol)
    (objects_attach magic_drop_pod "gun" secret_pistol "")
    (objects_attach magic_pelican "droppodl01" magic_drop_pod "attach")

    ;; R I S E
    (object_teleport magic_pelican magic_start)
    (recording_play_and_delete magic_pelican magic_pelican_rise)
    (skip_second)

    ;; Play the music + FX after a small delay, then wait until it's time to drop
    (effect_new "cmt\scenarios\singleplayer\b30_revamp\effects\magic" magic_water)
    (sound_looping_start "cmt\sounds\music\scenarios\b30_revamp\egg\magic\magic" none 1)
    (sleep_until (< (recording_time magic_pelican) 530))

    ;; Drop it
     (effect_new_on_object_marker
        "cmt\scenery\_shared\h_drop_pod\effects\h_drop_pod_detach"
        magic_pelican
        "droppodl01"
    )
    (objects_detach magic_pelican magic_drop_pod)

    ;; Weapon can be picked up when it lands
    (sleep 90)
    (objects_detach magic_drop_pod secret_pistol)
    (sleep 90)

    ;; Oh no.
    (player_effect_explosion)
    (sound_impulse_start "cmt\sounds\sfx\vehicles\human\_shared\fx\human_explosion_large" none 1)
    (effect_new_on_object_marker
        "cmt\scenarios\singleplayer\b30_revamp\effects\magic_2"
        magic_pelican
        "crouch rider"
    )
    (object_destroy magic_pelican)
    (player_effect_stop 2)

    ;; The trial is over. Let's pretend that didn't happen
    (sound_looping_stop "cmt\sounds\music\scenarios\b30_revamp\egg\magic\magic")
    (sleep -1 trial_of_the_pistol_conditions)
    (sleep -1 trial_of_the_pistol)
    (game_save_no_timeout)
)

(script dormant trial_of_the_pistol_conditions
    (sound_impulse_start "cmt\sounds\dialog\scenarios\b30_revamp\cheif\mc_started" none 1)

    ;; Place these guys over in their places
    (object_create_containing secret_h1)

    ;; Mark cleared if player hit all the targets
    (sleep_until
        (and
            (<= (unit_get_health secret_h1_1) 0)
            (<= (unit_get_health secret_h1_2) 0)
            (<= (unit_get_health secret_h1_3) 0)
        )
    )

    ;; You are worthy.
    (wake magic)
)

(script static boolean trial_of_the_pistol_is_ready
    ;; CO-OP: If more players are added, check them all here
    (and
        (unit_has_weapon_readied (player0) "cmt\weapons\evolved\pistol\pistol")
        (or
            (not (game_is_cooperative))
            (unit_has_weapon_readied (player1) "cmt\weapons\evolved\pistol\pistol")
        )
    )
)

(script dormant trial_of_the_pistol
    ;; Await insertion in impossible mode
    (sleep_until
        (and
            (game_is_impossible)
            (>= mission_state mission_inserted)
        )
    )

    ;; If players qualify, begin the Trial of the Pistol
    (sleep 100)
    (if (trial_of_the_pistol_is_ready)
        (wake trial_of_the_pistol_conditions)
        (sleep_forever)
    )

    ;; These are the fail conditions
    ;; CO-OP: If more players are added, check them all here
    (sleep_until
        (or
            (!= none X_CAR_vehicle_player0)
            (!= none X_CAR_vehicle_player1)
            (not (trial_of_the_pistol_is_ready))
        )
    )

    ;; You not worthy.
    ;; CO-OP: If more players are added, check them all here
    (if (or
            (< 0 (unit_get_health (player0)))
            (< 0 (unit_get_health (player1)))
        )
        (sound_impulse_start "cmt\sounds\dialog\scenarios\b30_revamp\cheif\mc_bad" none 1)
    )
    
    (object_destroy_containing secret_h1)
    (sleep -1 trial_of_the_pistol_conditions)
    (sleep -1 magic)
)

;; ---
;; Special difficulty

(script dormant b30r_life_help_text
    (sleep 30000)
    (objective_set dia_life help_life)
)

(script continuous _
    (sleep_until (game_is_easy) 1)
    (sleep_until (game_saving) 1)
    (sleep_until (not (game_saving)) 1)
    (sound_impulse_start "sound\sfx\ui\countdown_timer_end" none 1)
)

(script static void b30r_mission_easy_setup
    ;; These guns are honestly just boring. Theres no skill really, you just point and shoot. What I like about
    ;; H1 is that each weapon takes skill to use, but here you just adding changes for no reason other than
    ;; to have changes, the behaviors are just confusing. That's not what people want from a mod of H1.
    (objects_delete_by_definition "cmt\weapons\evolved\assault_rifle\assault_rifle")
    (objects_delete_by_definition "cmt\weapons\evolved\pistol\pistol")
    (objects_delete_by_definition "cmt\weapons\evolved\shotgun\shotgun")
    (objects_delete_by_definition "cmt\weapons\evolved\brute_shot\brute_shot")
    (objects_delete_by_definition "cmt\weapons\evolved\needler\needler")
    (objects_delete_by_definition "cmt\weapons\evolved\plasma_rifle\plasma_rifle")
    (objects_delete_by_definition "cmt\weapons\evolved\plasma_pistol\plasma_pistol")
    (objects_delete_by_definition "cmt\weapons\evolved\shredder\shredder")
    (objects_delete_by_definition "cmt\weapons\evolved\spiker\spiker")
    (object_destroy_containing secret)

    ;; There aren't enough human weapons on the map. I like to rock the Battle Rifle with the Pistol as my backup,
    ;; but I cant do that here because I'm forced to use the same guns every time. You shouldnt punish people for
    ;; wanting to be creative.  Its no fun being forced to play a certain way.
    (object_create_anew_containing "easy")

    ;; This was always just supposed to be a placeholder for testing.
    (sleep -1 X_HLP_checkpoint)
    (wake _)

    ;; Halo is, at its core, a war story.
    (object_create grimdome)
    (wake b30r_life_help_text)
)

;; ---
;; Credits

(global boolean b30r_rolled_credits false)

(script dormant b30r_credits_titles
    (cinematic_set_title credits_tsce_title)
    (sleep 30)
    
    (cinematic_set_title credits_tsce_core_title)
    (sleep 30)
    (cinematic_set_title credits_tsce_core_lag)
    (sleep 180)
    (cinematic_set_title credits_tsce_core_dafi)
    (sleep 180)
    (cinematic_set_title credits_tsce_core_silicon)
    (sleep 30)
    (cinematic_set_title credits_tsce_core_bob_llama)
    (sleep 180)
    
    (cinematic_set_title credits_tsce_additional_title)
    (sleep 30)
    (cinematic_set_title credits_tsce_additional_1)
    (cinematic_set_title credits_tsce_additional_2)
    (sleep 210)
    (cinematic_set_title credits_tsce_additional_3)
    (cinematic_set_title credits_tsce_additional_4)
    (sleep 210)

    ;; ---

    (cinematic_set_title credits_1_4_title)
    (sleep 60)
    
    (cinematic_set_title credits_1_4_core_team)
    (sleep 30)
    (cinematic_set_title credits_1_4_thanks)
    (sleep 30)
    (cinematic_set_title credits_1_4_testing)
    (sleep 180)

    ;; ---

    (cinematic_set_title credits_mcc_title)
    (sleep 60)
    
    (cinematic_set_title credits_mcc_core_team)
    (sleep 30)
    (cinematic_set_title credits_mcc_thanks)
    (sleep 30)
    (cinematic_set_title credits_mcc_testing)
    (sleep 180)
    
    ;; ---
    
    (cinematic_set_title credits_cmt_title)
    (sleep 30)
    
    (cinematic_set_title credits_cmt_1)
    (cinematic_set_title credits_cmt_2)
    (sleep 210)
    (cinematic_set_title credits_cmt_3)
    (cinematic_set_title credits_cmt_4)
    (cinematic_set_title credits_cmt_5)
    (sleep 210)
    
    ;; ---
    
    (cinematic_set_title credits_developers)
    (sleep 300)
    
    ;; ---
    
    (cinematic_set_title credits_spv2_title)
    (sleep 90)
    
    (cinematic_set_title credits_spv2_1)
    (cinematic_set_title credits_spv2_2)
    (sleep 210)
)

(script dormant b30r_credits_cutscene
    ;; Don't get any funny ideas
    (show_hud true)
    (player_enable_input true)

    ;; Cut to black from ending cutscene, and wait a bit more for players' adrenaline to wear off
    (snap_to_black)
    (sleep 150)
    
    ;; Switch to cinematic FOV, but with no letterbox
    (camera_control true)
    (cinematic_start)
    (cinematic_show_letterbox false)

    ;; Why god
    (switch_bsp bsp_index_ext_lz)
    (camera_set credits_lz_a 0)
    (camera_set credits_lz_b 30)
    (skip_second)
    (camera_set credits_lz_a 0)
    (object_pvs_set_camera credits_lz_b)

    ;; Disable lodvols so objects are visible during credits
    (b30r_lod_volumes_disable)

    ;; Disable other mischievous objects
    (object_destroy_containing "hog")
    (object_destroy_containing "ghost")
    (object_destroy_containing "wraith")
    (object_destroy_containing "secret")

    ;; Begin music, let it ramp up
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_21_credits")
    (sleep 300)

    ;; Fade in, set the scene for a couple of seconds
    (fade_in 0 0 0 150)
    (sleep 120)
    
    ;; Begin displaying credits
    (wake b30r_credits_titles)
    (sleep 30)

    ;; Camera starts moving
    (camera_set credits_lz_b 480)
    (sleep 350)

    ;; Face the sun
    (camera_set credits_lz_c 300)
    (sleep 240)

    ;; Fade out
    (fade_to_white)
    (skip_second)

    ;; Switch to pool, wait a bit to get camera moving
    (switch_bsp bsp_index_ext_pool)
    (camera_set credits_pool_a 0)
    (object_pvs_set_camera credits_pool_b)
    (camera_set credits_pool_b 330)
    (skip_second)

    ;; Fade in
    (fade_from_white)
    (sleep 185)

    ;; Start next camera movement before first comes to a complete stop
    (camera_set credits_pool_c 300)
    (sleep 240)

    ;; Fade out as the last movement finishes
    (fade_to_black)
    (skip_second)

    ;; Switch to cave, wait a bit to get camera moving
    (switch_bsp bsp_index_ext_cave)
    (camera_set credits_cave_a 0)
    (object_pvs_set_camera credits_cave_a)
    (camera_set credits_cave_b 370)
    (skip_second)

    ;; fade in
    (fade_from_black)
    (sleep 240)

    ;; Cut to Hunter building, hide the cut with a flash since HCE doesn't let me do a crossfade
    (fade_to_white)
    (skip_second)
    (camera_set credits_hunter_a 0)
    (skip_second)
    (fade_from_white)
    (camera_set credits_hunter_b 400)
    (sleep 185)

    ;; Fade out into cavewater color for descent into shafta
    (fade_out 0.18 0.26 0.24 30)
    (skip_second)

    ;; Switch to waterhall, wait a bit to get camera moving
    (switch_bsp bsp_index_int_shaft_b)
    (camera_set credits_waterhall_a 0)
    (object_pvs_set_camera credits_waterhall_a)
    (camera_set credits_waterhall_b 240)
    (skip_second)

    ;; Fade in
    (fade_in 0.18 0.26 0.24 30)
    (sleep 210)

    ;; Fade out as camera comes to a stop
    (fade_to_black)
    (skip_second)

    ;; Switch to map room, wait a bit to get camera moving
    (switch_bsp bsp_index_int_shaft_c)
    (camera_set credits_maproom_a 0)
    (object_pvs_set_object int_shaft_c_holo_ring)
    (camera_set credits_maproom_b 300)
    (skip_second)

    ;; Fade in
    (fade_from_black)
    (sleep 170)

    ;; Finish the movement
    (camera_set credits_maproom_c 300)
    (sleep 170)

    ;; Fade out before camera slows down
    (fade_to_white)
    (skip_second)

    ;; Switch to cart field, wait a bit to get camera moving
    (switch_bsp bsp_index_ext_cart)
    (camera_set credits_field_a 0)
    (camera_set credits_field_b 300)
    (object_pvs_clear)
    (skip_second)

    ;; Fade in and finish it
    (fade_from_white)
    (sleep 360)
    (fade_out 0 0 0 150)
    (sleep 150)

    ;; Oooh
    (if (game_is_impossible)
        (begin
            (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_22_teaser")
            (skip_second)

            (switch_bsp bsp_index_int_shaft_c)
            (object_create_anew the_silent_battle_rifle)
            (object_teleport the_silent_battle_rifle tease_item)
            (camera_set cutscene_tease_1a 0)
            (camera_set cutscene_tease_1b 345)
            (sleep 120)

            (fade_from_black)
            (sleep 210)

            (snap_to_black)
            (object_destroy the_silent_battle_rifle)
            (sleep 150)
        )
    )

    (sound_class_set_gain "ambient_nature" 0 0)
    (sound_class_set_gain "ambient_machinery" 0 0)

    ;; Done
    (cinematic_stop)
    (set b30r_rolled_credits true)
)

(script static void b30r_roll_credits
    (wake b30r_credits_cutscene)
)

;; ---
;; Checkpoint launching

;; DO NOT CHANGE THESE!
(global short b30r_launch_lz 0)
(global short b30r_launch_ext 1)
(global short b30r_launch_override 2)
(global short b30r_launch_override_a 3)
(global short b30r_launch_return 4)
(global short b30r_launch_int 5)
(global short b30r_launch_exit 6)
(global short b30r_launch_free 7)

;; CO-OP: If more players are added, add more params here for the (teleport_players) call
(script static void (checkpoint_launch (short bsp_index) (cutscene_flag spawn_player0) (cutscene_flag spawn_player1))
    ;; Move players to the desired BSP
    (switch_bsp bsp_index)
    (teleport_players spawn_player0 spawn_player1)

    ;; Turn on cinematic bars
    (cinematic_show_letterbox true)
    (skip_second)

    ;; Re-enable input after dropping a save
    (game_save_no_timeout)
    (player_enable_input true)

    ;; CO-OP: If more players are added, distribute guns to them all here
    (if (= easy (game_difficulty_get_real)) ;; Ensure coolest guns appropriate for the occasion
        (begin
            (player_add_equipment (player0) checkpoint_easy true)
            (player_add_equipment (player1) checkpoint_easy true)
        )
        (begin
            (player_add_equipment (player0) checkpoint true)
            (player_add_equipment (player1) checkpoint true)
        )
    )

    ;; Done, fade back in
    (cinematic_show_letterbox false)
    (fade_from_white)
)

;; ---
;; Secret command

(script static boolean test_secret_command
    ;; Re-enable player input long enough to test for "Jump."
    ;; As soon as any player jumps, they'll reach the test volume, triggering success.
    ;;
    ;; This is backwards-compatible with our previous implementation, which used
    ;; `player_action_test_jump`, but which did not sync in co-op.
    (player_enable_input true)
    (sleep_until (volume_test_players_any debug_room_entry_test) 1 15)
    (player_enable_input false)

    (volume_test_players_any debug_room_entry_test)
)

;; ---
;; Mission control

;; Mission state
(global short mission_launch_index -1)
(global short mission_state 0)
(global boolean mission_lz_cleared false)
(global boolean mission_security_unlocked false)

;; DO NOT CHANGE THESE!
(global short mission_init                        0)
(global short mission_inserted                    1)
(global short mission_cartographer_found          2)
(global short mission_cartographer_entered        3)
(global short mission_cartographer_activated      4)
(global short mission_extracted                   5)

;; The detour to deactivate the security system
(script dormant b30r_mission_detour_control
    ;; m_override: Unlock security
    (if (or
            (<= mission_launch_index b30r_launch_override)
            (<= mission_launch_index b30r_launch_override_a)
        )
        (m_override_startup)
        (m_override_mark_skip)
    )

    ;; Wait for the override mission to be complete
    (sleep_until mission_security_unlocked 1)

    ;; m_return: Return to the cartographer
    (if (<= mission_launch_index b30r_launch_return)
        (m_return_startup)
        (m_return_mark_skip)
    )

    ;; Prep override and ext for returning player
    (m_ext_mark_return)
    (m_override_mark_return)
)

;; The main mission to activate the cartographer
(script dormant b30r_mission_control
    ;; Activate the debug room for selecting a launch index, if either:
    ;; - Developer mode is enabled
    ;; - "cool mode" is enabled
    ;; - The secret command was used
    ;;
    ;; ...otherwise, default to launching at the LZ
    (if (or
            (!= 0 developer_mode)
            (test_secret_command)
        )
        (b30r_debug_room)
        (set mission_launch_index b30r_launch_lz)
    )

    ;; m_lz: Insert the player
    (if (<= mission_launch_index b30r_launch_lz)
        (m_lz_startup)
        (m_lz_mark_skip)
    )

    ;; Await completion of insertion
    (sleep_until (>= mission_state mission_inserted) 1)

    ;; m_ext: Find the cartographer
    (if (<= mission_launch_index b30r_launch_ext)
        (m_ext_startup)
        (m_ext_mark_skip)
    )

    ;; Halt progression until the cartographer is found
    (sleep_until (>= mission_state mission_cartographer_found) 1)

    ;; Clean up lz once we're at the cartographer
    (m_lz_cleanup)

    ;; Activate the security detour, giving it a frame to catch up
    (wake b30r_mission_detour_control)
    (skip_frame)

    ;; m_int: Activate the cartographer
    (if (<= mission_launch_index b30r_launch_int)
        (m_int_startup)
        (m_int_mark_skip)
    )

    ;; Wait for the player to enter the cartographer
    (sleep_until (>= mission_state mission_cartographer_entered) 1)

    ;; Clean up the override mission, if active, once player makes it back
    (if mission_security_unlocked
        (m_override_cleanup)
    )

    ;; Wait for cartographer to be active
    (sleep_until (>= mission_state mission_cartographer_activated) 1)

    ;; m_exit: Reach extraction
    (if (<= mission_launch_index b30r_launch_exit)
        (m_exit_startup)
        (m_exit_mark_skip)
    )

    ;; Clean up the ext + int missions
    (m_ext_cleanup)
    (m_int_cleanup)

    ;; Kill the detour missions
    (sleep -1 b30r_mission_detour_control)
    (m_override_cleanup)
    (m_return_cleanup)

    ;; Wait for player to be extracted
    (sleep_until (>= mission_state mission_extracted) 1)

    ;; Player extracted, clean everything up
    (m_exit_cleanup)

    ;; Free-roaming: if someone asked for it
    (if (>= mission_launch_index b30r_launch_free)
        (begin
            ;; Give the players a car
            (object_create_anew ext_drop_hog)
            (object_teleport ext_drop_hog m_free_hogspawn)
            (checkpoint_launch bsp_index_ext_lz m_free_spawn_0 m_free_spawn_1)

            ;; Remove any lingering obstacles to the fun
            (ai_erase_all)
            (object_destroy_containing cart_return_block)
            (object_destroy_containing return_cliffs_barrier)

            ;; "cool mode" lives on...
            (object_create_containing "coolmode")

            ;; Let them have a good time. No more mission events will happen.
            (sleep_forever)
        )
        (begin
            ;; Otherwise, roll credits
            (b30r_roll_credits)
            (sleep_until b30r_rolled_credits 1)
        )
    )

    ;; Switch to the empty BSP, and give the pleasant ambience a second to fade out
    (switch_bsp 0)
    (teleport_players the_void the_void)
    (sleep 30)

    ;; Disable sound before restoring camera control, so none of the shuffling we just did is audible
    (sound_enable false)
    (camera_control 0)

    ;; Reveal the debug room!
    (cinematic_set_title debug_room_hint)

    ;; Wait for the command to reset the map. As long as the players continue to hold the command,
    ;; the launch sequence will pick it up, creating a seamless effect.
    ;; But, time out after 15 seconds, in case the player just wants it to end.
    (sleep_until
        (begin
            (if (test_secret_command)
                (begin
                    (sound_enable true)
                    (map_reset)
                )
            )
            false
        )
        1
        540
    )

    ;; That's all.
    (sound_enable true)
    (game_won)
)

;; ---
;; Entry point

(script static void b30r_mission_startup
    ;; Set up AI allegiances
    (ai_allegiance player human)
    (ai_allegiance sentinel human)

    (ai_allegiance player unused6)
    (ai_allegiance human unused6)
    (ai_allegiance covenant unused6)

    ;; Don't attack secrets please
    (ai_allegiance covenant flood)
    (ai_allegiance human flood)

    ;; Wake mission control
    (wake b30r_mission_control)

    ;; Wake hog help
    (wake hog_help_text)

    ;; Wake the trial
    (wake trial_of_the_pistol)

    ;; Special difficulty setup
    (if (game_is_easy)
        (b30r_mission_easy_setup)
    )
)
