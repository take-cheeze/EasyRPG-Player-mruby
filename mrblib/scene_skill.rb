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

# Scene_Skill class.
class Scene_Skill < Scene
  # Constructor.
  def initialize(actor_index, skill_index = 0)
    super 'Skill'
    @actor_index = actor_index
    @skill_index = skill_index
  end

  def start
    # Create the windows
    @help_window = Window_Help.new 0, 0, 320, 32
    @skillstatus_window = Window_SkillStatus.new 0, 32, 320, 32
    @skill_window = Window_Skill.new 0, 64, 320, 240 - 64

    # Assign actors and help to windows
    @skill_window.actor = Game_Party.actor[@actor_index].id
    @skillstatus_window.actor = Game_Party.actor[@actor_index].id
    @skill_window.index = @skill_index
    @skill_window.help_window = @help_window
  end

  def update
    @help_window.update
    @skillstatus_window.update
    @skill_window.update

    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop
    elsif Input.trigger? Input::DECISION
      skill_id = @skill_window.skill_id

      actor = Game_Party.actors[@actor_index]

      if actor.skill_usable? skill_id
        Game_System.se_play $game_data.system.decision_se

        if Data.skills[skill_id].type == RPG::Skill::Type_switch
          actor.sp = actor.sp - actor.calculate_skill_cost(skill_id)
          Game_Switches[Data.skills[skill_id].switch_id] = true
          Scene.pop_until "Map"
          Game_Map.needs_refresh = true
        elsif Data.skills[skill_id].type == RPG::Skill::Type_normal
          Scene.push Scene_ActorTarget.new(skill_id, @actor_index, @skill_window.index)
          skill_index = @skill_window.index
        elsif Data.skills[skill_id].type == RPG::Skill::Type_teleport
          # TODO: Displays the teleport target scene/window
        elsif Data.skills[skill_id].type == RPG::Skill::Type_escape
          # TODO: Displays the escape target scene/window
        end
      else
        Game_System.se_play $game_data.system.buzzer_se
      end
    end
  end
end
