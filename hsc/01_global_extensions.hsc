;; 01_global_extensions.hsc
;; Globally-available modular extensions, useful for all mods
;; ---

;; --- EXTENSION: X_DBG ---
;; Debugging helpers
;; REQUIRES: None
;;
;; This gates some handy debugging features behind the `X_DBG_enabled` variable.
;; Debug features are off by default. `(set X_DBG_enabled true)` to turn debug features on.
;;
;; Ensure that debug features are OFF in your shipped map. These exist only to assist development!
;;
;; For clarity and convenience, the `print_debug` helpers don't use the X_DBG module prefix.

(global boolean X_DBG_enabled false)

(script static void (print_debug (string message))
    (if X_DBG_enabled
        (print message)
    )
)

(script static void (print_debug_if (boolean condition) (string message))
    (print_if (and X_DBG_enabled condition) message)
)

(script startup X_DBG_set_devmode
    (sleep_until X_DBG_enabled)
    (set developer_mode 127)
)

(script continuous X_DBG_notify_safe_to_save
    (if (not X_DBG_enabled)
        (sleep -1)
    )
    
    ;; Alert when safe
    (sleep_until (game_safe_to_save))
    (print_debug "X_DBG_notify_safe_to_save: game safe to save")

    ;; Alert when unsafe
    (sleep_until (not (game_safe_to_save)))
    (print_debug "X_DBG_notify_safe_to_save: game not safe to save")
)

(script continuous X_DBG_notify_saving
    ;; Alert when trying to save
    (sleep_until (game_saving))
    (print_debug "X_DBG_notify_saving: ...attempting to save game...")

    ;; Alert when successfully saved, or timeout after a few seconds
    (sleep_until (not (game_saving)) 150)
    (print_debug_if (not (game_saving)) "X_DBG_notify_saving: game-save attempt done")
)

;; --- EXTENSION: X_HLP ---
;; Help text utilities
;; REQUIRES: X_DBG
;;
;; Stock HCE has a lot of duplicate boilerplate for displaying & flashing help text. This module provides
;; all that generically. It also provides the ability to notify the user if a checkpoint is trying to save,
;; but currently can't, which is helpful given how stingy HCE checkpoints are.
;;
;; To use this module, your scenario needs to define HUD messages with these names & content:
;;   - checkpoint_new: "Checkpoint..."
;;   - checkpoint_blocked: "Area not safe - waiting to save checkpoint...", or similar
;;
;; Once that's done, you can simply set `X_HLP_desired` to a HUD message to display and blink it automatically!
;; Note that we use "checkpoint_new" as a default value, since `none` isn't valid for type hud_message.

(global hud_message X_HLP_desired "checkpoint_new")

(global boolean X_HLP_displaying false)

(script continuous X_HLP_blinker
    ;; Wait until we have something to display
    (print_debug "X_HLP_blinker: waiting for next cycle")
    (sleep_until (!= X_HLP_desired "checkpoint_new") 1)

    ;; Turn it on
    (print_debug "X_HLP_blinker: new help text received")
    (show_hud_help_text true)
    (hud_set_help_text X_HLP_desired)
    (set X_HLP_displaying true)
    
    ;; Clear the desired variable for next time
    (set X_HLP_desired "checkpoint_new")

    ;; Wait a bit, then bring up the flash before it goes away
    (print_debug "X_HLP_blinker: waiting for blink")
    (sleep 180)
    (enable_hud_help_flash true)
    (sleep 120)

    ;; Turn it off and reset the display variable
    (print_debug "X_HLP_blinker: done")
    (show_hud_help_text false)
    (enable_hud_help_flash false)
    (set X_HLP_displaying false)
)

(script continuous X_HLP_checkpoint
    ;; Wait until we're trying to save the game, and no help text is displaying
    (print_debug "X_HLP_checkpoint: awaiting for clear help text & saving game")
    (sleep_until
        (and
            (game_saving)
            (not X_HLP_displaying)
        )
        1
    )

    ;; Turn on "Checkpoint..."
    (print_debug "X_HLP_checkpoint: turning on checkpoint text")
    (show_hud_help_text true)
    (hud_set_help_text "checkpoint_new")

    ;; NOTE: All timeouts below are lined up *exactly* with the regular help text blinker.
    ;; Don't mess with them!

    ;; Wait until either the game has successfully saved, or the timeout was hit
    (print_debug "X_HLP_checkpoint: awaiting first timeout")
    (sleep_until (not (game_saving)) 1 30)

    ;; If the game is still trying to save, bring up the "area not safe" alert as a standard message
    (if (game_saving)
        (begin
            (print_debug "X_HLP_checkpoint: game still saving, flashing message")
            (set X_HLP_desired "checkpoint_blocked")
            
            ;; Set another, longer timeout. If this expires, we'll just hide the message for a while
            (sleep_until (not (game_saving)) 1 300)
        )
    )

    ;; If the game successfully saved this time, we can turn off help text immediately.
    (print_debug_if (not (game_saving)) "X_HLP_checkpoint: game saved, turning off message")
    (if (not (game_saving))
        (show_hud_help_text false)
    )

    ;; Otherwise, set one last timeout while waiting for a successful save, and loop once either happens
    (print_debug "X_HLP_checkpoint: awaiting next cycle")
    (sleep_until (not (game_saving)) 1 300)
)

;; --- EXTENSION: X_HFX ---
;; Health damage effects
;; REQUIRES: None
;;
;; This plays some global camera-shake damage effects when a player takes health damage, intended to
;; emphasize vulnerability. Damage is detected by remembering each player's last health value, and
;; checking if the current value is less than that.

(script static void (X_HFX_apply (unit my_unit) (real last_health))
    ;; Has this unit taken damage since the last update?
    (if (> last_health (unit_get_health my_unit))
        ;; Was it a lot of damage?
        (if (> (- last_health (unit_get_health my_unit)) 0.34)
            (damage_object "cmt\globals\_shared\damage_effects\health_damage_weak" my_unit)
            (damage_object "cmt\globals\_shared\damage_effects\health_damage_strong" my_unit)
        )
    )
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(global real X_HFX_last_health_player0 0)
(script continuous X_HFX_update_player0
    (X_HFX_apply (player0) X_HFX_last_health_player0)
    (set X_HFX_last_health_player0 (unit_get_health (player0)))
)

(global real X_HFX_last_health_player1 0)
(script continuous X_HFX_update_player1
    (X_HFX_apply (player1) X_HFX_last_health_player1)
    (set X_HFX_last_health_player1 (unit_get_health (player1)))
)

;; --- EXTENSION: X_WPN ---
;; Weapon detection & substitution
;; REQUIRES: None
;;
;; This lets scripts detect which weapons each player is currently using, and correlate those weapons with
;; scenario-specific substitute objects. (We used these objects for backpack weapons & cutscenes.)
;; 
;; Weapons are identified with a string ID, so client code doesn't have to constantly pass huge tag references around.
;;
;; The module requires that your mod implement `(X_WPN_test_list)`, which tests all weapon tags to see
;; if a player is using one of them.
;;
;; This should look like:
;;   (script static void (X_WPN_test_list (unit my_unit))
;;       (X_WPN_test my_unit "ar" "my_mod\weapons\assault_rifle\assault_rifle")
;;       (X_WPN_test my_unit "pr" "my_mod\weapons\plasma_rifle\plasma_rifle")
;;       ;; ... all other weapon tests ...
;;   )
;;
;; The first line tests if a player unit is using the weapon represented by the assault_rifle tag.
;; If so, the system will set that unit's weapon ID to "ar". Units have both primary (held) and secondary
;; (stowed) weapon IDs.
;;
;; See evolved_extensions.hsc for a practical example of how this is meant to work.

;; (script static void (X_WPN_test_list (unit my_unit))
(script stub void X_WPN_test_list
    (print "UNIMPLEMENTED: X_WPN_test_list")
)

;; (script static string (X_WPN_find_marker (string weapon_id))
(script stub string X_WPN_find_marker
    (print "UNIMPLEMENTED: X_WPN_find_marker")
    ""
)

;; (script static object (X_WPN_find_object_player0 (string weapon_id))
(script stub void X_WPN_find_object_player0
    (print "UNIMPLEMENTED: X_WPN_find_object_player0")
)

;; (script static object (X_WPN_find_object_player1 (string weapon_id))
(script stub void X_WPN_find_object_player1
    (print "UNIMPLEMENTED: X_WPN_find_object_player1")
)

;; Weapon testing internals

(global string X_WPN_test_id_primary "")
(global string X_WPN_test_id_secondary "")

(script static void X_WPN_test_reset
    (set X_WPN_test_id_primary "")
    (set X_WPN_test_id_secondary "")
)

(script static void (X_WPN_test (unit my_unit) (string weapon_id) (object_definition weapon_tag))
    (if (unit_has_weapon my_unit weapon_tag)
        (if (unit_has_weapon_readied my_unit weapon_tag)
            (set X_WPN_test_id_primary weapon_id)
            (set X_WPN_test_id_secondary weapon_id)
        )
    )
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(global string X_WPN_id_primary_player0 "")
(global string X_WPN_id_secondary_player0 "")

(script continuous X_WPN_update_player0
    (X_WPN_test_reset)
    (X_WPN_test_list (player0))
    
    (set X_WPN_id_primary_player0 X_WPN_test_id_primary)
    (set X_WPN_id_secondary_player0 X_WPN_test_id_secondary)
)

(global string X_WPN_id_primary_player1 "")
(global string X_WPN_id_secondary_player1 "")

(script continuous X_WPN_update_player1
    (X_WPN_test_reset)
    (X_WPN_test_list (player1))
    
    (set X_WPN_id_primary_player1 X_WPN_test_id_primary)
    (set X_WPN_id_secondary_player1 X_WPN_test_id_secondary)
)

;; --- EXTENSION: X_BPK ---
;; Backpack weapons
;; REQUIRES: X_WPN
;;
;; This adds "backpack weapon" support, i.e. displaying a player unit's stowed weapon on the
;; unit itself.

;; Internals

(script static void (X_BPK_attach (object attach_target) (object substitute) (string weapon_id))
    (if (!= "" weapon_id)
        (objects_attach attach_target (X_WPN_find_marker weapon_id) substitute "")
    )
)

(script static void (X_BPK_detach (object attach_target) (object substitute))
    (objects_detach attach_target substitute)
    (object_teleport substitute the_void)
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(global string X_BPK_id_player0 "")
(global object X_BPK_object_player0 none)

(script continuous X_BPK_update_player0
    ;; Is this player's secondary weapon different than the one we're currently substituting?
    (if (!= X_WPN_id_secondary_player0 X_BPK_id_player0)
        (begin
            ;; Detach old substitute
            (X_BPK_detach (player0) X_BPK_object_player0)

            ;; Update weapon ID and object
            (set X_BPK_id_player0 X_WPN_id_secondary_player0)
            (set X_BPK_object_player0 (X_WPN_find_object_player0 X_BPK_id_player0))
            
            ;; Attach new substitute
            (X_BPK_attach (player0) X_BPK_object_player0 X_BPK_id_player0)
        )
    )
)

(script static void X_BPK_disable_player0
    (sleep -1 X_BPK_update_player0)
    (X_BPK_detach (player0) X_BPK_object_player0)
    
    (set X_BPK_id_player0 "")
    (set X_BPK_object_player0 none)
)

(global string X_BPK_id_player1 "")
(global object X_BPK_object_player1 none)

(script continuous X_BPK_update_player1
    ;; Is this player's secondary weapon different than the one we're currently substituting?
    (if (!= X_WPN_id_secondary_player1 X_BPK_id_player1)
        (begin
            ;; Detach old substitute
            (X_BPK_detach (player1) X_BPK_object_player1)
            
            ;; Update weapon ID and object
            (set X_BPK_id_player1 X_WPN_id_secondary_player1)
            (set X_BPK_object_player1 (X_WPN_find_object_player1 X_BPK_id_player1))
            
            ;; Attach new substitute
            (X_BPK_attach (player1) X_BPK_object_player1 X_BPK_id_player1)
        )
    )
)

(script static void X_BPK_disable_player1
    (sleep -1 X_BPK_update_player1)
    (X_BPK_detach (player1) X_BPK_object_player1)
    
    (set X_BPK_id_player1 "")
    (set X_BPK_object_player1 none)
)

;; --- EXTENSION: X_CUT ---
;; Unit & weapon substitutions for cutscenes
;; REQUIRES: X_WPN, X_BPK
;;
;; This allows cutscenes to set up a substitute unit, displaying substitute weapons equivalent to a
;; player unit's actual held weapons.
;;
;; These helpers take care of both object creation & destruction themselves: just call `X_CUT_setup` on
;; your unit to bring it and its weapons into existence, and `X_CUT_teardown` to destroy & reset them.
;;
;; Note that this depends on the backpack weapons module (X_BPK). This allows the system to interact
;; gracefully with backpack weapons, so that they can automatically share the same substitute objects.

(script static void (X_CUT_setup (object_name cutscene_unit) (object primary) (object secondary) (string secondary_id))
    ;; Create the substitute unit
    (object_create cutscene_unit)
    
    ;; Attach primary weapon to the right hand
    (objects_attach cutscene_unit "right hand" primary "")
    
    ;; Attach secondary weapon to its marker
    (objects_attach cutscene_unit (X_WPN_find_marker secondary_id) secondary "")
)

(script static void (X_CUT_teardown (object_name cutscene_unit) (object primary) (object secondary))
    ;; Detach weapons
    (objects_detach cutscene_unit primary)
    (objects_detach cutscene_unit secondary)
    
    ;; Teleport them back to the void
    (object_teleport primary the_void)
    (object_teleport secondary the_void)
    
    ;; Destroy the substitute unit
    (object_destroy cutscene_unit)
)

;; Player-specific cutscene events
;; CO-OP: In case of more players, add more events

(global object X_CUT_primary_player0 none)
(global object X_CUT_secondary_player0 none)

(script static void (X_CUT_setup_player0 (object_name cutscene_unit))
    ;; Disable backpack updater
    (X_BPK_disable_player0)
    
    ;; Find substitutes for this player's weapons
    (set X_CUT_primary_player0 (X_WPN_find_object_player0 X_WPN_id_primary_player0))
    (set X_CUT_secondary_player0 (X_WPN_find_object_player0 X_WPN_id_secondary_player0))
    
    ;; Set up the cutscene unit with these weapons
    (X_CUT_setup cutscene_unit X_CUT_primary_player0 X_CUT_secondary_player0 X_WPN_id_secondary_player0)
)

(script static void (X_CUT_teardown_player0 (object_name cutscene_unit))
    ;; Clean up and destroy the cutscene unit
    (X_CUT_teardown cutscene_unit X_CUT_primary_player0 X_CUT_secondary_player0)
    
    ;; We're not using the weapon substitutes anymore
    (set X_CUT_primary_player0 none)
    (set X_CUT_secondary_player0 none)
    
    ;; Re-enable backpack updater
    (wake X_BPK_update_player0)
)

(global object X_CUT_primary_player1 none)
(global object X_CUT_secondary_player1 none)

(script static void (X_CUT_setup_player1 (object_name cutscene_unit))
    ;; Disable backpack updater
    (X_BPK_disable_player1)
    
    ;; Find substitutes for this player's weapons
    (set X_CUT_primary_player1 (X_WPN_find_object_player1 X_WPN_id_primary_player1))
    (set X_CUT_secondary_player1 (X_WPN_find_object_player1 X_WPN_id_secondary_player1))
    
    ;; Set up the cutscene unit with these weapons
    (X_CUT_setup cutscene_unit X_CUT_primary_player1 X_CUT_secondary_player1 X_WPN_id_secondary_player1)
)

(script static void (X_CUT_teardown_player1 (object_name cutscene_unit))
    ;; Clean up and destroy the cutscene unit
    (X_CUT_teardown cutscene_unit X_CUT_primary_player1 X_CUT_secondary_player1)
    
    ;; We're not using the weapon substitutes anymore
    (set X_CUT_primary_player1 none)
    (set X_CUT_secondary_player1 none)
    
    ;; Re-enable backpack updater
    (wake X_BPK_update_player1)
)

;; --- EXTENSION: X_CAR ---
;; Vehicle detection
;; REQUIRES: None
;;
;; This lets scripts detect which vehicle (and seat) each player is currently occupying, if any. Each possible seat
;; is identified with a string ID -- you can then use this to implement behavior specific to a vehicle and / or seat type.
;;
;; The module requires that your scenario implement `(X_CAR_test_list)`, which tests all of its vehicles to see if a player
;; is occupying one of them.
;;
;; This should look like:
;;   (script static void (X_CAR_test_list (unit my_unit))
;;       (X_CAR_test my_ghost_a my_unit "ghost_driver" "g-driver" 0 100)
;;       (X_CAR_test my_ghost_b my_unit "ghost_driver" "g-driver" 0 100)
;;       ;; ... all other vehicle tests ...
;;   )
;;
;; The first line tests if a player unit is occupying the "g-driver" seat in the vehicle named "my_ghost_a".
;; If so, the system will set that unit's vehicle ID to "ghost_driver". (The ghost's max shields & health are also
;; required. This is mainly intended to be propagated to the vehicle health regeneration system.) Subsequent lines
;; then make the same test for other vehicles.
;;
;; You may find it useful to create helper functions for testing vehicle types, so you don't have to repeat seat &
;; vitality information with each test. See evolved_extensions.hsc for an example of how TSC:E does this.

;; (script static void (X_CAR_test_list (unit my_unit))
(script stub void X_CAR_test_list
    (print "UNIMPLEMENTED: X_CAR_test_list")
)

;; Vehicle testing internals

(global vehicle X_CAR_test_vehicle none)
(global string X_CAR_test_id "")
(global real X_CAR_test_max_sd 0)
(global real X_CAR_test_max_hp 0)

(script static void X_CAR_test_reset
    (set X_CAR_test_vehicle none)
    (set X_CAR_test_id "")
    (set X_CAR_test_max_sd 0)
    (set X_CAR_test_max_hp 0)
)

(script static void (X_CAR_test (vehicle my_vehicle) (unit my_unit) (string id) (string seat_label) (real max_shield) (real max_health))
    (if (vehicle_test_seat my_vehicle seat_label my_unit)
        (begin
            (set X_CAR_test_vehicle my_vehicle)
            (set X_CAR_test_id id)
            (set X_CAR_test_max_sd max_shield)
            (set X_CAR_test_max_hp max_health)
        )
    )
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(global vehicle X_CAR_vehicle_player0 none)
(global string X_CAR_id_player0 "")
(global real X_CAR_max_sd_player0 0)
(global real X_CAR_max_hp_player0 0)

(script continuous X_CAR_update_player0
    (X_CAR_test_reset)
    (X_CAR_test_list (player0))
    
    (set X_CAR_vehicle_player0 X_CAR_test_vehicle)
    (set X_CAR_id_player0 X_CAR_test_id)
    (set X_CAR_max_sd_player0 X_CAR_test_max_sd)
    (set X_CAR_max_hp_player0 X_CAR_test_max_hp)
)

(global vehicle X_CAR_vehicle_player1 none)
(global string X_CAR_id_player1 "")
(global real X_CAR_max_sd_player1 0)
(global real X_CAR_max_hp_player1 0)

(script continuous X_CAR_update_player1
    (X_CAR_test_reset)
    (X_CAR_test_list (player1))
    
    (set X_CAR_vehicle_player1 X_CAR_test_vehicle)
    (set X_CAR_id_player1 X_CAR_test_id)
    (set X_CAR_max_sd_player1 X_CAR_test_max_sd)
    (set X_CAR_max_hp_player1 X_CAR_test_max_hp)
)

;; --- EXTENSION: X_VRG ---
;; Vehicle health regeneration
;; REQUIRES: X_CAR
;;
;; This allows player-occupied vehicles to stealthily regenerate health. Vehicles will regenerate up to 1/9 HP --
;; that's equivalent to one "chunk" of the health bar, meaning the bar won't visibly change in response to regeneration.
;;
;; Since health regeneration isn't a native feature of HCE, this simulates a stun timer & regeneration cycle
;; using extra global state per player. (This is why the system is limited only to player-occupied vehicles.)

;; Returns a new stun timer value
(script static real (X_VRG_tick (vehicle my_vehicle) (real max_shield) (real max_health) (real previous_health) (real current_stun_timer))
    (cond
        (
            ;; Vehicle isn't in danger, do nothing
            (< 0.11 (unit_get_health my_vehicle))
            0
        )
        (
            ;; Vehicle just took damage, reset the stun timer
            (> previous_health (unit_get_health my_vehicle))
            60
        )
        (
            ;; Stun timer hasn't yet elapsed, keep decrementing
            (> current_stun_timer 0)
            (max 0 (- current_stun_timer 1))
        )
        (
            ;; Stun timer has elapsed, regenerate health
            true
            
            (unit_set_current_vitality my_vehicle
                (*
                    (+ (unit_get_health my_vehicle) 0.011)
                    max_health
                )
                (* (unit_get_shield my_vehicle) max_shield)
            )
            
            0
        )
    )
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(global real X_VRG_last_hp_player0 0)
(global real X_VRG_stun_timer_player0 0)

(script continuous X_VRG_player0
    (if (!= none X_CAR_vehicle_player0)
        (begin
            (set X_VRG_stun_timer_player0
                (X_VRG_tick
                    X_CAR_vehicle_player0
                    X_CAR_max_sd_player0
                    X_CAR_max_hp_player0
                    X_VRG_last_hp_player0
                    X_VRG_stun_timer_player0
                )
            )
            (set X_VRG_last_hp_player0 (unit_get_health X_CAR_vehicle_player0))
        )
    )
)

(global real X_VRG_last_hp_player1 0)
(global real X_VRG_stun_timer_player1 0)

(script continuous X_VRG_player1
    (if (and
            (!= none X_CAR_vehicle_player1)
            (!= X_CAR_vehicle_player0 X_CAR_vehicle_player1)    ;; Don't double-regen the same vehicle that player0 is in
        )
        (begin
            (set X_VRG_stun_timer_player1
                (X_VRG_tick
                    X_CAR_vehicle_player1
                    X_CAR_max_sd_player1
                    X_CAR_max_hp_player1
                    X_VRG_last_hp_player1
                    X_VRG_stun_timer_player1
                )
            )
            (set X_VRG_last_hp_player1 (unit_get_health X_CAR_vehicle_player1))
        )
    )
)

;; --- EXTENSION: X_VMG ---
;; Automatic AI migration of vehicle passengers
;; REQUIRES: X_CAR
;;
;; Passenger AI, if attached to an encounter, will shit itself if the player enters a different BSP.
;; The simplest way to handle this is to `(ai_free)` passenger AI. For reasons lost to time, we didn't do this.
;;
;; Instead, we set a global migration target encounter, `X_VMG_target`. There should be a different AI migration
;; encounter defined by the scenario for each BSP, and `X_VMG_target` should be set to this encounter whenever a BSP
;; switch occurs.
;;
;; Then, if a player is detected in a vehicle, any AI passengers are automatically migrated to this BSP-specific
;; encounter, ensuring that they stay sane.
;;
;; Sometimes, this requires more than just migration. For this reason, custom `on_entry` and `on_exit` hooks are provided
;; for implementation by your mod. Our mod uses these to kick passengers out of Wraiths, the only Evolved vehicle that
;; can be occupied by AI of both teams -- see evolved_extensions.hsc for an example.
;;
;; If you don't need any custom hooks, feel free to either leave these unimplemented, or implement empty placeholders.

(global ai X_VMG_target none)

;; (script static void (X_VMG_on_entry (vehicle my_vehicle) (string id))
(script stub void X_VMG_on_entry
    (print "UNIMPLEMENTED: X_VMG_on_entry")
)

;; (script static void (X_VMG_on_exit (vehicle my_vehicle) (string id))
(script stub void X_VMG_on_exit
    (print "UNIMPLEMENTED: X_VMG_on_exit")
)

;; Player-specific updaters
;; CO-OP: In case of more players, add more updaters

(script continuous X_VMG_player0
    (if (and
            (!= none X_CAR_vehicle_player0)
            (!= none X_VMG_target)
        )
        (ai_migrate_by_unit (vehicle_riders X_CAR_vehicle_player0) X_VMG_target)
    )
)

(script continuous X_VMG_events_player0
    (sleep_until (!= none X_CAR_vehicle_player0) 1)
    (X_VMG_on_entry X_CAR_vehicle_player0 X_CAR_id_player0)
    
    (sleep_until (= none X_CAR_vehicle_player0) 1)
    (X_VMG_on_exit X_CAR_vehicle_player0 X_CAR_id_player0)
)

(script continuous X_VMG_player1
    (if (and
            (!= none X_CAR_vehicle_player1)
            (!= none X_VMG_target)
        )
        (ai_migrate_by_unit (vehicle_riders X_CAR_vehicle_player1) X_VMG_target)
    )
)

(script continuous X_VMG_events_player1
    (sleep_until (!= none X_CAR_vehicle_player1) 1)
    (X_VMG_on_entry X_CAR_vehicle_player1 X_CAR_id_player1)
    
    (sleep_until (= none X_CAR_vehicle_player1) 1)
    (X_VMG_on_exit X_CAR_vehicle_player1 X_CAR_id_player1)
)