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

class Game_Screen
  def initialize
    reset
  end

  def data; $game_data.screen ||= {}; end

  snowflake_life = 200
  snowflake_visible = 150

  def picture(id)
    @pictures[id - 1] = Picture.new id if @pictures[id - 1].nil?
    @pictures[id - 1]
  end

  def reset
    @pictures = Array.new 50

    data.tint_current_red = nil
    data.tint_current_green = nil
    data.tint_current_blue = nil
    data.tint_current_sat = nil

    data.tint_finish_red = nil
    data.tint_finish_green = nil
    data.tint_finish_blue = nil
    data.tint_finish_sat = nil

    data.tint_time_left = 0

    data.flash_red = nil
    data.flash_green = nil
    data.flash_blue = nil

    @flash_sat = 0
    data.flash_time_left = 0
    @flash_period = 0

    data.shake_strength = nil
    data.shake_speed = nil
    data.shake_time_left = 0
    data.shake_position = 0
    data.shake_continuous = false
    @shake_direction = 0

    data.weather = 0
    data.weather_strength = 0

    @movie_filename = ''
    @movie_pos_x, @movie_pos_y = 0, 0
    @movie_res_x, @movie_res_y = 0, 0

    @snowflakes = []
    stop_weather
  end

  def tint_screen(r, g, b, s, tenths)
    data.tint_finish_red = r
    data.tint_finish_green = g
    data.tint_finish_blue = b
    data.tint_finish_sat = s

    data.tint_time_left = tenths * DEFAULT_FPS / 10

    if data.tint_time_left == 0
      data.tint_current_red = data.tint_finish_red
      data.tint_current_green = data.tint_finish_green
      data.tint_current_blue = data.tint_finish_blue
      data.tint_current_sat = data.tint_finish_sat
    end
  end

  def shake_once(power, speed, tenths)
    data.shake_strength = power
    data.shake_speed = speed
    data.shake_time_left = tenths * DEFAULT_FPS / 10
    data.shake_position = 0
    data.shake_continuous = false
  end

  def shake_begin(power, speed)
    data.shake_strength = power
    data.shake_speed = speed
    data.shake_time_left = 0
    data.shake_position = 0
    data.shake_continuous = true
  end

  def shake_end
    data.shake_time_left = 0
    data.shake_continuous = false
  end

  def weather(type, strength)
    data.weather = type
    data.weather_strength = strength
    stop_weather
    init_weather if type != Weather_None
  end

  def play_movie(filename, pos_x, pos_y, res_x, res_y)
    @movie_filename = filename
    @movie_pos_x, @movie_pos_y = 0, 0
    @movie_res_x, @movie_res_y = 0, 0
  end

  def show_battle_animation(animation_id, target_id, global)
    data.battleanim_id = animation_id
    data.battleanim_target = target_id
    data.battleanim_global = global

    target = Game_Character.character target_id, target_id

    @animation = BattleAnimation.new target.screen_x, target.screen_y, Data.animations[animation_id]
    @animation.visible = true
  end

  def battle_animation_waiting?; not @animation.nil? end

  def flash_once(r, g, b, a, s, tenths)
    data.flash_red = r
    data.flash_green = g
    data.flash_blue = b
    @flash_sat = s
    data.flash_current_level = s

    data.flash_time_left = tenths * DEFAULT_FPS / 10
    @flash_period = 0
  end

  def flash_begin(r, g, b, a, s, tenths)
    data.flash_red = r
    data.flash_green = g
    data.flash_blue = b
    @flash_sat = s
    data.flash_current_level = s

    data.flash_time_left = tenths * DEFAULT_FPS / 10
    @flash_period = data.flash_time_left
  end

  def flash_end
    data.flash_time_left = 0
    flash_period = 0
  end

  Weather_None = 0
  Weather_Rain = 1
  Weather_Snow = 2
  Weather_Fog = 3
  Weather_Sandstorm = 4

  snow_image = [
                0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00,
                0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00,
                0x00, 0x04, 0x02, 0x03, 0x00, 0x00, 0x00, 0xd4, 0x9f, 0x76, 0xed,
                0x00, 0x00, 0x00, 0x09, 0x50, 0x4c, 0x54, 0x45, 0x00, 0x00, 0x00,
                0xc0, 0xc0, 0xc0, 0xff, 0xff, 0xff, 0x0d, 0x6d, 0xd7, 0xbb, 0x00,
                0x00, 0x00, 0x01, 0x74, 0x52, 0x4e, 0x53, 0x00, 0x40, 0xe6, 0xd8,
                0x66, 0x00, 0x00, 0x00, 0x0e, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7,
                0x63, 0x10, 0x61, 0xc8, 0x04, 0x42, 0x11, 0x00, 0x03, 0xf0, 0x00,
                0xfb, 0xb6, 0xa8, 0xf1, 0xda, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
                0x4e, 0x44, 0xae, 0x42, 0x60, 0x82 ].reduce('') { |tmp, v| tmp += v.chr }

  rain_image = [
                0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00,
                0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00,
                0x00, 0x10, 0x01, 0x03, 0x00, 0x00, 0x00, 0x11, 0x44, 0xac, 0x3e,
                0x00, 0x00, 0x00, 0x06, 0x50, 0x4c, 0x54, 0x45, 0x00, 0x00, 0x00,
                0xc0, 0xc0, 0xc0, 0x64, 0x56, 0x3a, 0x71, 0x00, 0x00, 0x00, 0x01,
                0x74, 0x52, 0x4e, 0x53, 0x00, 0x40, 0xe6, 0xd8, 0x66, 0x00, 0x00,
                0x00, 0x1f, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7, 0x63, 0x60, 0x64,
                0x60, 0x64, 0x60, 0x02, 0x42, 0x16, 0x20, 0xe4, 0x00, 0x42, 0x01,
                0x20, 0x54, 0x00, 0x42, 0x07, 0x20, 0x6c, 0x60, 0x68, 0x00, 0x00,
                0x0b, 0xd4, 0x01, 0xff, 0xed, 0x11, 0x33, 0x32, 0x00, 0x00, 0x00,
                0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
               ].reduce('') { |tmp, v| tmp += v.chr }

  def init_weather
    if @weather_plane.nil?
      @weather_plane = Plane.new
      @weather_surface = Bitmap.new 320, 240
      @weather_plane.bitmap = @weather_surface
      @weather_plane.z = 9999
    end
    @weather_surface.clear

    @rain_bitmap = Bitmap.load_raw rain_image if @rain_bitmap.nil?
    @snow_bitmap = Bitmap.load_raw snow_image if @snow_bitmap.nil?
  end

  def stop_weather
    @weather_plane = nil
    @snowflakes.clear
  end

  def init_snow_rain
    return unless @snowflakes.empty?

    for i in 0...(100 * (data.weather_strength + 1))
      @snowflakes.push Snowflake.new(rand * 440.0 / RAND_MAX, rand, rand)
    end
  end

  def update_snow_rain(speed)
    @snowflakes.each { |v|
      v.x += speed
      v.life += 1
      v.life = 0 if v.life > @snowflake_life
    }
  end

  def draw_rain
    @weather_plane.opacity = 192
    rect = @rain_bitmap.rect
    @snowflakes.each { |v|
      @weather_surface.blit v.x - v.y / 2, v.y, @rain_bitmap, rect, 255 if v.life <= @snowflake_visible
    }
  end

  wobble = [
            [-1,-1, 0, 1, 0, 1, 1, 0,-1,-1, 0, 1, 0, 1, 1, 0,-1, 0],
            [-1,-1, 0, 0, 1, 1, 0,-1,-1, 0, 1, 0, 1, 1, 0,-1, 0, 0]
           ]

  def draw_snow
    @weather_plane.opacity = 192
    rect = @snow_bitmap.rect
    @snowflakes.each { |v|
      if f.life <= @snowflake_visible
        x, y = v.x - v.y / 2, v.y
        i = (y / 2) % 18
        @weather_surface.blit x + wobble[0][i], y + wobble[1][i], @snow_bitmap, rect, 255
      end
    }
  end

  effect_opacities = [128, 160, 192]

  def draw_fog
    @weather_surface.fill @weather_surface.react, Color.new(128, 128, 128, 255)
    @weather_plane.opacity = effect_opacities[data.weather_strength]
  end

  def draw_sandstorm
    @weather_surface.fill @weather_surface.rect, Color.new(192, 160, 128, 255)
    @weather_plane.opacity = effect_opacities[data.weather_strength]
  end

  def interpolate(d, x0, x1) (x0 * (d - 1) + x1) / d end

  def update
    if (data.tint_time_left > 0)
      data.tint_current_red = interpolate(data.tint_time_left, data.tint_current_red, data.tint_finish_red)
      data.tint_current_green = interpolate(data.tint_time_left, data.tint_current_green, data.tint_finish_green)
      data.tint_current_blue = interpolate(data.tint_time_left, data.tint_current_blue, data.tint_finish_blue)
      data.tint_current_sat = interpolate(data.tint_time_left, data.tint_current_sat, data.tint_finish_sat)
      data.tint_time_left -= 1
    end

    if (data.flash_time_left > 0)
      data.flash_current_level = interpolate(data.flash_time_left, data.flash_current_level / 31, 0)
      data.flash_time_left -= 1
      data.flash_time_left = data.flash_continuous ? flash_period : 0 if data.flash_time_left <= 0
    end

    if (data.shake_continuous || data.shake_time_left > 0 || data.shake_position != 0)
      double delta = (data.shake_strength * data.shake_speed * shake_direction) / 10.0
      if (data.shake_time_left <= 1 && data.shake_position * (data.shake_position + delta) < 0)
        data.shake_position = 0
      else
        data.shake_position += delta
      end
      shake_direction = -1 if (data.shake_position > data.shake_strength * 2)
      shake_direction = 1 if (data.shake_position < -data.shake_strength * 2)
      data.shake_time_left -= 1 if (data.shake_time_left > 0)
    end

    @pictures.each { |v| v && v.update }

    unless @movie_filename.empty?
      # update movie
    end

    case data.weather
    when Weather_None
    when Weather_Rain
      init_weather
      init_snow_rain
      update_snow_rain 4
      draw_rain
    when Weather_Snow
      init_weather
      init_snow_rain
      update_snow_rain 2
      draw_snow
    when Weather_Fog
      init_weather
      draw_fog
    when Weather_Sandstorm
      init_weather
      draw_sandstorm
    end

    if @animation
      @animation.update
      @animation = nil if @animation.done?
    end
  end
end

class Game_Screen::Snowflake
  attr_accessor :x, :y, :life

  def initialize(x, y, life)
    @x, @y = x, y
    @life = life
  end
end
