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

# Window_Skill class.
class Window_Skill < Window_Selectable

  # Constructor.
  def initialize(ix, iy, iwidth, iheight)
    super ix, iy, iwidth, iheight
    @actor_id = nil
    @column_max = 2
  end

  # Sets the actor whose skills are displayed.
  #
  # @param actor_id ID of the actor.
  def actor=(id)
    @actor_id = id
    refresh
  end

  # Gets skill.
  #
  # @return current selected skill ID.
  def skill_id()
    @index < 0 ? 0 : data[@index]
  end

  # Refreshes the skill list.
  def refresh
    data = []

    skills = Game_Actors.actor(actor_id).skills
    skills.each { |v| data.push v if check_include v }

    create_contents

    contents.clear

    data.push 0 if data.empty?

    for i in 0...data.length; draw_item i; end
  end

  # Draws a skill together with the costs.
  #
  # @param index index of skill to draw.
  def draw_item(index)
    rect = item_rect(index)
    contents.fill(rect, Color.new)

    skill_id = data[index]

    if skill_id > 0
      costs = Data.skills[skill_id].sp_cost
      enabled = check_enable skill_id
      color = (not enabled) ? Font::ColorDisabled : Font::ColorDefault

      contents.draw_text_2k rect.x + rect.width - 28, rect.y, "-", color
      contents.draw_text_2k rect.x + rect.width - 6, rect.y, costs.to_s, color, Text::AlignRight

      draw_skill_name Data.skills[skill_id], rect.x, rect.y, enabled
    end
  end

  # Updates the help window.
  def update_help
    @help_window.text = skill_id == 0 ? "" : Data.skills[skill_id].description
  end

  # Checks if the skill should be in the list.
  #
  # @param skill_id skill to check.
  def check_include(id); true; end

  # Chechs if skill should be enabled.
  #
  # @param skill_id skill to check.
  def check_enable(id)
    Game_Actors.actor(@actor_id).skill_usable? id
  end
end

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
