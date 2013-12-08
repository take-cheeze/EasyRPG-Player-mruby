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

class Picture
  def initialize(id)
    @data = $game_data.pictures[id]
    @sprite = nil
    transition 0
  end

  WaverSpeed = 10

  def show(name)
    @data.name = name
    @data.time_left = 0

    bitmap = Cache.picture @data.name
    @sprite = Sprite.new
    @sprite.bitmap = bitmap
    @sprite.ox = @bitmap.width / 2
    @sprite.oy = @bitmap.height / 2
  end

  NoEffect = 0
  RotateEffect = 1
  WaveEffect = 2

  def erase
    @data.name = ''
    @sprite = nil
  end

  def use_transparent(flag) @data.transparency = flag end
  def scrolls(flag) @data.picture_scrolls = flag end
  def move(x, y) @data.finish_x, @data.finish_y = x, y end
  def color(r, g, b, s)
    @data.finish_red, @data.finish_green, @data.finish_blue, @data.finish_sat = r, g, b, s
  end
  def magify(scale) @data.finish_magnify = scale end
  def transparency(t, b) @data.finish_top_trans, @data.finish_bot_trans = t, b end
  def rotate(speed)
    @data.effect_mode = RotateEffect
    @data.effect_speed = @data.effect2_speed = speed
    @data.current_rotation = 0
  end
  def waver(depth)
    @data.effect_mode = WaveEffect
    @data.effect_speed = @data.effect2_speed = speed
    @data.current_waver = 0
  end
  def stop_effects
    @data.effect_mode = NoEffect
  end

  def transition(tenths)
    @data.time_left = tenths * DEFAULT_FPS / 10
    if tenths == 0
      @data.current_x = @data.finish_x
      @data.current_y = @data.finish_y
      @data.current_red = @data.finish_red
      @data.current_green = @data.finish_green
      @data.current_blue = @data.finish_blue
      @data.current_sat = @data.finish_sat
      @data.current_magnify = @data.finish_magnify
      @data.current_top_trans = @data.finish_top_trans
      @data.current_bot_trans = @data.finish_bot_trans

      update_sprite
    end
  end

  def interpolate(x0, x1) (x0 * (d - 1) + x1) / @data.time_left end

  def update
    return if @data.name.empty?

    # update effect
    case @data.effect_mode
    when RotateEffect; @data.current_rotation += @data.effect_speed
    when WaveEffect; @data.current_waver += @data.effect2_speed
    end

    if @data.time_left > 0
      @data.current_x = interpolate @data.current_x, @data.finish_x
      @data.current_y = interpolate @data.current_y, @data.finish_y
      @data.current_red = interpolate @data.current_red, @data.finish_red
      @data.current_green = interpolate @data.current_green, @data.finish_green
      @data.current_blue = interpolate @data.current_blue, @data.finish_blue
      @data.current_sat = interpolate @data.current_sat, @data.finish_sat
      @data.current_maginify = interpolate @data.current_maginify, @data.finish_maginify
      @data.current_top_trans = interpolate @data.current_top_trans, @data.finish_top_trans
      @data.current_bot_trans = interpolate @data.current_bot_trans, @data.finish_bot_trans
    end

    update_sprite
  end

  def update_sprite
    return if @sprite.nil?
    return if @data.name.empty?

    @sprite.x, @sprite.y = @data.current_x, @data.current_y
    @sprite.z = 1000 + data.index

    @sprite.zoom_x = @data.current_magnify / 100.0
    @sprite.zoom_y = @data.current_magnify / 100.0

    @sprite.ox = @sprite.bitmap.width * @data.current_magnify / 200.0
    @sprite.ox = @sprite.bitmap.height * @data.current_magnify / 200.0

    @sprite.angle = @data.effect_mode == RotateEffect ? @data.current_rotation : 0.0
    @sprite.waver_phase = @data.effect_mode == WaveEffect ? @data.current_waver : 0.0
    @sprite.waver_depth = @data.effect_mode == WaveEffect ? @data.effect2_speed : 0.0

    @sprite.set_opacity(255 * (100 - @data.current_top_trans) / 100,
                        255 * (100 - @data.current_bot_trans) / 100)

    @sprite.bush_depth = @sprite.height / 2 if
      @data.current_bot_trans != @data.current_top_trans

    @sprite.tone = Tone.new((@data.current_red - 100) * 255 / 100,
                            (@data.current_green - 100) * 255 / 100,
                            (@data.current_blue - 100) * 255 / 100,
                            (100 - @data.current_sat) * 255 / 100)
  end
end
