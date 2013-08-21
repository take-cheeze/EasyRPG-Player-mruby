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

# Game Temp static class.
module Game_Temp
  BattleNormal = 0
  BattleInitiative = 1
  BattleSurround = 2
  BattleBackAttack = 3
  BattlePincer = 4

  BattleVictory = 0
  BattleEscape = 1
  BattleDefeat = 2
  BattleAbort = 3

  attr_accessor(:menu_calling, :menu_beep, :forcing_battler,
                :battle_calling, :shop_calling, :name_calling, :save_calling, :inn_calling,
                :to_title, :gameover,
                :common_event_id,
                :transition_processing, :transition_type, :transition_erase,
                :shop_buys, :shop_sells, :shop_type, :shop_handlers, :shop_goods, :shop_transaction,
                :inn_type, :inn_price, :inn_handlers, :inn_stay,
                :hero_name, :hero_name_id, :hero_name_charset,
                :battle_troop_id, :battle_background, :battle_mode, :battle_terrain_id,
                :battle_formation, :battle_escape_mode, :battle_defeat_mode, :battle_first_strike,
                :battle_result, :battle_wait,
                :map_bgm)

  def init
    @menu_calling = false
    @menu_beep = false

    @forcing_battler = nil

    @battle_calling = false
    @shop_calling = false
    @name_calling = false
    @save_calling = false
    @to_title = false
    @gameover = false
    @inn_calling = false

    @common_event_id = 0

    @transition_processing = false
    @transition_type = Graphics::TransitionNone
    @transition_erase = false

    @shop_buys = true
    @shop_sells = true
    @shop_type = 0
    @shop_handlers = false
    @shop_goods = []
    @shop_transaction = false

    @inn_type = 0
    @inn_price = 0
    @inn_handlers = false
    @inn_stay = false

    @hero_name = ''
    @hero_name_id = 0
    @hero_name_charset = 0

    @battle_troop_id = 0
    @battle_background = ''
    @battle_mode = 0
    @battle_terrain_id = 0
    @battle_formation = 0
    @battle_escape_mode = 0
    @battle_defeat_mode = 0
    @battle_first_strike = false
    @battle_result =  nil
    @battle_wait = false
    @map_bgm = nil
  end
end
