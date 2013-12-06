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

# Window Save File Class.
class Window_SaveFile < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @index = 0
    @hero_hp = 0
    @hero_level = 0
    @corrupted = false

    self.z = 9999

    refresh
    update_cursor_rect
  end

  # Renders the current save on the window.
  def Refresh()
    contents.clear

    contents.draw_text_2k 4, 2, '%s%2d' % [Data.term.file , @index + 1], Font::ColorDefault

    if @corrupted
      contents.draw_text_2k 4, 16 + 2, "Savegame corrupted", Font::ColorKnockout
      return
    end

    return if party.empty?

    contents.draw_text_2k 8, 16 + 2, @hero_name, Font::ColorDefault
    contents.draw_text_2k 8, 32 + 2, Data.term.lvl_short, 1

    lx = contents.font.size(Data.term.lvl_short).width
    contents.draw_text_2k 8 + lx, 32 + 2, '%2d' % @hero_level, Font::ColorDefault

    contents.draw_text_2k(42, 32 + 2, Data.term.hp_short, 1)

    hx = contents.font.size(Data.term.hp_short).width
    contents.draw_text_2k 42 + hx, 32 + 2, '%3d' % @hero_hp, Font::ColorDefault

    for i in 0...[4, @party.length].min
      draw_face @party[i][2], party[i][1], 88 + i * 56, 0
    end
  end

  attr_writer :index, :corrupted

  # Party data displayed in the savegame slot.
  #
  # @param actors face_id and face_name of all party members.
  # @param name name of the First party member.
  # @param hp HP of the first party member.
  # @param level level of the First party member.
  def set_party(actors, name, hp, level)
    @party = actors
    @hero_name = name
    @hero_hp = hp
    @hero_level = level
  end

  def update
    super
    update_cursor_rect
  end


  def update_cursor_rect
    self.cursor_rect = active ? Rect.new(0, 0, 48, 16) : Rect.new
  end
end
