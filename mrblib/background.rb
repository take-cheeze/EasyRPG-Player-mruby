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

class Background
  def initialize(v)
    @bg_hscroll = 0
    @bg_vscroll = 0
    @bg_x = 0
    @bg_y = 0
    @fg_hscroll = 0
    @fg_vscroll = 0
    @fg_x = 0
    @fg_y = 0

    if v.is_a? String
      @bg_screen = Plane.new
      @bg_screen.bitmap = Cache.backdrop v
    else
      terrain = Data.terrains[v];

      if terrain.background_type == 0
        @bg_screen = Plane.new
        @bg_screen.bitmap = Cache.backdrop terrain.background_name
      else
        @bg_screen = Plane.new
        @bg_screen.bitmap = Cache.backdrop terrain.background_a_name
        @bg_hscroll = terrain.background_a_scrollh_speed if terrain.background_a_scrollh
        @bg_vscroll = terrain.background_a_scrollv_speed if terrain.background_a_scrollv

        if terrain.background_b
          @fg_screen = Plane.new
          @fg_screen.bitmap = Cache.frame terrain.background_b_name
          @fg_hscroll = terrain.background_b_scrollh_speed if terrain.background_b_scrollh
          @fg_vscroll = terrain.background_b_scrollv_speed if terrain.background_b_scrollv
        end
      end
    end

    @bg_screen.z = -1000 unless @bg_screen.nil?
    @fg_screen.z = -1000 unless @fg_screen.nil?
  end

  def update_coord(rate, v)
    v + ((rate > 0) ? (1 << rate) : (rate < 0) ? (1 << -rate) : 0)
  end

  def update
    @bg_x = update_coord @bg_hscroll, @bg_x
    @bg_y = update_coord @bg_vscroll, @bg_y
    @fg_x = update_coord @fg_hscroll, @fg_x
    @fg_y = update_coord @fg_vscroll, @fg_y

    @bg_screen.ox = scale @bg_x
    @bg_screen.oy = scale @bg_y
    @fg_screen.ox = scale @fg_x
    @fg_screen.oy = scale @fg_y
  end
end
