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

# Window_BattleSkill class.
class Window_BattleSkill < Window_Skill
  # Sets the actor whose skills are displayed.
  #
  # @param id ID of the actor.
  def subst=(id)
    @subst = id
    refresh
  end

  # Checks if the skill should be in the list.
  #
  # @param skill_id skill to check.
  def check_include(skill_id)
    type = Data.skills[skill_id]
    @subst == RPG::Skill::Type_normal ? type < 4 : @subst == type
  end

  # Chechs if skill should be enabled.
  #
  # @param skill_id skill to check.
  def check_enable(skill_id)
    skill = Data.skills[skill_id]
    skill.type == RPG::Skill::Type_switch ? skill.occasion_battle : true
  end
end
