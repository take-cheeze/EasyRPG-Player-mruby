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

# Window_EquipItem class.
# Displays the available equipment of a specific type.
class Window_EquipItem < Window_Item
  # Enum containing the different equipment types.
  weapon = 0
  shield = 1
  armor = 2
  helmet = 3
  other = 4

  # Constructor.
  #
  # @param actor_id actor whos equipment is displayed.
  # @param equip_type type of equipment to show.
  def initialize(actor_id, equip_type)
    super 0, 128, 320, 112

    @actor_id = actor_id
    @equip_type = equip_type
    @equip_type = other if equip_type > 4 or equip_type < 0

    @equip_type = weapon if @equip_type == shield and Game_Actors.actor(@actor_id).two_swords_style?
  end

  # Checks if the item should be in the list based on
  # the type.
  #
  # @param item_id item to check.
  def check_include(item_id)
    # Add the empty element
    return true if item_id == 0

    result = false

    case (equip_type)
    when Window_EquipItem::weapon; result = (Data.items[item_id].type == RPG::Item::Type_weapon)
    when Window_EquipItem::shield; result = (Data.items[item_id].type == RPG::Item::Type_shield)
    when Window_EquipItem::armor; result = (Data.items[item_id].type == RPG::Item::Type_armor)
    when Window_EquipItem::helmet; result = (Data.items[item_id].type == RPG::Item::Type_helmet)
    when Window_EquipItem::other; result = (Data.items[item_id].type == RPG::Item::Type_accessory)
    else; return false
    end

    if result
      # Check if the party has the item at least once
      if Game_Party.item_number(item_id) == 0
        return false
      else
        return Game_Actors.actor(actor_id).equipable?(item_id)
      end
    else
      return false
    end
  end

  # Chechs if item should be enabled. Always true.
  #
  # @param item_id item to check.
  def check_enable(item_id); true; end
end
