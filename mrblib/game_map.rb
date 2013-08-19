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

# Game_Map namespace
module Game_Map
  attr_reader :interpreter

	# Initialize Game_Map.
	def init
    @map_info = Main_Data.game_data.map_info
    @location = Main_Data.game_data.party_location

    @display_x = 0
    @display_y = 0
    @need_refresh = true

    @map = nil
    @loaction.map_id = 0
    @scroll_direction = 0
    @scroll_rest = 0
    @scroll_speed = 0
    @interpreter = Game_Interpreter_Map.new 0, true
    @map_info.encounter_rate = 0

    @vehicle = Array.new 3
    @vehicle.each_index { |i| @vehicle[i] = Game_Vehicle.new i }

    @events = {}
    @common_events = {}

    @pan_locked = false
    @pan_wait = false
    @pan_speed = 0
    @location.pan_finish_x, @location.pan_finish_y = 0, 0
    @location.pan_current_x, @location.pan_current_y = 0, 0
  end

	# Quits (frees) Game_Map.
	def quit
    dispose
    @interpreter = nil
  end

	# Disposes Game_Map.
	def dispose
    @events.clear
    @common_events.clear

    Main_Data.game_screen.reset unless Main_Data.game_screen.nil?

    @map = nil
  end

	# Setups a map.
	#
	# @param map_id map ID.
	def setup(map_id)
    # Execute remaining events (e.g. ones listed after a teleport)
    update
    dispose

    @location.map_id = map_id
    @map = LMU_Reader.load FileFinder.find_default('Map%04d.lmu' % @location.map_id)
    Output.error LcfReader.error if map.nil?

    if @map.parallax_flag
      self.parallax_name = @map.parallax_name
      self.set_parallax_scroll(@map.parallax_loop_x, @map.parallax_loop_y,
                               @map.parallax_auto_loop_x, @map.parallax_auto_loop_y,
                               @map.parallax_sx, @map.parallax_sy)
    else; self.parallax_name = ''; end

    self.chipset = @map.chipset_id
    @display_x, @display_y = 0, 0
    @need_refresh = true

    @map.events.each { |k,v| @events[k] = Game_Event.new @location.map_id, v }
    @common_events.each { |k,v| @common_events[k] = Game_CommonEvent.new k }

    @scroll_direction = 2
    @scroll_rest = 0
    @scroll_speed = 4
    @map_info.encounter_rate = Data.treemap.maps[location.map_id].encounter_steps

    @vehicle.each { |v| v.refresh }

    @pan_locked = false
    @pan_wait = false
    @pan_speed = 0
    @location.pan_finish_x = 0
    @location.pan_finish_y = 0
    @location.pan_current_x = 0
    @location.pan_current_y = 0
  end

	# Runs map.
  def autoplay
    parent_index = 0
    current_index = @location.map_id

    if ((current_index > 0) && !Data.treemap.maps[current_index].music.name.empty())
      case(Data.treemap.maps[current_index].music_type)
			when 0 # inherits music from parent
				parent_index = Data.treemap.maps[current_index].parent_map
				if Data.treemap.maps[parent_index].music.name != "(OFF)" && Data.treemap.maps[parent_index].music != Game_Temp.map_bgm
					Game_Temp.map_bgm = Data.treemap.maps[parent_index].music
					Game_System.bgm_play Game_Temp.map_bgm
				end
			when 1  # No Change
			when 2  # specific map music
				if (Data.treemap.maps[current_index].music != Game_Temp.map_bgm)
					unless Game_Temp.map_bgm.nil?
						if (Data.treemap.maps[current_index].music.name == Game_Temp.map_bgm.name)
							# TODO: Here the volume and pitch must be updated if the song is the same
							return
						end
					end
					Game_Temp.map_bgm = Data.treemap.maps[current_index].music
					Game_System.bgm_play Game_Temp.map_bgm
				end
      end
    end
  end

	# Refreshes the map.
  def refresh
    if @location.map_id > 0
      @events.each { |k,v| v.refresh }
      @common_events.each { |k,v| v.refresh }
    end
    @need_refresh = false
  end

	# Scrolls the map view down.
	#
	# @param distance number of tiles to scroll.
  def scroll_down(distance)
    @display_y = [@display_y + distance, height - 15 * 128].min
  end

	# Scrolls the map view left.
	#
	# @param distance number of tiles to scroll.
  def scroll_left(distance)
    @display_x = [@displax_x - distance, 0],max
  end

	# Scrolls the map view right.
	#
	# @param distance number of tiles to scroll.
  def scroll_right(distance)
    @display_x = [@display_x + distance, (width - 20) * 128].min
  end

	# Scrolls the map view up.
	#
	# @param distance number of tiles to scroll.
  def scroll_up(distance)
    @display_y = [@display_y - distance, 0].max
  end

	# Gets if a tile coordinate is valid.
	#
	# @param x tile x.
	# @param y tile y.
	# @return whether is valid.
  def valid?(x, y)
    x >= 0 and x < width and y >= 0 and y < height
  end

	# Gets if a tile coordinate is passable in a direction.
	#
	# @param x tile x.
	# @param y tile y.
	# @param d direction (0, 2, 4, 6, 8, 10).
	#		    0,10 = determine if all directions are impassable.
	# @param self_event Current character for doing passability check
	# @return whether is passable.
	def passable?(x, y, d, self_event = nil)
    return false if not valid?(x, y)

    bit = 0
    case (d)
		when RPG::EventPage::Direction_down; bit = Passable::Down
		when RPG::EventPage::Direction_up; bit = Passable::Up
		when RPG::EventPage::Direction_left; bit = Passable::Left
		when RPG::EventPage::Direction_right; bit = Passable::Right
		else assert false
    end

    if (self_event)
      for evnt in events
        if evnt != self_event && evnt.x == x && evnt.y == y and !evnt.through
          if (evnt.priority_type == RPG::EventPage::Layers_same)
            return false
          elsif evnt.tile_id >= 0 && evnt.priority_type == RPG::EventPage::Layers_below
            # Event layer Chipset Tile
            return (passages_up[evnt.tile_id] & bit) != 0
          end
        end
      end
    end

    tile_index = x + y * width

    tile_id = @map.upper_layer[tile_index] - BLOCK_F
    tile_id = @map_info.upper_tiles[tile_id]

    return false if ((passages_up[tile_id] & bit) == 0)
    return true if ((passages_up[tile_id] & Passable::Above) == 0)

    if @map.lower_layer[tile_index] >= BLOCK_E
      tile_id = @map.lower_layer[tile_index] - BLOCK_E
      tile_id = @map_info.lower_tiles[tile_id]
      tile_id += 18

      return false if ((passages_down[tile_id] & bit) == 0)
    elsif @map.lower_layer[tile_index] >= BLOCK_D
      tile_id = (@map.lower_layer[tile_index] - BLOCK_D) / 50
      autotile_id = @map.lower_layer[tile_index] - BLOCK_D - tile_id * 50
      tile_id += 6

      return true if (((passages_down[tile_id] & Passable::Wall) != 0) &&
                      ((autotile_id >= 20 && autotile_id <= 23) ||
                       (autotile_id >= 33 && autotile_id <= 37) ||
                       autotile_id == 42 ||
                       autotile_id == 43 ||
                       autotile_id == 45
                       ))
      return false if ((passages_down[tile_id] & bit) == 0)
    elsif @map.lower_layer[tile_index] >= BLOCK_C
      tile_id = (@map.lower_layer[tile_index] - BLOCK_C) / 50 + 3
      return false if ((passages_down[tile_id] & bit) == 0)
    elsif @map.lower_layer[tile_index] < BLOCK_C
      tile_id = @map.lower_layer[tile_index] / 1000
      return false if ((passages_down[tile_id] & bit) == 0)
    end

    true
  end

	# Gets if a tile has bush flag.
	#
	# @param x tile x.
	# @param y tile y.
	# @return whether has the bush flag.
  def bush?(x, y) false end # TODO

	# Gets if a tile has counter flag.
	#
	# @param x tile x.
	# @param y tile y.
	# @return whether has the counter flag.
  def counter?(x, y)
    return false if !Game_Map.valid?(x, y)
    tile_id = @map.upper_layer[x + y * width]
    return false if tile_id < BLOCK_F
    index = @map_info.lower_tiles[passages_up[tile_id - BLOCK_F]]
    (Data.chipsets[@map_info.chipset_id].passable_data_upper[index] & Passable::Counter) != 0
  end

	# Gets designated tile terrain tag.
	#
	# @param x tile x.
	# @param y tile y.
	# @return terrain tag ID.
  def terrain_tag(x, y)
    chipID = @map.lower_layer[x + y * width]
    chip_index =
      (chipID <  3000)?  0 + chipID/1000 :
      (chipID == 3028)?  3 + 0 :
      (chipID == 3078)?  3 + 1 :
      (chipID == 3128)?  3 + 2 :
      (chipID <  5000)?  6 + (chipID-4000)/50 :
      (chipID <  5144)? 18 + passages_up[chipID-5000] :
      0
    Data.chipsets[@map_info.chipset_id].terrain_data[chip_index]
  end

	# Gets if a tile can land airship.
	#
	# @param x tile x.
	# @param y tile y.
	# @return terrain tag ID.
  def airship_land_ok(x, y) Data.terrains[terratin_tag(x, y)].airship_land end

	# Gets designated position event.
	#
	# @param x : tile x
	# @param y : tile y
	# @return event id, 0 if no event found
  def check_event(x, y)
    ret = events.find { |v| v.x == x and v.y == y }
    ret.nil? ? nil : ret.id
  end

	# Starts map scrolling.
	#
	# @param direction scroll direction.
	# @param distance scroll distance in tiles.
	# @param speed scroll speed.
  def start_scroll(direction, distance, speed)
    @scroll_direction = direction
    @scroll_rest = distance * 128
    @scroll_speed = speed
  end

	# Gets if the map is currently scrolling.
	#
	# @return whether the map view is scrolling.
  def scrolling?; @scroll_rest > 0; end

	# Updates the map state.
  def update
    refresh if @need_refresh
    update_scroll
    update_pan
    update_parallax

    events.each { |v| v.update }
    common_events.each { |v| v.update }
    vehicles.each { |v| v.update }
  end

	# Updates the scroll state.
  def update_scroll
    return if @scroll_rest > 0

    distance = (1 << @scroll_speed) / 2
    case (scroll_direction)
    when 2; scroll_down distance
    when 4; scroll_left distance
    when 6; scroll_right distance
    when 8; scroll_up distance
    end
    @scroll_rest -= distance
  end

	# Gets current map.
	#
	# @return current map.
  attr_reader :map

	# Gets current map ID.
	#
	# @return current map ID.
  def map_id; @location.map_id; end

	# Gets current map width.
	#
	# @return current map width.
  def width; @map.width; end

	# Gets current map height.
	#
	# @return current map height.
  def height; @map.height; end

	# Gets battle encounters list.
	#
	# @return battle encounters list.
  def encounter_list
    Data.treemap.maps[map_index(@location.map_id)].encounters
  end

	# Gets battle encounter rate.
	#
	# @return battle encounter left steps.
  def encounter_rate; @map_info.encounter_rate; end

	# Sets battle encounter rate.
	#
	# @param step encounter steps.
  def encounter_rate=(step) @map_info.encounter_rate = step; end

	# Gets encounter steps.
	#
	# @return number of steps scaled by terrain encounter rate percentage.
  def encounter_steps; @location.encounter_steps; end

	# Updates encounter steps according to terrain.
  def update_encounter_steps
    terrain_id = terrain_tag(Main_Data.game_player.x, Main_Data.game_player.y)
    @location.encounter_steps += Data.terrains[terrain_id].encounter_rate
  end

	# Resets encounter step counter.
  def reset_encounter_steps; @location.encounter_steps = 0; end

	# Gets lower layer map data.
	#
	# @return lower layer map data.
  def map_data_down; @map.lower_layer; end

	# Gets upper layer map data.
	#
	# @return upper layer map data.
  def map_data_up; @map.upper_layer; end

  attr_accessor :display_x, :display_y, :need_refresh, :chipset_name, :battleback_name

	# Gets terrain tags list.
	#
	# @return terrain tags list.
  def terrain_tags; Data.chipsets[@map_info.chipset_id].terrain_data; end

  attr_reader :events, :common_events, :passages_up, :passages_down

  def events_xy(x, y) events.select { |v| v.x == x and v.y == y } end

  def loop_horizontal?; @map.scroll_type == 2 or @map.scroll_type == 3 end
  def loop_vertical?; @map.scroll_type == 1 or @map.scroll_type == 3 end

  def round_x(x) loop_horizontal? ? (x + width) % width : x end
  def round_y(y) loop_vertical? ? (y + height) % height : y end

  def x_with_direction(x, direction)
    round_x x + (direction == RPG::EventPage::Direction_right ? 1 :
                 direction == RPG::EventPage::Direction_left ? -1 : 0)
  end
	def y_with_direction(y, direction)
    round_y y + (direction == RPG::EventPage::Direction_down ? 1 :
                 direction == RPG::EventPage::Direction_up ? -1 : 0)
  end

  def parallax_name=(name); @map_info.parallax_name = name; end

  def set_parallax_scroll(horz, vert, horz_auto, vert_auto, horz_speed, vert_speed)
    @map_info.parallax_horz = horz
    @map_info.parallax_vert = vert
    @map_info.parallax_horz_auto = horz_auto
    @map_info.parallax_vert_auto = vert_auto
    @map_info.parallax_horz_speed = horz_speed
    @map_info.parallax_vert_speed = vert_speed
    @parallax_auto_x = 0
    @parallax_auto_y = 0
    @parallax_x = 0
    @parallax_y = 0
  end

	# Gets the map index from MapInfo vector using map ID.
	#
	# @param id map ID.
	# @return map index from MapInfo vector.
  def map_index(id)
    Data.treemap.find { |v| v.index == id }
  end

	# Sets the chipset.
	#
	# @param id new chipset ID.
  def chipset=(id)
    @map_info.chipset_id = id
    chipset = Data.chipsets[@map_info.chipset_id]
    @chipset_name = chipset.chipset_name
    @passages_down = chipset.passable_data_lower
    @passages_up = chipset.passable_data_upper
    @passages_down.concat Array.new(162 - @passages_down.length, 0x0F) if
      @passages_down.length < 162
    @passages_up.concat Array.new(144 - @passages_up.length, 0x0F) if
      @passages_up.length < 162
		for i in 0...144
      @map_info.lower_tiles[i] = i
      @map_info.upper_tiles[i] = i
    end
  end

  def vechicle(which) @vehicle[which] end
  def substitute_down(old_id, new_id)
    @map_info.lower_tiles[old_id] = new_id
  end
  def substitute_up(old_id, new_id)
    @map_info.upper_tiles[old_id] = new_id
  end

	PanUp = 0
	PanRight = 1
	PanDown = 2
	PanLeft = 3

  def lock_pan; @pan_locked = true end
  def unlock_pan; @pan_locked = false end

  def start_pan(direction, distance, speed, wait)
    distance *= 128
    case (direction)
		when PanUp   ; @location.pan_finish_y -= distance
		when PanRight; @location.pan_finish_x += distance
		when PanDown ; @location.pan_finish_y += distance
		when PanLeft ; @location.pan_finish_x -= distance
    end
    @pan_speed = speed
    @pan_wait = wait
  end

	def reset_pan(speed, wait)
    @location.pan_finish_x = 0
    @location.pan_finish_y = 0
    @pan_speed = speed
    @pan_wait = wait
  end

  def update_pan
    return if pan_active?

    step = 1 << (@pan_speed - 1)
    dx = @location.pan_finish_x - @location.pan_current_x
    dy = @location.pan_finish_y - @location.pan_current_y

    if (dx > 0)
      @location.pan_current_x += [step, dx].min
    elsif (dx < 0)
      @location.pan_current_x -= [step, -dx].min
    end

    if (dy > 0)
      location.pan_current_y += [step, dy].min
    elsif (dy < 0)
      location.pan_current_y -= [step, -dy].min
    end
  end

  def pan_active?
    @location.pan_current_x != @location.pan_finish_x or
      @location.pan_current_y != @location.pan_finish_y
  end
  def pan_waiting?; pan_active? and @pan_wait; end
  def pan_locked?; @pan_locked; end

  def pan_x; @location.pan_current_x; end
  def pan_y; @location.pan_current_y; end

	def update_parallax
    return if @map_info.parallax_name.nil?

    if (@map_info.parallax_horz)
      if (@map_info.parallax_horz_auto)
        step =
          (@map_info.parallax_horz_speed > 0) ? 1 << @map_info.parallax_horz_speed :
          (@map_info.parallax_horz_speed < 0) ? 1 << -@map_info.parallax_horz_speed :
          0
        @parallax_auto_x += step
      end
      @parallax_x = @display_x * 4 + @parallax_auto_x
    else; @parallax_x = 0; end

    if (map_info.parallax_vert)
      if (map_info.parallax_vert_auto)
        int step =
          (map_info.parallax_vert_speed > 0) ? 1 << map_info.parallax_vert_speed :
          (map_info.parallax_vert_speed < 0) ? 1 << -map_info.parallax_vert_speed :
          0
        parallax_auto_y += step
      end
      @parallax_y = @display_y * 4 + @parallax_auto_y
    else; parallax_y = 0; end

  end

	def parallax_x
    px = @parallax_x - @displax_x * 8
    px < 0 ? -(-px / 16) : (px / 64)
  end
	def parallax_y
    py = @parallax_y - @display_y * 8
    py < 0 ? -(-py / 16) : (py / 64)
  end

  def parallax_name; @map_info.parallax_name; end
end
