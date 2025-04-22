;; 02_evolved.hsc
;; Scripts and helpers specific to Evolved content
;; ---

;; ---
;; Game state management

(script static boolean game_is_easy
    (= easy (game_difficulty_get_real))
)

(script static boolean game_is_impossible
    (= impossible (game_difficulty_get_real))
)

;; ---
;; Phantom helpers

(script static void (phantom_create_anew (object_name name) (object_name grav_name) (object_name gun_l_name) (object_name gun_r_name) (object_name troop_l_name) (object_name troop_r_name))
    (object_create_anew name)
    (object_create_anew grav_name)
    (object_create_anew gun_l_name)
    (object_create_anew gun_r_name)
    (object_create_anew troop_l_name)
    (object_create_anew troop_r_name)

    (objects_attach name "gravlift" grav_name "")
    (objects_attach name "turret_door_left" gun_l_name "")
    (objects_attach name "turret_door_right" gun_r_name "")
    (objects_attach name "troop_door_left" troop_l_name "")
    (objects_attach name "troop_door_right" troop_r_name "")

    (unit_set_desired_flashlight_state (unit grav_name) false)
    (unit_close (unit grav_name))
    (unit_close (unit gun_l_name))
    (unit_close (unit gun_r_name))
    (unit_close (unit troop_l_name))
    (unit_close (unit troop_r_name))
)

;; How long the Phantom's bank animation lasts
(global short phantom_bank_time 250)

(script static void (phantom_hover_and_bank (vehicle phantom))
    (vehicle_hover phantom true)
    (custom_animation
        phantom
        "cmt\vehicles\_shared\phantom\phantom"
        "cinematic-hover-bank"
        true
    )

    (sleep phantom_bank_time)
)

;; ---
;; X_CAR test helpers for Evolved content

(script static void (evolved_test_hog (vehicle my_vehicle) (unit my_unit))
    (X_CAR_test my_vehicle my_unit "hog_driver" "w-driver" 0 450)
    (X_CAR_test my_vehicle my_unit "hog_passenger" "w-passenger" 0 450)
    (X_CAR_test my_vehicle my_unit "hog_gunner" "w-gunner" 0 450)
)

(script static void (evolved_test_rhog (vehicle my_vehicle) (unit my_unit))
    (X_CAR_test my_vehicle my_unit "hog_driver" "w-driver" 0 450)
    (X_CAR_test my_vehicle my_unit "hog_passenger" "w-passenger" 0 450)
    (X_CAR_test my_vehicle my_unit "hog_gunner_rocket" "w-gunner" 0 450)
)

(script static void (evolved_test_ghost (vehicle my_vehicle) (unit my_unit))
    (X_CAR_test my_vehicle my_unit "ghost_driver" "g-driver" 1 200)
)

(script static void (evolved_test_shade (vehicle my_vehicle) (unit my_unit))
    (X_CAR_test my_vehicle my_unit "shade_gunner" "ball-gunner" 1 100)
)

(script static void (evolved_test_wraith (vehicle my_vehicle) (unit my_unit))
    (X_CAR_test my_vehicle my_unit "wraith_driver" "wraith-driver" 1 600)
)

;; ---
;; X_VMG events for Evolved vehicles

(script static void (X_VMG_on_entry (vehicle my_vehicle) (string id))
    (if (= "wraith_driver" id)
        (begin
            ;; Wraiths need to kick out their Covenant riders, and reset their enterable state
            (print_debug "X_VMG_on_entry: player entered wraith, kicking out riders and resetting AI enterability")
            (vehicle_unload my_vehicle "scorpion")
            (ai_vehicle_enterable_disable my_vehicle)

            ;; Now, friendly teams are allowed in
            (print_debug "X_VMG_on_entry: enabling friendly AI entrance")
            (ai_vehicle_enterable_team my_vehicle human)
            (ai_vehicle_enterable_distance my_vehicle 10)
        )
    )
)

(script static void (X_VMG_on_exit (vehicle my_vehicle) (string id))
    (if (= "wraith_driver" id)
        (begin
            ;; Wraiths need to kick out their human riders, and reset their enterable state
            (print_debug "X_VMG_on_exit: player exited wraith, kicking out riders and resetting AI enterability")
            (vehicle_unload my_vehicle "scorpion")
            (ai_vehicle_enterable_disable my_vehicle)

            ;; Now, hostile teams are allowed in
            (print_debug "X_VMG_on_exit: enabling hostile AI entrance")
            (ai_vehicle_enterable_team my_vehicle covenant)
            (ai_vehicle_enterable_distance my_vehicle 10)

            ;; Skip to make sure the AI are on the new BSP. Otherwise, they may still freeze
            ;; Add 3-second timeout for safety, if an Elite immediately steals the Wraith or something
            (print_debug "X_VMG_on_exit: waiting for vehicle to be empty")
            (sleep_until (= 0 (list_count (vehicle_riders my_vehicle))) 1 90) 

            ;; Migrate former riders to the correct BSP
            (print_debug "X_VMG_on_exit: migrating riders to bsp target")
            (if X_DBG_enabled
                (inspect (list_count (vehicle_riders my_vehicle)))
            )
            (if (!= none X_VMG_target)
                (ai_migrate_by_unit (vehicle_riders my_vehicle) X_VMG_target)
            )
        )
    )
)

;; ---
;; X_WPN implementation for Evolved weapons

;; X_WPN_find_object implementations assume that all Evolved scenarios have the listed substitute 
;; weapon objects for all players, for all non-egg weapons, with exactly-correct names.

(script static void (X_WPN_test_list (unit my_unit))
    (X_WPN_test my_unit "ar"   "cmt\weapons\evolved\assault_rifle\assault_rifle")
    (X_WPN_test my_unit "argl" "cmt\weapons\evolved\assault_rifle\_assault_rifle_grenade\assault_rifle_grenade")
    (X_WPN_test my_unit "br"   "cmt\weapons\evolved\battle_rifle\battle_rifle")
    (X_WPN_test my_unit "bs"   "cmt\weapons\evolved\brute_shot\brute_shot")
    (X_WPN_test my_unit "cbn"  "cmt\weapons\evolved\carbine\carbine")
    (X_WPN_test my_unit "dmr"  "cmt\weapons\evolved\dmr\dmr")
    (X_WPN_test my_unit "ne"   "cmt\weapons\evolved\needler\needler")
    (X_WPN_test my_unit "hp"   "cmt\weapons\evolved\pistol\pistol")
    (X_WPN_test my_unit "shp"  "cmt\weapons\evolved\pistol\spistol")
    (X_WPN_test my_unit "pp"   "cmt\weapons\evolved\plasma_pistol\plasma_pistol")
    (X_WPN_test my_unit "pr"   "cmt\weapons\evolved\plasma_rifle\plasma_rifle")
    (X_WPN_test my_unit "rl"   "cmt\weapons\evolved\rocket_launcher\rocket_launcher")
    (X_WPN_test my_unit "sg"   "cmt\weapons\evolved\shotgun\shotgun")
    (X_WPN_test my_unit "shrd" "cmt\weapons\evolved\shredder\shredder")
    (X_WPN_test my_unit "sr"   "cmt\weapons\evolved\sniper_rifle\sniper_rifle")
    (X_WPN_test my_unit "spkr" "cmt\weapons\evolved\spiker\spiker")
)

(script static string (X_WPN_find_marker (string weapon_id))
    (cond
        (
            (or
                (= "ar" weapon_id)
                (= "argl" weapon_id)
                (= "br" weapon_id)
                (= "cbn" weapon_id)
                (= "dmr" weapon_id)
                (= "sg" weapon_id)
            )
            "backpack"
        )
        (
            (or
                (= "ne" weapon_id)
                (= "hp" weapon_id)
                (= "shp" weapon_id)
                (= "pp" weapon_id)
                (= "pr" weapon_id)
                (= "shrd" weapon_id)
                (= "spkr" weapon_id)
            )
            "holster"
        )
        (
            (= "bs" weapon_id)
            "backpack-bs"
        )
        (
            (= "rl" weapon_id)
            "backpack-rl"
        )
        (
            (= "sr" weapon_id)
            "backpack-sr"
        )
    )
)

;; CO-OP: In case of more players, add more implementations
;; You'll need to add more backpack weapon objects for them to use, too. Good luck.

;; A (cond) testing all IDs will overflow the stack, as (cond) is simply sugar for nested (if) blocks.
;; To hack around this, use a flat list of (if) conditions, set this variable when one is true, and return it instead.
(global object HACK_find_object_return_player0 none)
(script static object (X_WPN_find_object_player0 (string weapon_id))
    (set HACK_find_object_return_player0 none)
    
    (if (= "ar" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_ar)
    )
    (if (= "argl" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_argl)
    )
    (if (= "br" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_br)
    )
    (if (= "bs" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_bs)
    )
    (if (= "cbn" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_cbn)
    )
    (if (= "dmr" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_dmr)
    )
    (if (= "ne" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_ne)
    )
    (if (= "hp" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_hp)
    )
    (if (= "shp" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_shp)
    )
    (if (= "pp" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_pp)
    )
    (if (= "pr" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_pr)
    )
    (if (= "rl" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_rl)
    )
    (if (= "sg" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_sg)
    )
    (if (= "shrd" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_shrd)
    )
    (if (= "sr" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_sr)
    )
    (if (= "spkr" weapon_id)
        (set HACK_find_object_return_player0 backpack_0_spkr)
    )
    
    HACK_find_object_return_player0
)

;; A (cond) testing all IDs will overflow the stack, as (cond) is simply sugar for nested (if) blocks.
;; To hack around this, use a flat list of (if) conditions, set this variable when one is true, and return it instead.
(global object HACK_find_object_return_player1 none)
(script static object (X_WPN_find_object_player1 (string weapon_id))
    (set HACK_find_object_return_player1 none)
    
    (if (= "ar" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_ar)
    )
    (if (= "argl" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_argl)
    )
    (if (= "br" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_br)
    )
    (if (= "bs" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_bs)
    )
    (if (= "cbn" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_cbn)
    )
    (if (= "dmr" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_dmr)
    )
    (if (= "ne" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_ne)
    )
    (if (= "hp" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_hp)
    )
    (if (= "shp" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_shp)
    )
    (if (= "pp" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_pp)
    )
    (if (= "pr" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_pr)
    )
    (if (= "rl" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_rl)
    )
    (if (= "sg" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_sg)
    )
    (if (= "shrd" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_shrd)
    )
    (if (= "sr" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_sr)
    )
    (if (= "spkr" weapon_id)
        (set HACK_find_object_return_player1 backpack_1_spkr)
    )
    
    HACK_find_object_return_player1
)