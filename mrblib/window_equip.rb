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

# Window_Equip class.
# Displays currently equipped items.
class Window_Equip < Window_Selectable
  # Constructor.
  #
  # @param x window x position.
  # @param y window y position.
  # @param w window width.
  # @param h window height.
  # @param actor_id actor whose inventory is displayed.
  def initialize(ix, iy, iw, ih, actor_id)
    super ix, iy, iw, ih
    @actor_id = actor_id
    self.contents = Bitmap.new iw - 16, ih - 16
    @index = 0
    @data = []
    refresh
  end

  # Refreshes.
  def refresh
    contents.clear


    # Add the equipment of the actor to data
    @data.clear
    actor = Game_Actors.actor(@actor_id)
    for i in 0...5; @data.push actor.equipment i; end
    @item_max = data.length

    # Draw equipment text
    for i in 0...5
      draw_equipment_type(actor, 0, (12 + 4) * i + 2, i)
      draw_item_name Data.items[data[i]], 60, (12 + 4) * i + 2 if (data[i] > 0)
    end
  end

  # Returns the item ID of the selected item.
  #
  # @return item ID.
  def item_id; @index < 0 ? 0 : @data[@index]; end

  # Updates the help text.
  def update_help; @help_window.text = item_id == 0 ? '' : Data.items[item_id].description; end
end

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

# Window_EquipLeft class.
# Displays stats of the hero/item.
class Window_EquipStatus < Window_Base

  # Constructor.
  #
  # @param x window x position.
  # @param y window y position.
  # @param w window width.
  # @param h window height.
  # @param actor_id actor whose stats are displayed.
  # @param draw_actorname displays the actor name above the items.
  def initialize(ix, iy, iw, ih, actor_id, draw_actorname)
    super ix, iy, iw, ih
    @actor_id = actor_id
    @draw_params = false
    @draw_actorname = draw_actorname

    @dirty = true

    @attack, @defence, @spirit, @agility = 0, 0, 0, 0

    self.contents = Bitmap.new iw - 16, ih - 16
    refresh
  end

  # Refreshes screen.
  def refresh
    return if not @dirty

    if @draw_actorname
      y_offset = 18
      draw_actor_name Game_Actors.actor(@actor_id), 0, 2
    else; y_offset = 2
    end

    for i in 0...4; draw_parameter 0, y_offset + (12 + 4) * i, i; end

    @dirty = false
  end

  # Sets the parameter drawn after the ->.
  #
  # @param attack new attack.
  # @param defence new defense.
  # @param spirit new spirit.
  # @param agility new agility.
  def set_new_parameters(attack, defence, spirit, agility)
    @draw_params = true

    @dirty = @attack != attack or @defence != defence or @spirit != spirit or @agility != agility
    @attack, @defence, @spirit, @agility = attack, defence, spirit, agility
  end

  # Removes the parameters drawn after the ->.
  def clear_parameters
    return if not @draw_params

    @draw_params = false
    @dirty = true
    refresh
  end

  # Returns the draw color based on the passed values.
  #
  # @param old_value old value.
  # @param new_value new value,
  # @return 0 if equal, 4 if new > old, 5 if old > new,
  def new_parameter_color(old_value, new_value)
    if old_value == new_value; return 0
    elsif old_value < new_value; return 2
    else; return 3
    end
  end

  # Draws the actor parameters followed by the new ones.
  #
  # @param cx x coordinate.
  # @param cy y coordinate.
  # @param type parameter type to draw.
  def drawparameter(cx, cy, type)
    case (type)
    when 0
      name = Data.term.attack
      value = Game_Actors.actor(actor_id).attack
      new_value = @attack
    when 1
      name = Data.term.defense
      value = Game_Actors.actor(actor_id).defence
      new_value = @defence
    when 2
      name = Data.term.spirit
      value = Game_Actors.actor(actor_id).spirit
      new_value = @spirit
    when 3
      name = Data.term.agility
      value = Game_Actors.actor(actor_id).agility
      new_value = @agility
    else; return
    end

    # Draw Term
    contents.draw_text_2k cx, cy, name, 1

    # Draw Value
    cx += 60
    contents.draw_text_2k cx + 18, cy, value.to_s, Font::ColorDefault, Text::AlignRight

    if @draw_params
      # Draw New Value
      cx += 30
      color = new_parameter_color value, new_value
      contents.draw_text_2k(cx + 18, cy, new_value.to_s, color, Text::AlignRight)
    end
  end
end
