# This file is part of EasyRPG Player.
#
# EasyRPG Player is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# EasyRPG Player is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.

# Game_Interpreter_Battle class.
class Game_Interpreter_Battle < Game_Interpreter
  def initialize(depth, main_flag)
    super depth, main_flag
  end

  def execute_command
    return command_end if @index >= @list.length

    com = @list[@index]

    case com.code
    when Cmd::ElseBranch_B; return skip_to Cmd::EndBranch_B
    when Cmd::EndBranch_B; return true
    else
      super
    end
  end

  def command_call_common_event(com)
    return false if @child_interpreter

    event = Data.commonevents[com[0]]

    @child_interpreter = Game_Interpreter_Battle(depth + 1).new
    @child_interpreter.setup event.event_commands, 0, event.index, -2

    true
  end

  def command_force_flee(com)
    check = com[2] == 0

    case com[0]
    when 0
      Game_Battle.allies_flee = true if
        !check || Game_Temp.battle_mode != Game_Temp::BattlePincer
    when 1
      Game_Battle.MonstersFlee if !check || Game_Temp.battle_mode != Game_Temp::BattleSurround
    when 2
      Game_Battle.monster_flee com[1] if
        !check || Game_Temp.battle_mode != Game_Temp::BattleSurround
    end

    true
  end

  def command_enable_combo(com)
    ally = Game_Battle.find_ally com[0]
    return true if !ally

    ally.enable_combo(com[1], com[2])

    true
  end

  def command_change_monster_hp(com)
    enemy = Game_Battle.enemy com[0]
    hp = enemy.actor.hp

    case (com[2])
    when 0; change = com[3]
    when 1; change = Game_Variables[com[3]]
    when 2; change = com[3] * hp / 100
    end

    change = -change if com[1] > 0
    hp += change
    hp = 1 if (com[4] && hp <= 0)

    enemy.actor.hp = hp

    true
  end

  def command_change_monster_mp(com)
    enemy = Game_Battle.enemy com[0]
    sp = enemy.actor.sp

    case (com[2])
    when 0; change = com[3]
    when 1; change = Game_Variables[com[3]]
    end

    change = -change if com[1] > 0
    sp += change

    enemy.actor.sp = sp

    true
  end

  def command_change_monster_condition(com)
    enemy = Game_Battle.enemy com[0]
    if com[1] > 0; enemy.actor.remove_state com[2]
    else enemy.actor.add_state com[2]
    end
    true
  end

  def command_show_hidden_monster(com)
    Game_Battle.enemy(com[0]).game_enemy.hide false
    true
  end

  def command_change_battle_bg(com)
    Game_Battle.change_background com.string
    true
  end

  def command_show_battle_animation(com)
    target = com[1]
    wait = com[2] != 0
    allies = com[3] != 0

    ally = (allies && target >= 0) ? Game_Battle.find_ally(target) : nil
    enemy = (!allies && target >= 0) ? Game_Battle.enemy(target) : nil

    return !Game_Battle..secene.animation_waiting? if @active

    Game_Battle.scene.show_animation com[0], allies, ally, enemy, wait
    !wait
  end

  def command_terminate_battle(comm)
    Game_Battle.terminate
    true
  end

  def command_conditional_branch(com)
    result = false

    case com[0]
    when 0 # Cases
      result = Game_Casees[com[1]] == (com[2] == 0)
    when 1 # Variable
      value1 = Game_Variables[com[1]]
      if com[2] == 0; value2 = com[3]
      else; value2 = Game_Variables[com[3]]
      end

      case (com[4])
      when 0; result = (value1 == value2)
      when 1; result = (value1 >= value2)
      when 2; result = (value1 <= value2)
      when 3; result = (value1 >  value2)
      when 4; result = (value1 <  value2)
      when 5; result = (value1 != value2)
      end
    when 2 # Hero can act
      ally = Game_Battle.find_ally com[1]
      result = !ally.nil? && ally.can_act?
    when 3 # Monster can act
      result = Game_Battle.enemy(com[1]).can_act?
    when 4 # Monster is the current target
      result = Game_Battle.has_target_enemy && Game_Battle.target_enemy.id == com[1]
    when 5 # Hero uses the ... command
      ally = Game_Battle.find_ally com[1]
      result = !ally.nil? && ally.last_command == com[2]
    end

    return true if result
    return skip_to Cmd::ElseBranch_B, Cmd::EndBranch_B
  end
end
