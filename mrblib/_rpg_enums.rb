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
      MoveUp = 0, MoveRight = 1, MoveDown = 2, MoveLeft = 3,
      MoveUpright = 4, MoveDownright = 5, MoveDownleft = 6, MoveUpleft = 7,
      MoveRandom = 8, MoveTowardsHero = 9, MoveAwayFromHero = 10, MoveForward = 11,
      FaceUp = 12, FaceRight = 13, FaceDown = 14, FaceLeft = 15,
      Turn90DegreeRight = 16, Turn90DegreeLeft = 17, Turn180Degree = 18, Turn90DegreeRandom = 19,
      FaceRandomDirection = 20, FaceHero = 21, FaceAwayFromHero = 22, Wait = 23,
      BeginJump = 24, EndJump = 25, LockFacing = 26, UnlockFacing = 27,
      IncreaseMovementSpeed = 28, DecreaseMovementSpeed = 29, IncreaseMovementFrequence = 30, DecreaseMovementFrequence = 31,
      SwitchOn = 32, SwitchOff = 33, ChangeGraphic = 34, PlaySoundEffect = 35,
      WalkEverywhereOn = 36, WalkEverywhereOff = 37, StopAnimation = 38, StartAnimation = 39,
      IncreaseTransp = 40, DecreaseTransp = 41
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

module Passable
  Down = 0x01
  Left = 0x02
  Right = 0x04
  Up = 0x08

  Above = 0x10
  Wall = 0x20
  Counter = 0x40
end

BLOCK_C = 3000
BLOCK_D = 4000
BLOCK_D_BLOCKS = 12
BLOCK_E = 5000
BLOCK_E_TILES = 144
BLOCK_F = 10000
BLOCK_F_TILES = 144
