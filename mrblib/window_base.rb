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

# Window Base class.
class Window_Base < Window
  # Constructor.
  #
  # @param x window x position.
  # @param y window y position.
  # @param w window width.
  # @param h window height.
  def initialize(ix, iy, iw, ih)
    super()
    @windowskin_name = Game_System.system_name
    self.windowskin = Cache.system @windowskin_name
    self.x, self.y = ix, iy
    self.width, self.height = iw, ih
    self.contents = Bitmap.new iw - 16, ih - 16
    self.z = 100
  end

  # Updates the window.
  def update
    super
    return if Game_System.system_name == @windowskin_name

    @windowskin_name = Game_System.system_name
    self.windowskin = Cache.system @windowskin_name
  end

  def draw_face(face_name, face_index, cx, cy, flip)
    faceset = Cache.faceset face_name

    r = Rect.new((face_index % 4) * 48, face_index / 4 * 48, 48, 48)
    if flip; contents.flip_blit BlitCommon.new(cx, cy, faceset, r), true, false
    else; contents.blit cx, cy, faceset, r, 255
    end
  end

  def draw_actor_face(actor, cx, cy); draw_face actor.face_name, actor.face_index, cx, cy; end
  def draw_actor_name(actor, cx, cy); contents.draw_text_2k cx, cy, actor.name, Font::ColorDefault; end
  def draw_actor_title(actor, cx, cy); contents.draw_text_2k cx, cy, actor.title, Font::ColorDefault; end
  def draw_actor_class(actor, cx, cy); contents.draw_text_2k cx, cy, actor.class_name, Font::ColorDefault; end

  def draw_actor_level(actor, cx, cy)
    # Draw LV-String
    contents.draw_text_2k cx, cy, Data.term.lvl_short, 1

    # Draw Level of the Actor
    contents.draw_text_2k cx + 24, cy, actor.level.to_s, Font::ColorDefault, Text::AlignRight
  end

  def draw_actor_state(actor, cx, cy)
    if actor.states.empty?; contents.draw_text_2k cx, cy, Data.term.normal_status, Font::ColorDefault
    else
      state = actor.significant_state
      contents.draw_text_2k cx, cy, state.name, state.color
    end
  end

  def draw_actor_exp(actor, cx, cy)
    # Draw EXP-String
    contents.draw_text_2k cx, cy, Data.term.exp_short, 1

    # Current Exp of the Actor
    # ------/------
    str = '%6s/%6s' % [actor.exp_string, actor.next_exp_string]
    contents.draw_text_2k cx + 12, cy, str, Font::ColorDefault, Text::AlignLeft
  end

  def draw_actor_hp(actor, cx, cy, draw_max)
    # Draw HP-String
    contents.draw_text_2k cx, cy, Data.term.hp_short, 1

    # Draw Current HP of the Actor
    cx += 12
    # Color: 0 okay, 4 critical, 5 dead
    if actor.hp == 0; color = Font::ColorKnockout
    elsif actor.hp <= actor.max_hp / 4; color = Font::ColorCritical
    else; color = Font::ColorDefault
    end
    contents.draw_text_2k cx + 18, cy, actor.hp.to_s, color, Text::AlignRight

    return if !draw_max

    # Draw the /
    cx += 3 * 6
    contents.draw_text_2k cx, cy, "/", Font::ColorDefault

    # Draw Max Hp
    cx += 6
    contents.draw_text_2k cx + 18, cy, actor.max_hp.to_s, Font::ColorDefault, Text::AlignRight
  end

  def draw_actor_sp(actor, cx, cy, draw_max)
    # Draw SP-String
    contents.draw_text_2k cx, cy, Data.term.sp_short, 1

    # Draw Current SP of the Actor
    cx += 12
    # Color: 0 okay, 4 critical/empty
    color = Font::ColorDefault
    color = Font::ColorCritical if (actor.max_sp != 0 && actor.sp <= actor.max_sp / 4)
    contents.draw_text_2k cx + 18, cy, actor.sp.to_s, color, Text::AlignRight

    return if !draw_max

    # Draw the /
    cx += 3 * 6
    contents.draw_text_2k cx, cy, "/", Font::ColorDefault

    # Draw Max Sp
    cx += 6
    contents.draw_text_2k cx + 18, cy, actor.max_sp.to_s, Font::ColorDefault, Text::AlignRight
  end

  def draw_actor_parameter(actor, cx, cy, type)
    case type
    when 0
      name = Data.term.attack
      value = actor.attack
    when 1
      name = Data.term.defense
      value = actor.defence
    when 2
      name = Data.term.spirit
      value = actor.spirit
    when 3
      name = Data.term.agility
      value = actor.agility
    else; return
    end

    # Draw Term
    contents.draw_text_2k cx, cy, name, 1

    # Draw Value
    contents.draw_text_2k cx + 78, cy, value.to_s, Font::ColorDefault, Text::AlignRight
  end

  def draw_equipment_type(actor, cx, cy, type)
    case type
    when 0
      name = Data.term.weapon
    when 1
      if actor.two_swords_style?
        name = Data.term.weapon
      else
        name = Data.term.shield
      end
    when 2
      name = Data.term.armor
    when 3
      name = Data.term.helmet
    when 4
      name = Data.term.accessory
    else; return
    end

    contents.draw_text_2k cx, cy, name, 1
  end

  def draw_item_name(item, cx, cy, enabled)
    contents.draw_text_2k cx, cy, item.name, enabled ? Font::ColorDefault : Font::ColorDisabled
  end

  def draw_skill_name(skill, cx, cy, enabled)
    contents.draw_text_2k cx, cy, skill.name, enabled ? Font::ColorDefault : Font::ColorDisabled
  end

  def draw_currency_value(money, cx, cy)
    # This function draws right aligned because of the dynamic with of the
    # gold output (cx and cy define the right border)
    gold_text_size = contents.text_size Data.term.currency
    contents.draw_text_2k cx, cy, Data.term.currency, 1, Text::AlignRight

    contents.draw_text_2k cx - gold_text_size.width, cy, money.to_s, Font::ColorDefault, Text::AlignRight
  end
end
