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

# Scene Equip class.
# Displays the equipment of a hero.
class Scene_Equip < Scene

  # Constructor.
  #
  # @param actor_index actor in the party.
  # @param equip_index selected equipment.
  def initialize(actor_index = 0, equip_index = 0)
    super 'Equip'
    @actor_index, @equip_index = actor_index. equip_index
    @item_windows = []
  end

  def start
    actor = Game_Party.actors[@actor_index]

    # Create the windows
    @help_window = Window_Help.new 0, 0, 320, 32
    @equipstatus_window = Window_EquipStatus.new 0, 32, 124, 96, actor.id
    @equip_window = Window_Equip.new 124, 32, 196, 96, actor.id

    @equip_window.index = @equip_index

    for i in 0...5; @item_windows.push Window_EquipItem.new(actor.id, i); end

    # Assign the help windows
    @equip_window.help_window = @help_window
    @item_windows.each { |v|
      v.help_window = @help_window
      v.active = false
      v.refresh
    }
  end

  def update
    @help_window.update

    update_equip_window
    update_status_window
    update_item_windows

    if @equip_window.active; update_equip_selction
    elsif @item_window; update_item_selection
    end
  end

  # Updates the item windows.
  def update_item_windows
    @item_windows.each_with_index { |v, i|
      v.visible = @equip_window.index == i
      v.update
    }
    @item_window = @item_windows[@equip_window.index]
  end

  # Updates the equip window.
  def update_equip_window; @equip_window.update; end

  # Updates the status window.
  def update_status_window
    if @equip_window.active
      @equipstatus_window.clear_parameters
    elsif @item_window.active
      actor = Game_Party.actors[@actor_index]
      old_item = actor.set_equipment @equip_window.index, @item_window.item_id

      @equipstatus_window.set_new_parameters(actor.attack, actor.defence,
                                             actor.spirit, actor.agility)

      actor.set_equipment @equip_window.index, old_item

      @equipstatus_window.refresh
    end

    @equipstatus_window.update
  end

  # Updates the equip window.
  def update_equip_selction
    if Input.trigger? Input::CANCEL
      Game_System.se_play Game_System::SFX_Cancel
      Player.pop
    elsif Input.trigger? Input::DECISION
      Game_System.se_play Game_System::SFX_Decision
      @equip_window.active = false
      @item_window.active = true
      @item_window.index = 0
    elsif Game_Party.actors.length > 1 && Input.trigger?(Input::RIGHT)
      Game_System.se_play Game_System::SFX_Cursor
      @actor_index = (@actor_index + 1) % Game_Party.actors.length
      Player.push Scene_Equip.new(@actor_index, @equip_window.index), true
    elsif Game_Party.actors.length > 1 && Input.trigger?(Input::LEFT)
      Game_System.se_play Game_System::SFX_Cursor
      @actor_index = (@actor_index + Game_Party..actors.length - 1) % Game_Party.actors.length
      Player.push Scene_Equip.new(@actor_index, @equip_window.index), true
    end
  end

  # Updates the item window.
  def update_item_selection
    if Input.trigger? Input::CANCEL
      Game_System.se_play Game_System::SFX_Cancel
      @equip_window.active = true
      @item_window.active = false
      @item_window.index = nil
    elsif Input.trigger? Input::DECISION
      Game_System.se_play Game_System::SFX_Decision

      Game_Party.actors[@actor_index].change_equipment @equip_window.index, @item_window.item_id

      @equip_window.active = true
      @item_window.active = false
      @item_window.index = nil

      @equip_window.refresh

      @item_windows.each { |v| v.refresh }
    end
  end
end
