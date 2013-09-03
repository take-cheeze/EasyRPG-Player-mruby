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

    contents = Bitmap.new iw - 16, ih - 16

    case(Game_Temp.shop_type)
    when 0
      @greeting = Data.terms.shop_greeting1
      @regreeting = Data.terms.shop_regreeting1
      @buy_msg = Data.terms.shop_buy1
      @sell_msg = Data.terms.shop_sell1
      @leave_msg = Data.terms.shop_leave1
      @buy_select = Data.terms.shop_buy_select1
      @buy_number = Data.terms.shop_buy_number1
      @purchased = Data.terms.shop_purchased1
      @sell_select = Data.terms.shop_sell_select1
      @sell_number = Data.terms.shop_sell_number1
      @sold_msg = Data.terms.shop_sold1
    when 1
      @greeting = Data.terms.shop_greeting2
      @regreeting = Data.terms.shop_regreeting2
      @buy_msg = Data.terms.shop_buy2
      @sell_msg = Data.terms.shop_sell2
      @leave_msg = Data.terms.shop_leave2
      @buy_select = Data.terms.shop_buy_select2
      @buy_number = Data.terms.shop_buy_number2
      @purchased = Data.terms.shop_purchased2
      @sell_select = Data.terms.shop_sell_select2
      @sell_number = Data.terms.shop_sell_number2
      @sold_msg = Data.terms.shop_sold2
    when 2
      @greeting = Data.terms.shop_greeting3
      @regreeting = Data.terms.shop_regreeting3
      @buy_msg = Data.terms.shop_buy3
      @sell_msg = Data.terms.shop_sell3
      @leave_msg = Data.terms.shop_leave3
      @buy_select = Data.terms.shop_buy_select3
      @buy_number = Data.terms.shop_buy_number3
      @purchased = Data.terms.shop_purchased3
      @sell_select = Data.terms.shop_sell_select3
      @sell_number = Data.terms.shop_sell_number3
      @sold_msg = Data.terms.shop_sold3
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
