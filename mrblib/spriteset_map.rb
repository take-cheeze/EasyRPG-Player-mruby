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

# Spriteset_Map class.
class Spriteset_Map
  def initialize
    @tilemap = Tilemap.new
    @panorama = Plane.new
    @panorama_name = ''
    @character_sprites = []

    @tilemap.width, @tilemap.height = Game_Map.width, Game_Map.height
    @tilemap.chipset = Cache.chipset Game_Map.chipset_name
    @tilemap.passable_down = Game_Map.passages_down
    @tilemap.passable_up = Game_Map.passages_up
    @tilemap.map_data_down = Game_Map.map_data_down
    @tilemap.map_data_up = Game_Map.map_data_up

    @panorama.z = -1000

    Game_Map.events.each { |v| @character_sprites << Sprite_Character.new(v) unless v.nil? }
    @character_sprites << Sprite_Character.new($game_player)

    update
  end

  def update
    @tilemap.ox, @tilemap.oy = Game_Map.display_x / 8, Game_Map.display_y / 8
    @tilemap.update

    @character_sprites.each { |v| v.update }

    name = Game_Map.panorama_name
    if name != @panorama_name
      @panorama_name = name
      @panorama.bitmap = Cache.panorama @panorama_name
    end
    @panorama.ox, @panorama.oy = Game_Map.panorama_x, Game_Map.panorama_y
  end

  # Finds the sprite for a specific character.
  def find_character(c)
    @character_sprites.find { |v| v.character == c }
  end

  # Notifies that the map's chipset has changed.
  def chipset_updated
    @tilemap.chipset = Cache.chipset Game_Map.chipset_name
    @tilemap.passable_down = Game_Map.passages_down
    @tilemap.passable_up = Game_Map.passable_up
  end

  # Substitutes tile in lower layer.
  def substitute_down(old_id, new_id)
    Game_Map.substitute_down old_id, new_id
    @tilemap.substitute_down old_id, new_id
  end

  # Substitutes tile in upper layer.
  def substitute_up(old_id, new_id)
    Game_Map.substitute_up old_id, new_id
    @tilemap.substitute_up old_id, new_id
  end
end
