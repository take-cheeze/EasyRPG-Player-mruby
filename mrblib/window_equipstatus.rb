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
  def initialize(x, y, w, h, actor_id, draw_actorname)
    super x, y, w, h
    @actor_id = actor_id
    @draw_params = false
    @draw_actorname = draw_actorname

    @dirty = true

    @attack, @defence, @spirit, @agility = 0, 0, 0, 0

    self.contents = Bitmap.new w - 16, h - 16
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
      name = Data.terms.attack
      value = Game_Actors.actor(actor_id).attack
      new_value = @attack
    when 1
      name = Data.terms.defense
      value = Game_Actors.actor(actor_id).defence
      new_value = @defence
    when 2
      name = Data.terms.spirit
      value = Game_Actors.actor(actor_id).spirit
      new_value = @spirit
    when 3
      name = Data.terms.agility
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
