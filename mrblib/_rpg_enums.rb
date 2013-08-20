module RPG
	class Item
    Type_normal = 0, Type_weapon = 1, Type_shield = 2, Type_armor = 3,
    Type_helmet = 4, Type_accessory = 5, Type_medicine = 6, Type_book = 7,
    Type_material = 8, Type_special = 9, Type_switch = 10
	end

	class BattleCommand
    Type_attack = 0, Type_skill = 1, Type_subskill = 2, Type_defense = 3,
    Type_item = 4, Type_escape = 5, Type_special = 6
	end

	class Skill
		Type_normal = 0, Type_teleport = 1, Type_escape = 2, Type_switch = 3

		SpType_cost = 0, SpType_percent = 1

    Scope_enemy = 0, Scope_enemies = 1, Scope_self = 2, Scope_ally = 3,
    Scope_party = 4
	end

	class MoveCommand
		class Code
      move_up = 0, move_right = 1, move_down = 2, move_left = 3,
      move_upright = 4, move_downright = 5, move_downleft = 6, move_upleft = 7,
      move_random = 8, move_towards_hero = 9, move_away_from_hero = 10, move_forward = 11,
      face_up = 12, face_right = 13, face_down = 14, face_left = 15,
      turn_90_degree_right = 16, turn_90_degree_left = 17, turn_180_degree = 18, turn_90_degree_random = 19,
      face_random_direction = 20, face_hero = 21, face_away_from_hero = 22, wait = 23,
      begin_jump = 24, end_jump = 25, lock_facing = 26, unlock_facing = 27,
      increase_movement_speed = 28, decrease_movement_speed = 29, increase_movement_frequence = 30, decrease_movement_frequence = 31,
      switch_on = 32, switch_off = 33, change_graphic = 34, play_sound_effect = 35,
      walk_everywhere_on = 36, walk_everywhere_off = 37, stop_animation = 38, start_animation = 39,
      increase_transp = 40, decrease_transp = 41
		end
	end

	class EnemyAction
		Kind_basic = 0, Kind_skill = 1, Kind_transformation = 2

    Basic_attack = 0, Basic_dual_attack = 1, Basic_defense = 2, Basic_observe = 3,
    Basic_charge = 4, Basic_autodeclassion = 5, Basic_escape = 6, Basic_nothing = 7

    ConditionType_always = 0, ConditionType_switch = 1, ConditionType_turn = 2, ConditionType_actors = 3,
    ConditionType_hp = 4, ConditionType_sp = 5, ConditionType_party_lvl = 6, ConditionType_party_fatigue = 7
	end

	class EventPage
		Direction_up = 0, Direction_right = 1, Direction_down = 2, Direction_left = 3
		Frame_left = 0, Frame_middle = 1, Frame_right = 2

    MoveType_stationary = 0, MoveType_random = 1, MoveType_vertical = 2, MoveType_horizontal = 3,
    MoveType_toward = 4, MoveType_away = 5, MoveType_custom = 6

    Trigger_action = 0, Trigger_touched = 1, Trigger_collision = 2, Trigger_auto_start = 3,
    Trigger_parallel = 4

		Layers_below = 0, Layers_same = 1, Layers_above = 2

    AnimType_non_continuous = 0, AnimType_continuous = 1, AnimType_fixed_non_continuous = 2, AnimType_fixed_continuous = 3,
    AnimType_fixed_graphic = 4, AnimType_spin = 5

    MoveSpeed_eighth = 1, MoveSpeed_quarter = 2, MoveSpeed_half = 3, MoveSpeed_normal = 4,
    MoveSpeed_double = 5, MoveSpeed_fourfold = 6
	end
end
