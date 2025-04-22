;; 07_b30_revamp_mission_lz.hsc
;; Mission to clear the initial landing zone
;; ---

;; ---
;; Insertion cutscene

(script dormant m_lz_cutscene_insertion_rocket
    ;; Fire rocket
    (sound_impulse_start "cmt\sounds\sfx\weapons\human\rocket_launcher\fx\rocket_launcher_rocket_fire" none 1)
    (sleep 25)

    ;; Boom!
    (recording_kill lz_wraith)
    (object_destroy lz_wraith)
    (object_create_containing lz_wraith_d)
    (object_create lz_wraith_cover)
    (effect_new_on_object_marker "cmt\vehicles\evolved\wraith\effects\wraith_body_depleted" lz_wraith_cover "")
    (ai_erase lz_marines/rocket_marine)
    (set m_lz_rescue_witch_start true)

    ;; Fake FX so that players actually see/hear something
    ;; CO-OP: If more players are added, apply effects to them all here
    (damage_object "cmt\effects\shared effects\damage_effects\large explosion shockwave" (player0))
    (damage_object "cmt\effects\shared effects\damage_effects\large explosion shockwave" (player1))
    (sound_impulse_start "cmt\sounds\sfx\vehicles\covenant\_shared\fx\covenant_explosion_large" insertion_pelican_nodust_2 1)
)

(script dormant m_lz_cutscene_insertion
    ;; Mission launch has already set up the camera & cutscene. All we need is a letterbox.
    ;; Bring it in before spawning AI, to better hide hitches
    (cinematic_show_letterbox true)
    (skip_second)

    ;; Set up players
    ;; This is just a temporary holding place, so we can put both of them here
    ;; CO-OP: If more players are added, distribute guns to them all here
    (teleport_players insertion_cutscene_player insertion_cutscene_player)
    (if (game_is_easy)
        (begin
            (player_add_equipment (player0) lz_easy_player0 true)
            (player_add_equipment (player1) lz_easy_player1 true)
        )
        (begin
            (player_add_equipment (player0) lz true)
            (player_add_equipment (player1) lz true)
        )
    )
    (skip_frame)

    ;; Set up Marines
    (skip_frame)
    (if (game_is_easy)
        (begin
            (ai_place lz_marines/left_marines_easy)
            (ai_place lz_marines/right_marines_easy)
            (ai_migrate lz_marines/left_marines_easy lz_marines/left_marines)
            (ai_migrate lz_marines/right_marines_easy lz_marines/right_marines)
        )
        (begin
            (ai_place lz_marines/left_marines)
            (ai_place lz_marines/right_marines)
        )
    )
    (ai_place lz_marines/rocket_marine)
    (ai_braindead lz_marines true)

    ;; Set up Pelicans
    ;; CO-OP: If more players are added, (somehow) stick them in the Pelicans here
    (skip_frame)
    (create_insertion_pelican_1)
    (object_create_anew insertion_pelican_nodust_2)
    (object_create_anew insertion_pelican_nodust_3)
    (unit_enter_vehicle (player0) insertion_pelican_1 "p-riderlf")
    (unit_enter_vehicle (player1) insertion_pelican_1 "p-riderrf")
    (vehicle_load_magic insertion_pelican_1 "rider" (ai_actors lz_marines/left_marines))
    (vehicle_load_magic insertion_pelican_nodust_2 "rider" (ai_actors lz_marines/right_marines))
    (vehicle_load_magic insertion_pelican_nodust_2 "p-ridercrouch" (ai_actors lz_marines/rocket_marine))

    ;; Set up hogs
    (skip_frame)
    (objects_attach insertion_pelican_nodust_3 "cargo" override_cliffs_dump_hog "")

    ;; Likewisem set up the Covenant stuff
    (ai_place lz/recon_brutes)
    (ai_place lz/recon_grunts)
    (skip_frame)
    (ai_place lz/lower_camp_elites)
    (ai_place lz/lower_camp_jackals)
    (ai_place lz/lower_camp_grunts)
    (skip_frame)
    (ai_place lz/mid_camp_elites)
    (ai_place lz/mid_camp_grunts)
    (ai_place lz/mid_camp_jackals)
    (skip_frame)
    (ai_place lz/high_camp_grunts)
    (ai_place lz/turret_gunner_high)
    (skip_frame)

    ;; Special difficulty
    (if (game_is_easy)
        (begin
            (ai_erase lz/recon_brutes)
            (ai_place lz/easy)
            (ai_migrate lz/lower_camp_grunts_easy lz/lower_camp_grunts)
            (ai_migrate lz/mid_camp_grunts_easy lz/mid_camp_grunts)
            (ai_migrate lz/high_camp_grunts_easy lz/high_camp_grunts)
            (object_create lz_wraith_easy)
            (vehicle_load_magic lz_wraith_easy "wraith-driver" (ai_actors lz/wraith_pilot_easy))
        )
    )

    ;; Zealot on legendary
    (if (game_is_impossible)
        (ai_place lz/core_zealot)
    )

    ;; Lower turret gunner does not appear on easy
    (if (not (game_is_easy))
        (ai_place lz/turret_gunner_low)
    )

    ;; Can't kill these guys yet
    (object_cannot_take_damage (ai_actors lz/turret_gunner_high))
    (object_cannot_take_damage (ai_actors lz/turret_gunner_low))

    ;; Begin with the intro foley
    (sound_looping_start "cmt\sounds\sfx\scenarios\b30_revamp\foley\b30r_insertion_foley" none 1)
    (sleep 85)

    ;; Rumble as sound ramps up
    (player_effect_rumble)
    (sleep 5)

    ;; Pelicans start moving
    (object_teleport insertion_pelican_1 insertion_cutscene_p1)
    (object_teleport insertion_pelican_nodust_2 insertion_cutscene_p2)
    (object_teleport insertion_pelican_nodust_3 insertion_cutscene_p3)
    (recording_play_and_hover insertion_pelican_1 insertion_pelican_1_in)
    (recording_play_and_hover insertion_pelican_nodust_2 insertion_pelican_2_in)
    (recording_play_and_delete insertion_pelican_nodust_3 insertion_pelican_3_in)
    (sleep 60)

    ;; Pelicans fly past; music starts, shake fades out
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01_insertion")
    (player_effect_stop 2)

    ;; Camera recoils, scene plays out as it recovers
    (camera_set cutscene_insertion_1b 30)
    (sleep 3)
    (camera_set cutscene_insertion_1c 30)
    (sleep 15)
    (camera_set cutscene_insertion_1a 90)
    (sleep 140)

    ;; Tracking shot
    (camera_set_relative cutscene_insertion_r1 0 insertion_pelican_1)
    (sleep 140)

    ;; Cut to low angle, looking up; title plays, peli3 secretly teleports to better position
    (object_teleport insertion_pelican_nodust_3 insertion_cutscene_p3_tp)
    (camera_set cutscene_insertion_2a 0)
    (if (game_is_easy)
        (cinematic_set_title insertion_special)
        (cinematic_set_title insertion)
    )
    (sleep 35)

    ;; Wraith goes here so it's not as noticeable
    (object_create lz_wraith)
    (ai_place lz/wraith_pilot)
    (vehicle_load_magic lz_wraith "wraith-driver" (ai_actors lz/wraith_pilot))

    ;; First lines
    (if (game_is_easy)
        (ai_conversation lz_intro_special)
        (ai_conversation lz_intro)
    )
    (skip_half_second)

    ;; Camera rotates to follow Pelicans
    (camera_set cutscene_insertion_2b 130)
    (sleep 150)

    ;; Cut to Marine loading, then MC
    (camera_set_relative cutscene_insertion_r2 0 insertion_pelican_1)
    (ai_command_list lz_marines/left_marines lz_peli_looking)
    (sleep 90)
    (camera_set_relative cutscene_insertion_r3 0 insertion_pelican_nodust_2)
    (ai_command_list lz_marines/right_marines lz_peli_looking)
    (ai_command_list lz_marines/rocket_marine lz_peli_looking_2)
    (sleep 40)

    ;; Wraith comes online & turret dudes hop in
    (ai_vehicle_encounter lz_turret_high lz/turret_gunner_high)
    (ai_vehicle_encounter lz_turret_high lz/turret_gunner_low)
    (ai_go_to_vehicle lz/turret_gunner_high lz_turret_high "gunner")
    (ai_go_to_vehicle lz/turret_gunner_low lz_turret_low "gunner")
    (recording_play lz_wraith lz_wraith_fire)
    (sleep 50)

    ;; Actors will preferentially target the Brutes so that players' lives are not hell
    (ai_try_to_fight lz_marines lz/recon_brutes)

    ;; Cut to beach shot, then rotate up to follow pelis
    (camera_set cutscene_insertion_3a 0)
    (sleep 20)
    (camera_set cutscene_insertion_3b 140)
    (sleep 40)
    (camera_set cutscene_insertion_3c 140)
    (sleep 20)

    ;; Cut to player
    (fade_to_white)
    (skip_second)
    (camera_control false)
    (fade_from_white)
    
    ;; Switch back to the player's FOV, but keep the letterbox
    (cinematic_stop)
    (cinematic_show_letterbox true)
    (player_enable_input false)

    ;; Reached LZ
    (ai_conversation lz_approaching)
    (sleep 40)
    
    ;; Perform evil tricks now, if there's a player at risk of seeing them
    (if (game_is_cooperative)
        (begin
            (wake m_lz_cutscene_insertion_rocket)
            (object_teleport insertion_pelican_nodust_2 insertion_cutscene_p2_end)
            (vehicle_hover insertion_pelican_nodust_2 true)
        )
    )
    (sleep 105)

    ;; Send in the covenant recon team
    (ai_command_list lz/recon_brutes lz_cov_recon_leader)
    (ai_command_list lz/recon_grunts lz_cov_recon)
    (ai_migrate lz/recon_grunts lz/recon_combat)
    (ai_migrate lz/recon_brutes lz/recon_combat)
    (ai_attack lz/recon)
    
    ;; If there's only one player, we can wait until now for evil tricks
    (if (not (game_is_cooperative))
        (begin
            (wake m_lz_cutscene_insertion_rocket)
            (object_teleport insertion_pelican_nodust_2 insertion_cutscene_p2_end)
            (vehicle_hover insertion_pelican_nodust_2 true)
        )
    )
    (sleep 45)

    ;; The waterfall can exist now
    (object_create_containing "spray")

    ;; Touchdown
    (ai_conversation lz_touchdown)
    (sleep 55)

    ;; Unload everyone
    (vehicle_unload insertion_pelican_1 "rider")
    (vehicle_unload insertion_pelican_nodust_2 "rider")
    (unit_set_enterable_by_player insertion_pelican_1 false)
    (unit_set_enterable_by_player insertion_pelican_nodust_2 false)
    (ai_braindead lz_marines false)
    (ai_command_list_advance lz_marines)
    (skip_frame)
    (ai_command_list lz_marines move_forwards)

    ;; Secretly, some Marines got out ahead of you! And they DIED
    (if (not (game_is_easy))
        (object_create_containing lz_dump)
    )
    (object_create_containing lz_elev_dump)
    (object_create_anew override_cliffs_dump_hog)

    ;; Can kill these guys now
    (object_can_take_damage (ai_actors lz))

    ;; Once the players are out, we let them do stuff
    ;; CO-OP: If more players are added, give them grenades here
    (skip_half_second)
    (set mission_state mission_inserted)
    (player_enable_input true)
    (player_add_equipment (player0) grenades false)
    (player_add_equipment (player1) grenades false)
    (sleep 60)
    (cinematic_show_letterbox false)
    (show_hud true)
    (game_save_totally_unsafe)
    (skip_frame)

    ;; Remove preferential Brute targeting from friendly AI
    (ai_try_to_fight_nothing lz_marines)
    (sleep 45)

    ;; Then they fly away
    (vehicle_hover insertion_pelican_1 false)
    (recording_play_and_delete insertion_pelican_1 insertion_pelican_1_out)
    (skip_second)
    (vehicle_hover insertion_pelican_nodust_2 false)
    (recording_play_and_delete insertion_pelican_nodust_2 insertion_pelican_2_out)
)

;; ---
;; Auxiliary updaters

(global boolean m_lz_sidepath false)
(global boolean m_lz_highpath false)

;; Wait until the player moves to one path & mark that it has been chosen
(global boolean m_lz_updater_start false)
(script continuous m_lz_updater
    (sleep_until m_lz_updater_start 1)

    (cond
        (
            ;; Any player going down the side justifies a maneuver
            (or
                (volume_test_players_any lz_beach_side)
                (volume_test_players_any lz_beach_side_main)
            )
            (set m_lz_sidepath true)
            (set m_lz_highpath false)
        )
        (
            ;; But if all players are up the high path, keep it reinforced
            (or
                (volume_test_players_all lz_beach_high)
                (volume_test_players_all lz_beach_high_main)
            )
            (set m_lz_highpath true)
            (set m_lz_sidepath false)
        )
    )
    
    (sleep 15)
)

;; "i'll say it in red! _it is possible to guarantee that no covenant get stuck inside the wraith_!"
;; Use magic to yoink wayward units away from the damaged wraith during the cutscene, so they don't appear stuck inside
;; When the player passes by.
(global short m_lz_rescue_idx 0)
(global boolean m_lz_rescue_witch_start false)

(script continuous m_lz_rescue_witch
    ;; Wait until told to activate
    (sleep_until m_lz_rescue_witch_start 1)

    ;; If we've checked everyone, the witch's work here is done
    (if (>= m_lz_rescue_idx (ai_living_count lz))
        (sleep -1)
    )

    ;; If an actor is in the danger zone, yoink them to safety
    (if (volume_test_object lz_wraith_danger (ai_actor lz m_lz_rescue_idx))
        (object_teleport (ai_actor lz m_lz_rescue_idx) lz_wraith_yoink)
    )

    ;; Check the next actor on the next frame
    (set m_lz_rescue_idx (+ 1 m_lz_rescue_idx))
)

;; ---
;; Mission progression

(global boolean m_lz_coreplaced false)

;; DO NOT CHANGE THESE!
(global short blz_init 0)
(global short blz_started 1)
(global short blz_recon_pushed 2)
(global short blz_recon_broken 3)
(global short blz_camp_tapped 4)
(global short blz_camp_pushed 5)
(global short blz_camp_broken 6)
(global short blz_core_tapped 7)
(global short blz_core_crossed 8)
(global short blz_cov_pushed 9)
(global short blz_cov_broken 10)
(global short blz_cov_dead 11)
(global short blz_finished 12)
(global short m_lz_state blz_init)

(script dormant m_lz_combat
    (set m_lz_state blz_started)

    ;; Objective text
    (objective_set dia_lz obj_lz)

    ;; Allow Covenant to enter the lower turret
    (ai_vehicle_enterable_team lz_turret_low covenant)
    (ai_vehicle_enterable_distance lz_turret_low 2)

    ;; No grenades for AI in the first few seconds, that's way cheap
    (ai_grenades false)

    ;; Wait for a player to advance or for recon to get their asses kicked
    (sleep_until
        (or
            (volume_test_players_any lz_beach_initcombat)
            (< (ai_living_fraction lz/recon) 0.5)
        )
        5
    )
    (set m_lz_state blz_recon_pushed)

    ;; Pull back recon
    (ai_defend lz/recon)

    ;; Wake the scripts looking for the path the player is taking
    (set m_lz_updater_start true)

    ;; Wait for the player to advance or for recon to get their asses totally kicked
    (sleep_until
        (or
            m_lz_sidepath
            m_lz_highpath
            (< (ai_living_count lz/recon) 2)
        )
        5
    )
    (set m_lz_state blz_recon_broken)

    ;; Grenades are ok now
    (ai_grenades true)

    ;; Make the recon dudes retreat; send in the lower camp to back them up
    (ai_retreat lz/recon)
    (ai_attack lz/camp_low)

    ;; Make the Marines move up to meet them
    (ai_migrate_and_speak lz_marines/left lz_marines/left_marines_rocks "advance")
    (ai_migrate_and_speak lz_marines/right lz_marines/right_marines_rocks "advance")
    (ai_renew lz_marines)

    ;; Wait for a player to move up and/or for the camp to get their asses kicked
    (sleep_until
        (or
            (volume_test_players_any lz_beach_main)
            (< (ai_living_count lz/camp_low) 4)
            (< (ai_living_count lz/camp) 5)
        )
        5
    )
    (set m_lz_state blz_camp_tapped)

    ;; Players can save again before the camp assault
    (game_save_no_timeout)

    ;; If a player is taking the low route, send out the camp and redistribute forces accordingly
    (if m_lz_sidepath
        (begin
            (ai_migrate lz/camp lz/camp_low_again)
        )
        ;; Otherwise, if both players are up high, send some up above
        (begin
            (ai_migrate lz/camp_low lz/high_camp_grunts)
        )
    )

    ;; Send in the snipers, high or low
    (if (random_chance_50)
        (begin
            (ai_place lz/snipers_high)
            (ai_command_list lz/snipers_high lz_sniper_high)
        )
        (begin
            (ai_place lz/snipers_low)
            (ai_command_list lz/snipers_low lz_sniper_low)
        )
    )

    ;; Allow Covenant to enter the upper turret
    (ai_vehicle_enterable_team lz_turret_high covenant)
    (ai_vehicle_enterable_distance lz_turret_high 1)

    ;; Keep the bros alive
    (ai_renew lz_marines)

    ;; Wait for a player to move up or for the camp to start taking losses
    (sleep_until
        (or
            (volume_test_players_any lz_beach_main)
            (and
                (< (ai_living_count lz/camp) 4)
                (< (ai_living_count lz/camp_low) 4)
                (< (ai_living_count lz/core) 4)
            )
        )
        5
    )
    (set m_lz_state blz_camp_pushed)

    ;; Move up the Marines
    (ai_migrate lz_marines/left lz_marines/left_marines_assault)
    (ai_renew lz_marines)

    ;; These dudes sometimes don't move so they are forced to move. Move it, assholes.
    (ai_command_list lz_marines/right right_marines_charge)

    ;; Send the core out early to meet a player if one is down low and the camp is suffering
    (if
        (and
            m_lz_sidepath
            (< (ai_living_count lz/camp_low) 5)
            (< (ai_living_count lz/core) 5)
        )
        (begin
            (set m_lz_coreplaced true)
            (ai_place lz/core_elites)
            (ai_place lz/core_grunts)
            (ai_migrate lz/core_elites lz/camp_low_again)
            (ai_migrate lz/core_grunts lz/camp_low_again)
            (ai_attack lz/core)
            (ai_attack lz/camp_low_again)
        )
        ;; Otherwise move the low camp to reinforce the others
        (begin
            (ai_migrate lz/camp_low_again lz/core_cleanup)
            (ai_migrate lz/camp_low lz/high_camp_grunts)
        )
    )

    ;; Make the camp fall back but not retreat
    (ai_defend lz/camp)

    ;; Keep the bros alive
    (ai_renew lz_marines)

    ;; Wait for a player to move up or for the camp to get its ass totally kicked
    (sleep_until
        (or
            (volume_test_players_any lz_beach_main)
            (volume_test_players_any lz_beach_threshold)
            (and
                (< (ai_living_count lz/camp) 4)
                (< (ai_living_count lz/camp_low) 3)
                (< (ai_living_count lz/core) 3)
            )
        )
        5
    )
    (set m_lz_state blz_camp_broken)

    ;; Move up the marines
    (ai_migrate lz_marines/left lz_marines/left_marines_advance)
    (ai_migrate lz_marines/right lz_marines/right_marines_assault)
    (ai_renew lz_marines)

    ;; Make the camp retreat
    (ai_retreat lz/camp)
    (ai_migrate lz/mid_camp_jackals lz/core_cleanup)
    (if (not m_lz_sidepath)
        (ai_migrate lz/camp_low_again lz/core_cleanup)
    )

    ;; Place the core if it wasn't sent out before
    (if (not m_lz_coreplaced)
        (begin
            (ai_place lz/core_elites)
            (ai_place lz/core_grunts)
            (ai_attack lz/core)
            (if m_lz_sidepath
                (begin
                    (ai_migrate lz/core_elites lz/camp_low_again)
                    (ai_migrate lz/core_grunts lz/camp_low_again)
                    (ai_attack lz/core)
                    (ai_attack lz/camp_low_again)
                )
            )
        )
    )

    ;; Players can save before the core breaks
    (game_save_no_timeout)

    ;; wWit for a player to move up or for the core to get its ass kicked
    (sleep_until
        (or
            (volume_test_players_any lz_beach_threshold)
            (< (ai_living_count lz/core) 3)
        )
        5
    )
    (set m_lz_state blz_core_tapped)

    ;; Fix straggling Marine assholes
    (if (not (volume_test_objects lz_beach_main (ai_actors lz_marines)))
        (ai_command_list lz_marines move_forwards)
    )

    ;; Move up the Marines
    (ai_migrate lz_marines/right lz_marines/right_marines_advance)
    (ai_renew lz_marines)

    ;; Have the core fall back
    (ai_defend lz/core)
    (ai_migrate lz/camp_low_again lz/core_cleanup)

    ;; Players can save again before the final assault
    (game_save_no_timeout)

    ;; Put on the new music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01_insertion")
    (music_start "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01a_insertion_end")

    ;; Wait for the core encounter to get its ass totally kicked
    (sleep_until
        (or
            (and
                (<= (ai_living_count lz/core) 2)
                (<= (ai_living_count lz/camp_high) 2)
            )
            (volume_test_players_any lz_beach_threshold)
        )
        5
    )
    (set m_lz_state blz_core_crossed)

    ;; Move up the marines
    (ai_migrate lz_marines lz_marines/marines_core)
    (ai_renew lz_marines)

    ;; Have the core regroup
    (ai_migrate lz/core lz/core_cleanup)

    ;; Place the final wave
    (if (game_is_easy)
        (ai_place lz/final_grunts_easy)
        (ai_place lz/final_brutes)
    )
    (ai_place lz/final_jackals)
    (ai_place lz/final_grunts)
    (ai_migrate lz/final_grunts_easy lz/final_grunts)

    ;; Have the snipers fall back to aid their bros
    (ai_maneuver lz/snipers)

    ;; Save the game, jesus christ
    (game_save_no_timeout)

    ;; Wait for the Covenant to be almost eliminated
    (sleep_until
        (or
            (volume_test_players_any lz_beach_final)
            (< (ai_living_count lz) 7)
        )
        5
    )
    (set m_lz_state blz_cov_pushed)

    ;; Move up the marines
    (ai_migrate lz_marines lz_marines/marines_arch)
    (ai_renew lz_marines)

    ;; Make the final group attack if it was not already
    (ai_attack lz/final)

    ;; Save the game, jesus christ
    (game_save_no_timeout)

    ;; Have the main covenant group become stragglers, also no fuckers allowed to hide in the turrets
    (vehicle_unload lz_turret_high "gunner")
    (vehicle_unload lz_turret_low "gunner")
    (ai_migrate lz/recon lz/stragglers_cleanup)
    (ai_migrate lz/camp lz/stragglers_cleanup)
    (ai_migrate lz/camp_low lz/stragglers_cleanup)
    (ai_migrate lz/core lz/stragglers_cleanup)
    (ai_migrate lz/snipers lz/stragglers_cleanup)
    (ai_migrate lz/turret_gunner_high lz/stragglers_cleanup)
    (ai_migrate lz/turret_gunner_low lz/stragglers_cleanup)

    ;; Wait for the Covenant to be hanging on for dear life
    (sleep_until
        (or
            (volume_test_players_any lz_beach_final)
            (< (ai_living_count lz) 4)
        )
        5
    )
    (set m_lz_state blz_cov_broken)

    ;; Everyone is a straggler now
    (ai_migrate lz lz/stragglers_cleanup)

    ;; Move up the marines
    (ai_migrate lz_marines lz_marines/marines_final)

    ;; Save the game, jesus christ
    (game_save_no_timeout)

    ;; Wait for the Covenant to be eliminated as far as any sane man is concerned
    (sleep_until
        (or
            (< (ai_living_count lz) 1)
            (and
                (<= (ai_living_count lz) 1)
                (not (volume_test_objects lz_beach_final (ai_actors lz)))
                (not (volume_test_objects lz_beach_threshold (ai_actors lz)))
            )
        )
        5
    )
    (set m_lz_state blz_cov_dead)

    ;; Regroup the Marines
    (ai_migrate lz_marines lz_marines/end_marines)
    (ai_renew lz_marines)

    ;; Mission complete!
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01a_insertion_end")

    ;; Clean up after yourself
    (sleep -1 m_lz_updater)

    ;; Save the game, jesus christ
    (game_save_no_timeout)

    ;; Done
    (set m_lz_state blz_finished)
)

;; ---
;; Main things

(script dormant m_lz_progression
    ;; Start with insertion cutscene
    (wake m_lz_cutscene_insertion)

    ;; Wait for insertion
    (sleep_until (>= mission_state mission_inserted))

    ;; Activate combat sequence
    (wake m_lz_combat)

    ;; Wait for the player to actually clear the beach or get so far away that it no longer matters
    (sleep_until
        (or
            (= m_lz_state blz_finished)
            (= bsp_index_ext_lid (structure_bsp_index))
            (= bsp_index_ext_cart (structure_bsp_index))
        )
    )

    ;; LZ secure
    (set mission_lz_cleared true)
)

(script static void m_lz_launch
    ;; BSP & spawn point
    ;; This is just a temporary holding place, so we can put both players there
    (switch_bsp bsp_index_ext_lz)
    (teleport_players m_lz_spawn m_lz_spawn)
    
    ;; We have to kill these, otherwise they break the intro cutscene
    (object_destroy_containing "spray")

    ;; Try and minimize texture hitching
    (object_type_predict "cmt\scenery\_shared\c_storage\scenery\c_storage")
    (object_type_predict "cmt\characters\evolved\grunt\bipeds\grunt_minor")
    (object_type_predict "cmt\characters\evolved\jackal\bipeds\jackal_minor")
    (object_type_predict "cmt\characters\evolved\elite\bipeds\elite_combat_minor")
    (object_type_predict "cmt\characters\evolved\brute\bipeds\brute_follower_minor")
    
    ;; Begin a cinematic for FOV purposes, but keep the letterbox off until we need it
    (show_hud false)
    (player_enable_input false)
    (cinematic_start)
    (cinematic_show_letterbox false)
    
    ;; Set the scene, but secretly pre-warm a couple of camera points to avoid demand-load hitches later
    (camera_control true)
    (camera_set cutscene_insertion_2b 0)
    (skip_frame)
    (camera_set cutscene_insertion_3a 0)
    (skip_frame)
    (camera_set cutscene_insertion_1a 0)

    ;; Set up is complete, fade in
    (fade_from_black)

    ;; Done. The rest is up to the cutscene
)

(script static void m_lz_start
    (print_debug "m_lz_start")

    ;; Launch mission if we have to
    (if (= b30r_launch_lz mission_launch_index)
        (m_lz_launch)
    )

    ;; Start up progression
    (wake m_lz_progression)
)

(script static void m_lz_clean
    ;; If we're cleaning before the mission is completed, make it look like a big cool fight happened
    (if (> blz_finished m_lz_state)
        (ai_kill lz)
    )

    ;; Make sure grenades are usable
    (ai_grenades true)

    ;; Kill updater scripts
    (sleep -1 m_lz_combat)
    (sleep -1 m_lz_updater)
    (sleep -1 m_lz_progression)

    ;; Kill music
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01_insertion")
    (music_stop "cmt\sounds\music\scenarios\b30_revamp\main\b30_revamp_01a_insertion_end")

    ;; Erase remaining enemies
    (ai_erase lz)

    ;; You uh, did it.
    (set mission_lz_cleared true)
)

(script static void m_lz_skip
    ;; LZ has been cleared, player has been inserted
    (set mission_state mission_inserted)
    (set mission_lz_cleared true)

    ;; LZ objects are here
    (object_create_containing lz_wraith_d)
    (object_create lz_wraith_cover)
    (object_create_containing lz_dump)
    (object_create_containing lz_elev_dump)
    (ai_place lz_marines/left_marines)
    (ai_migrate lz_marines lz_marines/end_marines)
)

;; ---
;; Control scripts

;; 0 - Inactive
;; 1 - Active
;; 2 - Skip
;; 3 - End
(global long m_lz_ctrl_state 0)

(script dormant m_lz_control
    (if (!= m_lz_ctrl_state 1)
        (m_lz_skip)
        (m_lz_start)
    )

    (sleep_until (>= m_lz_ctrl_state 3))
    (m_lz_clean)
)

(script static void m_lz_startup
    (if (= 0 m_lz_ctrl_state)
        (begin
            (set m_lz_ctrl_state 1)
            (wake m_lz_control)
        )
    )
)

(script static void m_lz_cleanup
    (set m_lz_ctrl_state 3)
)

(script static void m_lz_mark_skip
    (m_lz_startup)
    (set m_lz_ctrl_state 2)
)
