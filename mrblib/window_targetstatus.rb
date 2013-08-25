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

# Window_TargetStatus class.
# Shows owned (and equipped) items.
# If needed it can also display the costs of a skill.
class Window_TargetStatus < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @use_item = false
    self.contents = Bitmap.new iwidth - 16, iheight - 16
  end

  # Renders the current item quantity/spell costs on
  # the window.
  def refresh
    contents.clear

    return if id < 0

    contents.draw_text_2k 0, 0, use_item ? Data.terms.possessed_items : Data.terms.sp_cost, 1
    msg = (@use_item ? Game_Party.item_number(id) : Data.skills[id].sp_cost).to_s
    contents.draw_text_2k contents.width - contents.text_size(msg).width, 0, msg, Font::ColorDefault, Text::AlignRight
  end

  # Sets the ID of the item/skill that shall be used.
  #
  # @param id ID of item/skill.
  # @param is_item true if ID for an item, otherwise for a skill.
  def set_data(id, is_item)
    @id = id
    @use_item = is_item

    refresh
  end
end
