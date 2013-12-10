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


class BattleAnimation < Sprite
  def initialize(x, y, animation)
    self.x, self.y = x, y
    @animation = animation
    @frame = 0
    @initialized = false
    @update = true
  end

  def z; 400; end

  def setup
    return if @initialized

    name = animation.animation_name

    if not FileFinder.find_image("Battle", name).empty?
      @large = false
      graphic = Cache.battle name
    elsif not FileFinder.find_image("Battle2", name).empty?
      @large = true
      graphic = Cache.Battle2 name
    else
      Output.warning("Couldn't find animation: %s" % name)
      self.visible = false
      return
    end

    self.bitmap = graphic
    @initialized = true
  end

  def update
    frame += 1 if @update
    @update = !@update

    return if done?

    setup

    @animation.frames[@frame].cells.each do |cell|
      sx, sy = cell.cell_id % 5, cell.cell_id / 5
      size = large ? 128 : 96
      zoomed = size * cell.zoom / 100
      self.src_rect = Rect.new sx * size, sy * size, size, size
      self.zoom_x_effect = cell.zoom / 100.0
      self.zoom_y_effect = cell.zoom / 100.0
      self.tone = Tone.new cell.tone_red, cell.tone_green, cell.tone_blue, cell.tone_gray
      self.opacity = 255 * (100 - cell.transparency) / 100
      self.x, self.y = x + cell.x - zoomed / 2, y + cell.y - zoomed / 2
    end
  end

  attr_accessor :frame

  def frames; @animation.frames.length; end

  def done?; frame >= frames; end
end
