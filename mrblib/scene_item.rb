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

# Scene_Item class.
class Scene_Item < Scene
	# Constructor.
	#
	# @param item_index index to select.
  def initialize(item_index)
    super 'Item'
    @item_index = item_index
  end

	def start
    @help_window = Window_Help 0, 0, 320, 32
    @item_window = Window_Item 0, 32, 320, 240 - 32
    @item_window.help_window = @help_window
    @item_window.refresh
    @item_window.index = @item_index
  end

	def update
    @help_window.update
    @item_window.update

    if Input.triggered? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop
    elsif Input.triggered? Input::DECISION
      item_id = @item_window.item_id

      if Game_Party.item_usable? item_id
        Game_System.se_play $game_data.system.decision_se

        if Data.items[item_id].type == RPG::Item::Type_switch
          Game_Switches[Data.items[item_id].switch_id] = true
          Scene.pop_until 'Map'
          Game_Map.need_refresh = true
        else
          Scene.push Scene_ActorTarget.new(item_id, @item_window.index)
          @item_index = @item_window.index
        end
      else
        Game_System.se_play $game_data.system.buzzer_se
      end
    end
  end
end
