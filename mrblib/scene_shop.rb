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

# Scene Shop class.
# Manages buying and selling of items.
class Scene_Shop < Scene

  # Constructor.
  def initialize; super "Shop"; end

  def start
    @shop_window = Window_Shop.new 0, 160, 320, 80
    @help_window = Window_Help.new 0, 0, 320, 32
    @gold_window = Window_Gold.new 184, 128, 136, 32
    @empty_window = Window_Base.new 0, 32, 320, 128
    @empty_window2 = Window_Base.new 0, 32, 184, 128
    @buy_window = Window_ShopBuy.new 0, 32, 184, 128
    @party_window = Window_ShopParty.new 184, 32, 136, 48
    @sell_window = Window_ShopSell.new 0, 32, 320, 128
    @status_window = Window_ShopStatus.new 184, 80, 136, 48
    @number_window = Window_ShopNumber.new 0, 32, 184, 128

    [@buy_window, @sell_window].each { |v|
      enable v, false
      v.help_window = @help_window
    }
    enable @number_window, false

    @status_window.visible = false
    @sell_window.refresh
    @sell_window.index = 0
    @sell_window.active = true

    Game_Temp.shop_transaction = false
    @timer = 0

    if Game_Temp.shop_buys && Game_Temp.shop_sells
      self.mode = BuySellLeave
    elsif Game_Temp.shop_buys
      @shop_window.choice = Buy
      self.mode = Buy
    else
      @shop_window.choice = Sell
      self.mode = Sell
    end
  end

  BuySellLeave = 0
  BuySellLeave2 = 1
  Buy = 2
  BuyHowMany = 3
  Bought = 4
  Sell = 5
  SellHowMany = 6
  Sold = 7
  Leave = 8

  def mode=(m)
    @mode = m
    @help_window.text = ''

    # Central panel
    case mode
    when BuySellLeave, BuySellLeave2
      @empty_window.visible = true
      enable @sell_window, false
    when Sell
      @empty_window.visible = false
      enable @sell_window, true
    when Buy, BuyHowMany, SellHowMany, Bought, Sold
      @empty_window.visible = false
      enable @sell_window, false
    end

    # Right-hand panels
    case mode
    when BuySellLeave, BuySellLeave2, Sell
      @party_window.visible = false
      @status_window.visible = false
      @gold_window.visible = false
    when Buy, BuyHowMany, SellHowMany, Bought, Sold
      @party_window.visible = true
      @status_window.visible = true
      @gold_window.visible = true
    end

    # Left-hand panels
    case mode
    when BuySellLeave, BuySellLeave2, Sell
      enable @buy_window, false
      enable @number_window, false
      @empty_window2.visible = false
    when Buy
      @buy_window.refresh
      enable @buy_window, true
      enable @number_window, false
      @empty_window2.visible = false
    when BuyHowMany, SellHowMany
      @number_window.refresh
      enable @buy_window, false
      enable @number_window, true
    when Bought, Sold
      enable @buy_window, false
      enable @number_window, false
      @empty_window2.visible = true

      @timer = DEFAULT_FPS
    end

    @shop_window.mode = mode
  end

  def update
    @buy_window.update
    @sell_window.update
    @shop_window.update
    @number_window.update
    @party_window.update

    case mode
    when BuySellLeave, BuySellLeave2; update_command_selection
    when Buy; update_buy_selection
    when Sell; update_sell_selection
    when BuyHowMany, SellHowMany; update_number_input
    when Bought
      timer -= 1
      self.mode = Buy if (timer == 0)
    when Sold
      timer -= 1
      self.mode = Sell if (timer == 0)
    end
  end

  def update_command_selection
    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      Scene.pop
    elsif Input.trigger? Input::DECISION
      case @shop_window.choice
      when Buy, Sell; self.mode = @shop_window.choice
      when Leave; Scene.pop
      end
    end
  end

  def update_buy_selection
    @status_window.item_id = @buy_window.item_id
    @party_window.item_id = @buy_window.item_id

    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      if Game_Temp.shop_sells; self.mode = BuySellLeave2
      else; Scene.pop
      end
    elsif Input.trigger? Input::DECISION
      item_id = @buy_window.item_id

      # checks the money and number of items possessed before buy
      if @buy_window.check_enable item_id
        Game_System.se_play $game_data.system.decision_se

        item = Data.items[item_id]
        max = item.price == 0 ? 99 : Game_Party.gold / item.price
        @number_window.set_data item_id, max, item.price

        self.mode = BuyHowMany
      else
        Game_System.se_play $game_data.system.buzzer_se
      end
    end
  end

  def update_sell_selection
    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      if Game_Temp.shop_buys; self.mode = BuySellLeave2
      else; Scene.pop
      end
    elsif Input.trigger? Input::DECISION
      item_id = @sell_window.item_id
      @status_window.item_id = item_id
      @party_window.item_id = item_id

      if item_id > 0 && Data.items[item_id].price > 0
        item = Data.items[item_id]
        Game_System.se_play $game_data.system.decision_se
        @number_window.set_data item_id, Game_Party.item_number(item_id), item.price
        self.mode = SellHowMany
      else
        Game_System.se_play $game_data.system.buzzer_se
      end
    end
  end

  def update_number_input
    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      case @shop_window.choice
      when Buy; self.mode = Buy
      when Sell; self.mode = Sell
      end
    elsif Input.trigger? Input::DECISION
      case shop_window.GetChoice
      when Buy
        Game_Party.lose_gold @number_window.total
        Game_Party.gain_item @buy_window.item_id, @number_window.number
        @gold_window.refresh
        @buy_window.refresh
        @status_window.refresh
        self.mode = Bought
      when Sell
        item_id =
          Game_Party.gain_gold @number_window.total
        Game_Party.lose_item @sell_window.item_id, @number_window.number
        @gold_window.refresh
        @sell_window.refresh
        @status_window.refresh
        self.mode = Sold
      end
      Game_System.se_play $game_data.system.decision_se

      Game_Temp.shop_transaction = true
    end
  end

  def enable(window, state)
    window.visible = state
    window.active = state
  end
end
