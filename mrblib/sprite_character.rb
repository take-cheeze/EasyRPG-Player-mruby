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

# Sprite character class.
class Sprite_Character < Sprite
  # Constructor.
  #
  # @param c game character to display
  def initialize(c)
    super

    @tile_id = 0
    @character_name = nil
    @character_index = 0
    @chara_width, @chara_height = 0, 0
    @character = c
  end

  attr_accessor :character

  # Updates sprite state.
  def update
    super

    if @tile_id != @character.tile_id or
        @character_name != @character.character_name or
        @character_index != @character.character_index
      @tile_id  = @character.tile_id
      @character_name = @character.character_name
      @character_index = @character.character_index

      if @tile_id.nil?
        if @character_name.nil?
          self.bitmap = nil
        else
          self.bitmap = Cache.charset @character_name
          @chara_width, @chara_height = bitmap.width / 4 / 3, bitmap.height / 2 / 4
          self.ox, self.oy = @chara_width / 2, @chara_height
          self.sprite_rect = Rect.new((@character_index % 4) * @chara_width * 3,
                                      (@character_index / 4) * @chara_height * 4,
                                      @chara_width * 3, @chara_height * 4)
        end
      else
        self.bitmap = Cache.tile Game_Map.chipset_name, @tile_id
        self.src_rect = Rect.new 0, 0, 16, 16
        self.ox, self.oy = 8, 16
      end
    end

    self.src_rect = Rect.new(@character.pattern * @chara_width,
                             @character.direction * @chara_height,
                             @chara_width, @chara_height) if @tile_id.nil?

    if @character.flash_pending?
      col, dur = @character.flash_paramaters
      flash col, dur
    end

    self.opacity = @character.opacity if @character.visible

    self.x, self.y = @character.screen_x, @character.screen_y
    self.z = @character.screen_z @chara_height

    # self.blend_type = @character.blend_type
    # self.bush_depth = @character.bush_depth
  end
end
