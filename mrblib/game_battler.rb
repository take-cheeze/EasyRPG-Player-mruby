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

# Game_Battler class.
class Game_Battler
	# Gets if battler has a state.
	#
	# @param state_id database state ID.
	# @return whether the battler has the state.
	def has_state(state_id); not states.find(state_id).nil?; end

	# Gets current battler state with highest priority.
	#
	# @return the highest priority state affecting the battler.
	#         Returns nil if no states.
  def significant_state
    states.find { |v| v.index == 1 } or states.reduce do |ret,v|
      s = Data.states[v]
      ret.nil? or s.priority > ret.priority ? s : ret
    end
  end

  def max_hp; base_max_hp; end
  def max_sp; base_max_sp; end

  def limit_param(v); [1, [v, 999].min].max; end
  def affect_parameter(t, v)
    t == 0 ? v / 2 :
      t == 1 ? v * 2 :
      t == 2 ? v : v
  end

	# Gets the current battler attack.
	#
	# @return current attack.
  def attack
    n = limit_param base_attack
    states.index do |v|
      if Data.states[v].affect_attack
        n = affect_parameter Data.states[v].affect_type, n
        true
      else; false; end
    end
    limit_param n
  end

	# Gets the current battler defense.
	#
	# @return current defense.
  def defence
    n = limit_param base_defence
    states.index do |v|
      if Data.states[v].affect_defence
        n = affect_parameter Data.states[v].affect_type, n
        true
      else; false; end
    end
    limit_param n
  end

	# Gets the current battler spirit.
	#
	# @return current spirit.
  def spirit
    n = limit_param base_spirit
    states.index do |v|
      if Data.states[v].affect_spirit
        n = affect_parameter Data.states[v].affect_type, n
        true
      else; false; end
    end
    limit_param n
  end

	# Gets the current battler agility.
	#
	# @return current agility.
  def agility
    n = limit_param base_agility
    states.index do |v|
      if Data.states[v].affect_agility
        n = affect_parameter Data.states[v].affect_type, n
        true
      else; false; end
    end
    limit_param n
  end

  def hidden?; false; end
  def immortal?; false; end

  def exists?; not(hidden? or dead?); end
  def dead?; not hidden? and hp == 0 and not immortal?; end

	# Checks if the actor can use the skill.
	#
	# @param skill_id ID of skill to check.
	# @return true if skill can be used.
	def skill_usable?(skill_id)
    return false if calculate_skill_cost(skill_id) > sp
    # TODO: Check for Movable(?) and Silence

    skill = Data.skills[skill_id]

    # TODO: Escape and Teleport Spells need event SetTeleportPlace and
    # SetEscapePlace first. Not sure if any game uses this...
    #if (Data.skills[skill_id - 1].type == RPG::Skill::Type_teleport)
    #	return is_there_a_teleport_set
    #elsif (Data.skills[skill_id - 1].type == RPG::Skill::Type_escape)
    #	return is_there_an_escape_set
    #else
    if (skill.type == RPG::Skill::Type_normal)
      scope = skill.scope

      if (scope == RPG::Skill::Scope_self ||
          scope == RPG::Skill::Scope_ally ||
          scope == RPG::Skill::Scope_party)
        # TODO: A skill is also acceptable when it cures a status
        return skill.affect_hp || skill.affect_sp
      end
    elsif (skill.type == RPG::Skill::Type_switch)
      # TODO:
      # if (Game_Temp::IsInBattle())
      # return Data.skills[skill_id - 1].occasion_battle
      # else
      return skill.occasion_field
      # end
    end

    return false
  end

	# Calculates the Skill costs including all modifiers.
	#
	# @param skill_id ID of skill to calculate.
	# @return needed skill cost.
  def calculate_skill_cost(skill_id)
    skill = Data.skills[skill_id]
    if Player.rpg2k3? && skill.sp_type == RPG::Skill::SpType_percent
      max_sp * skill.sp_percent / 100
    else skill.sp_cost end
  end

	# Adds a State.
	#
	# @param state_id ID of state to add.
	def add_state(state_id)
    if state_id > 0 and not has_state state_id
      states.push state_id
      states.sort!
    end
  end

	# Removes a State.
	#
	# @param state_id ID of state to remove.
  def remove_state(state_id)
    states.delete_if { |v| v == state_id }
  end

	# Removes all states which end after battle.
  def remove_staates
    states.delete_if { |v| Data.states[v].type == 0 }
  end

	# Removes all states.
	def remove_all_states; states.clear; end
end
