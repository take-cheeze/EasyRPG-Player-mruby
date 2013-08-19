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

# Window_SkillStatus class.
class Window_SkillStatus < Window_Base

	# Constructor.
	def initialize(ix, iy, iwidth, iheight)
    super(ix, iy, iwidth, iheight)
    @actor_id = nil
    contents = Bitmap.new(width - 16, height - 16)
  end

	# Sets the actor whose stats are displayed.
	# @param actor_id ID of the actor.
	def actor=(v)
    @actor_id = v
    refresh
  end

	# Renders the stats of the actor.
	def refresh
    contents.fill Rect.new(0, 0, contents.width, 16), Color.new()

    actor = Game_Actors.actor(@actor_id)

    draw_actor_name(actor, 0, 0)
    draw_actor_level(actor, 80, 0)
    draw_actor_state(actor, 80 + 44, 0)
    draw_actor_hp(actor, 80 + 44 + 60, 0)
    draw_actor_sp(actor, 80 + 44 + 60 + 66, 0)
  end
end
