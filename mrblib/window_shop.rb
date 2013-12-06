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

# Window Shop Class.
class Window_Shop < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih

    case(Game_Temp.shop_type)
    when 0
      @greeting = Data.term.shop_greeting1
      @regreeting = Data.term.shop_regreeting1
      @buy_msg = Data.term.shop_buy1
      @sell_msg = Data.term.shop_sell1
      @leave_msg = Data.term.shop_leave1
      @buy_select = Data.term.shop_buy_select1
      @buy_number = Data.term.shop_buy_number1
      @purchased = Data.term.shop_purchased1
      @sell_select = Data.term.shop_sell_select1
      @sell_number = Data.term.shop_sell_number1
      @sold_msg = Data.term.shop_sold1
    when 1
      @greeting = Data.term.shop_greeting2
      @regreeting = Data.term.shop_regreeting2
      @buy_msg = Data.term.shop_buy2
      @sell_msg = Data.term.shop_sell2
      @leave_msg = Data.term.shop_leave2
      @buy_select = Data.term.shop_buy_select2
      @buy_number = Data.term.shop_buy_number2
      @purchased = Data.term.shop_purchased2
      @sell_select = Data.term.shop_sell_select2
      @sell_number = Data.term.shop_sell_number2
      @sold_msg = Data.term.shop_sold2
    when 2
      @greeting = Data.term.shop_greeting3
      @regreeting = Data.term.shop_regreeting3
      @buy_msg = Data.term.shop_buy3
      @sell_msg = Data.term.shop_sell3
      @leave_msg = Data.term.shop_leave3
      @buy_select = Data.term.shop_buy_select3
      @buy_number = Data.term.shop_buy_number3
      @purchased = Data.term.shop_purchased3
      @sell_select = Data.term.shop_sell_select3
      @sell_number = Data.term.shop_sell_number3
      @sold_msg = Data.term.shop_sold3
    end

    @mode = Scene_Shop::BuySellLeave
    @index = 1

    refresh()
  end

  # Renders the current shop on the window.
  def refresh
    contents.clear

    case @mode
    when Scene_Shop::BuySellLeave, Scene_Shop::BuySellLeave2
      idx = 0

      contents.draw_text_2k(2, 4,
                         @mode == Scene_Shop::BuySellLeave2 ? regreeting : greeting,
                         Font::ColorDefault)
      idx += 1

      contents.draw_text_2k 12, 4 + idx * 16, buy_msg, Font::ColorDefault
      buy_index = idx
      idx += 1

      contents.draw_text_2k 12, 4 + idx * 16, sell_msg, Font::ColorDefault
      sell_index = idx
      idx += 1

      contents.draw_text_2k 12, 4 + idx * 16, leave_msg, Font::ColorDefault
      leave_index = idx
      idx += 1
    when Scene_Shop::Buy
      contents.draw_text_2k 2, 2, buy_select, Font::ColorDefault
    when Scene_Shop::BuyHowMany
      contents.draw_text_2k 2, 2, buy_number, Font::ColorDefault
    when Scene_Shop::Bought
      contents.draw_text_2k 2, 2, purchased, Font::ColorDefault
    when Scene_Shop::Sell
      contents.draw_text_2k 2, 2, sell_select, Font::ColorDefault
    when Scene_Shop::SellHowMany
      contents.draw_text_2k 2, 2, sell_number, Font::ColorDefault
    when Scene_Shop::Sold
      contents.draw_text_2k 2, 2, sold_msg, Font::ColorDefault
    end
  end

  # Updates the window.
  def update
    super

    if active
      case mode
      when Scene_Shop::BuySellLeave, Scene_Shop::BuySellLeave2
        if Input.repeat? Input::DOWN
          if index < leave_index
            index += 1
          else
            index = 1
          end
          Game_System.se_play Game_System::SFX_Cursor
        end
        if Input.repeat? Input::UP
          if index > 1; index -= 1
          else index = leave_index
          end
          Game_System.se_play Game_System::SFX_Cursor
        end
        if Input.trigger? Input::DECISION
          Game_System.se_play Game_System::SFX_Decision
          if index == buy_index
            choice = Scene_Shop::Buy
          elsif index == sell_index
            choice = Scene_Shop::Sell
          elsif index == leave_index
            choice = Scene_Shop::Leave
          end
        end
      end
    end

    update_cursor_rect
  end

  def mode=(nmode)
    @mode = nmode
    refresh
  end

  attr_accessor :choice

  def update_cursor_rect
    case mode
    when Scene_Shop::BuySellLeave, Scene_Shop::BuySellLeave2
      rect = Rect.new 4, index * 16 + 2, contents.width - 8, 16
    else
      rect = Rect.new
    end

    cursor_rect = rect
  end
end

# Window Shop Buy Class
# The shop item list window.
class Window_ShopBuy < Window_Selectable
  # Constructor.
  def initialize(x, y, w = 320, h = 80)
    super ix, iy, iw, ih
    @index = 0
  end

  # Gets item ID of the selected item.
  #
  # @return current selected item ID.
  def item_id
    index < 0 ? 0 : data[index]
  end

  # Refreshes the item list.
  def refresh
    @data = Game_Temp.shop_goods
    @item_max = data.length

    create_contents
    contents.clear

    for i in 0...data.length; draw_item i; end
  end

  # Draws an item together with the price.
  #
  # @param index index of item to draw.
  def draw_item(index)
    id = data[index]
    enabled = Data.items[id].price <= Game_Party.gold
    rect = item_rect(index)
    contents.fill rect, Color.new()
    draw_item_name Data.items[id], rect.x, rect.y, enabled

    contents.draw_text_2k rect.width + 4, rect.y, Data.items[id].price.to_s, enabled ? Font::ColorDefault : Font::ColorDisabled, Text::AlignRight
  end

  # Updates the help window.
  def update_help
    help_window.text = item_id == 0 ? ""  : Data.items[item_id].description
  end

  # Checks if the item should be enabled.
  #
  # @param item_id item id to check.
  # @return true if it is enabled.
  def check_enable(id)
    id > 0 and
      Data.items[id].price <= Game_Party.gold and
      Game_Party.item_number(id) < 99
  end
end

# Window Shop Number Class.
# The number input window for the shop.
class Window_ShopNumber < Window_Base
  attr_reader :number

  # Constructor.
  #
  # @param x window x position.
  # @param y window y position.
  # @param w window width.
  # @param h window height.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @item_max = 1
    @price = 0
    @number = 1
    @item_id = 0
  end

  # Updates the Windows contents.
  def refresh
    contents.clear

    y = 34
    draw_item_name Data.items[item_id], 0, y

    contents.draw_text_2k 132, y, "x", Font::ColorDefault
    contents.draw_text_2k 132 + 30, y, @number.to_s, Font::ColorDefault, Text::AlignRight
    cursor_rect = Rect.new 132 + 14, y - 2, 20, 16

    draw_currency_value(total, contents.width, y + 32)
  end

  # Updates number value according to user input.
  def update
    super

    if active
        int last_number = number
      if Input.repeat?(Input::RIGHT) && number < item_max
        number += 1
      elsif Input.repeat?(Input::LEFT) && number > 1
        number -= 1
      elsif Input.repeat?(Input::UP) && number < item_max
        number = [number + 10, item_max].min
      elsif Input.repeat?(Input::DOWN) && number > 1
        number = [number - 10, 1].max
      end
    end

    if last_number != number
      Game_System.se_play Game_System::SFX_Cursor
      refresh
    end
  end

  # Sets all data needed for the window.
  #
  # @param id item to buy.
  # @param max item maximum quantity.
  # @param price Price of the item.
  # @return the currently input number.
  def set_data(id, max, price)
    @item_id = id
    @item_max = max
    @price = price
    @number = 1
  end

  # Returns the total costs.
  #
  # @return total costs to buy the item.
  def total
    Data.items[@item_id].price * @number
  end
end

# Window ShopParty Class.
# Displays the party in the shop scene.
class Window_ShopParty < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih

    @cycle = 0
    @item_id = 0

    @bitmaps = Array.new(4) { Array.new(3) { Array.new(2) } }

    Game_Party.actors.each { |actor|
      sprite_id = actor.charset_index
      bm = Cache.charset actor.charset
      width = bm.width / 4 / 3
      height = bm.height / 2 / 4
      for j in 0...3
          sx = ((sprite_id % 4) * 3 + j) * width
          sy = ((sprite_id / 4) * 4 + 2) * height
          Rect src(sx, sy, width, height)
          for k in 0...2
            bm2 = Bitmap.new width, height
            bm2.blit 0, 0, bm, src, 255
            if k == 0
              bm2.tone_blit BlitCommon.new(0, 0, bm2, bm2.rect), Tone.new(0, 0, 0, 255)
              bitmaps[i][j][k] = bm2
            end
          end
      end
    }

    refresh
  end

  # Renders the current party on the window.
  def refresh
    contents.clear

    system = Cache.system Game_System.system_name

    Game_Party.actors.each { |actor|
      phase = (@cycle / @anim_rate) % 4
      phase = 1 if phase == 3
      equippable = @item_id == 0 || actor.equippable?(item_id)
      bm = bitmaps[i][phase][equippable ? 1 : 0]
      contents.blit i * 32, 0, bm, bm.rect, 255

      if equippable
        # check if item is equipped by each member
        is_equipped = false
        for j in 0...5; is_equipped |= (actor.equipment(j) == item_id); end
        if is_equipped
          contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 24, 8, 8), 255
        else
          new_item = Data.items[@item_id]
          new_item_id = actor.equipment(new_item.type - RPG::Item::Type_weapon)
          current_item = new_item_id != 0 ? Data.items[new_item_id] : Data.items[1]

          if not current_item.nil?
            diff_atk = new_item.atk_points1 - current_item.atk_points1
            diff_def = new_item.def_points1 - current_item.def_points1
            diff_spi = new_item.spi_points1 - current_item.spi_points1
            diff_agi = new_item.agi_points1 - current_item.agi_points1
            if diff_atk > 0 || diff_def > 0 || diff_spi > 0 || diff_agi > 0
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 0, 8, 8), 255
            elsif diff_atk < 0 || diff_def < 0 || diff_spi < 0 || diff_agi < 0
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 16, 8, 8), 255
            else
              contents.blit i * 32 + 20, 24, system, Rect.new(128 + 8 * phase, 8, 8, 8), 255
            end
          end
        end
      end
    }
  end

  # Updates the window state.
  def update
    @cycle += 1
    refresh if @cycle % @anim_rate == 0
  end

  # Sets the reference item.
  def item_id=(id)
    if id != @item_id
      @item_id = nitem_idid
      refresh
    end
  end

  # Animation rate.
  @anim_rate = 12
end

# Window ShopSell class.
# Displays all items of the party and allows to sell them.
class Window_ShopSell < Window_Item
  # Chechs if item should be enabled.
  #
  # @param item_id item to check.
  def check_enable(item_id)
    Data.items[item_id].price > 0
  end
end

# Window ShopStatus Class.
# Displays possessed and equipped items.
class Window_ShopStatus < Window_Base
  # Constructor.
  def initialize(ix, iy, iw, ih)
    super ix, iy, iw, ih
    @item_id = 0

    refresh
  end

  # Renders the current total on the window.
  def refresh
    contents.clear

    if item_id != 0
      contents.draw_text_2k 0, 2, Data.term.possessed_items, 1
      contents.draw_text_2k 0, 18, Data.term.equipped_items, 1

      contents.draw_text_2k 120, 2, Game_Party.item_number(item_id).to_s, Font::ColorDefault, Text::AlignRight
      contents.draw_text_2k 120, 18, Game_Party.item_number(item_id, true).to_s, Font::ColorDefault, Text::AlignRight
    end
  end

  # Sets the item to display.
  #
  # @param item_id ID of item to use.
  def item_id=(new_item_id)
    if new_item_id != @item_id
      @item_id = new_item_id
      refresh()
    end
  end
end
