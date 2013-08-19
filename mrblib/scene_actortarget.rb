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

# Scene ActorTarget class.
# Manages using of Items and Spells.
class Scene_ActorTarget < Scene
	# Constructor.
  def initialize(id, index, skill = nil)
    super "ActorTarget"
    @id = id
    if skill.nil?; @index = index
    else
      @index = skill
      @actor_index = index
    end
    @use_item = skill.nil?
  end

  def start
    # Create the windows
    @help_window = Window_Help.new 0, 0, 136, 32
    @target_window = Window_ActorTarget.new 136, 0, 184, 240
    @status_window = Window_TargetStatus.new 0, 32, 136, 32

    @target_window.active = true
    @target_window.index = 0

    if @use_item
      if Data.items[id].entire_party
        @target_window.index = -100
      end
      @status_window.set_data id, true
      @help_window.text = Data.items[id].name
    else
      if Data.skills[id].scope == RPG::Skill::Scope_self
        @target_window.index = -@actor_index
      elsif Data.skills[id].scope == RPG::Skill::Scope_party
        @target_window.index = -100
      end

      @status_window.set_data id, false
      @help_window.text = Data.skills[id].name
    end
  end

  def update
    @help_window.update
    @target_window.update
    @status_window.update

    if Input.triggered? Input::CANCEL
      Game_System.se_play Main_Data.game_data.system.cancel_se
      Scene.pop
    end

    @use_item ? update_item : update_skill
  end

	# Update function used when an item will be used.
  def update_item
  end

	# Update function used when a skill will be used.
	def update_skill
  end
end
