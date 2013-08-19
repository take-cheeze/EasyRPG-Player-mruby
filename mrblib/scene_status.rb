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

# Scene Status class.
# Displays status information about a party member.
class Scene_Status < Scene
	# Constructor.
	#
	# @param actor_index party index of the actor.
  def initialize(actor_index)
    super "Status"
    @actor_index = actor_index
    @actorinfo_window = nil
    @actorstatus_window = nil
    @gold_window = nil
    @equipstatus_window = nil
    @equip_window = nil
  end

  def start
    actor = Game_Party.actors[@actor_index].id

    @actorinfo_window = Window_ActorInfo.new 0, 0, 124, 208, actor
    @actorstatus_window = Window_ActorStatus 124, 0, 196, 64, actor
    @gold_window = Window_Gold.new 0, 208, 124, 32
    @equipstatus_window = Window_EquipStatus 124, 64, 196, 80, actor, false
    @equip_window = Window_Equip 124, 144, 196, 96, actor

    @equip_window.active = false
    @equipstatus_window.active = false
    @equip_window.index = nil
  end

  def update
    @gold_window.update
    @equipstatus_window.update
    @equip_window.update


    if (Input.triggered?(Input::CANCEL))
      Game_System.se_play Main_Data.game_data.system.cancel_se
      Scene.pop
    elsif Game_Party.actors.length > 1 && Input.triggered?(Input::RIGHT)
      Game_System.se_play Main_Data.game_data.system.cursor_se
      @actor_index = (@actor_index + 1) % Game_Party.actors.length
      Scene.push Scene_Status.new(@actor_index), true
    elsif Game_Party.actors.length > 1 && Input.triggered?(Input::LEFT)
      Game_System.se_play Main_Data.game_data.system.cursor_se
      @actor_index = (@actor_index + Game_Party.actors.length - 1) % Game_Party.actors.length
      Scene.push Scene_Status.new(@actor_index), true
    end
  end
end
