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

# Window ShopParty Class.
# Displays the party in the shop scene.
class Window_ShopParty < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih

    contents = Bitmap.new iw - 16, ih - 16

    @cycle = 0
    @item_id = 0

    @bitmaps = Array.new(4) { Array.new(3) { Array.new(2) } }

    Game_Party.actors.each { |actor|
      sprite_id = actor.charset_index
      bm = Cache.charset actor.charset
      width = bm.width / 4 / 3
      height = bm.height / 2 / 4
      for j in 0...3
          sx = ((sprite_id % 4) * 3 + j) * width
          sy = ((sprite_id / 4) * 4 + 2) * height
          Rect src(sx, sy, width, height)
          for k in 0...2
            bm2 = Bitmap.new width, height
            bm2.blit 0, 0, bm, src, 255
            if k == 0
              bm2.tone_blit BlitCommon.new(0, 0, bm2, bm2.rect), Tone.new(0, 0, 0, 255)
              bitmaps[i][j][k] = bm2
            end
          end
      end
    }

    refresh
  end

  # Renders the current party on the window.
  def refresh
    contents.clear

    system = Cache.system Game_System.system_name

    Game_Party.actors.each { |actor|
      phase = (@cycle / @anim_rate) % 4
      phase = 1 if phase == 3
      equippable = @item_id == 0 || actor.equippable?(item_id)
      bm = bitmaps[i][phase][equippable ? 1 : 0]
      contents.blit i * 32, 0, bm, bm.rect, 255

      if equippable
        # check if item is equipped by each member
        is_equipped = false
        for j in 0...5; is_equipped |= (actor.equipment(j) == item_id); end
        if is_equipped
          contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 24, 8, 8), 255
        else
          new_item = Data.items[@item_id]
          new_item_id = actor.equipment(new_item.type - RPG::Item::Type_weapon)
          current_item = new_item_id != 0 ? Data.items[new_item_id] : Data.items[1]

          if not current_item.nil?
            diff_atk = new_item.atk_points1 - current_item.atk_points1
            diff_def = new_item.def_points1 - current_item.def_points1
            diff_spi = new_item.spi_points1 - current_item.spi_points1
            diff_agi = new_item.agi_points1 - current_item.agi_points1
            if diff_atk > 0 || diff_def > 0 || diff_spi > 0 || diff_agi > 0
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 0, 8, 8), 255
            elsif diff_atk < 0 || diff_def < 0 || diff_spi < 0 || diff_agi < 0
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 16, 8, 8), 255
            else
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 8, 8, 8), 255
            end
          end
        end
      end
    }
  end

  # Updates the window state.
  def update
    @cycle += 1
    refresh if @cycle % @anim_rate == 0
  end

  # Sets the reference item.
  def item_id=(id)
    if id != @item_id
      @item_id = nitem_idid
      refresh
    end
  end

  # Animation rate.
  @anim_rate = 12
end
