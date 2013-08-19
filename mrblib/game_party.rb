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

# Game_Party class.
module Game_Party
	# Initializes Game_Party.
  def init
    @data = Main_Data.game_data.inventory
    @data.setup
  end

	# Setups initial party.
	# void SetupStartingMembers()

	# Setups battle test party.
	# void SetupBattleTestMembers()

	# Refreshes party members.
	# void Refresh()

	# Gets maximum level.
	#
	# @return max party level.
	# int MaxLevel()

	# Adds an actor to the party.
	#
	# @param actor_id database actor ID.
  def add_actor(actor_id)
    return if actor_in_party? actor_id
    return if @data.party.length >= 4
    @data.party.psuh actor_id
    Main_Data.game_player.refresh
  end

	# Removes an actor from the party.
	#
	# @param actor_id database actor ID.
  def remove_actor(actor_id)
    return if not actor_in_party? actor_id

    @data.party.delete @data.party.index(actor_id)
    Main_Data.game_player.refresh
  end

	# Gets if an actor is in party.
	#
	# @param actor_id database actor ID.
	# @return whether the actor is in party.
  def actor_in_party?(actor_id) not @data.find(actor_id).nil? end

	# Gains gold.
	#
	# @param value gained gold.
  def gain_gold(value)
    @data.gold += value
    @data.gold = [0, [@data.gold, 999999].min].max
  end

	# Loses gold.
	#
	# @param value lost gold.
  def lose_gold(value)
    @data.gold -= value
    @data.gold = [0, [@data.gold, 999999].min].max
  end

	# Increases steps in 1.
	# void IncreaseSteps()

	# Returns all items of the party.
	#
	# @param item_list vector to fill.
  def items; @data.item_ids.dup;  end

	# Gets number of possessed or equipped items.
	#
	# @param item_id database item ID.
	# @param get_equipped if true this returns the number
	#                     of equipped items.
	# @return number of items.
	def item_number(item_id, get_equipped = false)
    if (get_equipped && item_id != 0)
      number = 0
      @data.party.each { |v|
        actor = Game_Actors.actor(v)
        number += 1 if actor.weapon_id == item_id
        number += 1 if actor.shiled_id == item_id
        number += 1 if actor.armor_id == item_id
        number += 1 if actor.helmet_id == item_id
        number += 1 if actor.accessory_id == item_id
      }
      return number
    else
      idx = @data.item_ids.index item_id
      return @data.item_counts[idx] if not idx.nil?
    end
    0
  end

	# Gains an amount of items.
	#
	# @param item_id database item ID.
	# @param amount gained quantity.
  def gain_item(item_id, amount)
    if item_id < 1 || item_id > Data.items.length
      Output.warning('can\'t add item to party (%04d is not a valid item ID)' % item_id)
      return
    end

    idx = @data.item_ids.index item_id
    if idx.nil? # Item isn't in the inventory yet
      if amount > 0
        @data.item_ids.push item_id
        @data.item_counts.push [amount, 99].min
        @data.item_usage.push Data.items[item_id].uses
      end
    else
      total_items = @data.item_counts[idx] + amount

      if total_items <= 0
        @data.item_ids.delete idx
        @data.item_counts.delete idx
        @data.item_usage.delete idx
      else @data.item_counts[idx] = [0, [total_items, 99].min].max
      end
    end
  end

	# Loses an amount of items.
	#
	# @param item_id database item ID.
	# @param amount lost quantity.
	def lose_item(item_id, amount) gain_item item_id, -amount end

	# Gets if item can be used.
	#
	# @param item_id database item ID.
	# @return whether the item can be used.
  def item_usable?(item_id)
    if item_id > 0 && item_id <= Data.items.length
      # TODO: if (Game_Temp::IsInBattle())
      # if (Data::items[item_id - 1].type == RPG::Item::Type_medicine)
      # 	return !Data::items[item_id - 1].ocassion_field
      # elsif (Data::items[item_id - 1].type == RPG::Item::Type_switch)
      # 	return Data::items[item_id - 1].ocassion_battle
      # else
      if (not @data.party.empty? &&
          (Data.items[item_id].type == RPG::Item::Type_medicine ||
           Data.items[item_id].type == RPG::Item::Type_material ||
           Data.items[item_id].type == RPG::Item::Type_book))
        return true
      elsif Data.items[item_id].type == RPG::Item::Type_switch
        return Data.items[item_id].occasion_field2
      end
    end

    false
  end

	# Clears all actors in party actions.
	# void ClearActions()

	# Determines if a command can be input.
	#
	# @return whether a command can be input.
	# bool IsInputable()

	# Determines if everyone is dead.
	#
	# @return whether all are dead.
	# bool AreAllDdead()

	# Checks slip damage.
	# void CheckMapSlipDamage()

	# Random selection of target actor.
	#
	# @//param hp0 : only targets actors with 0 HP.
	# @//return target actor.
	# Game_Actor* RandomTargetActor(bool hp0 = false)

	# Smooth selection of target actor.
	#
	# @//param actor_index : actor index in party.
	# @//return target actor.
	# Game_Actor* SmoothTargetActor(int actor_index)

	# Gets gold possessed.
	#
	# @return gold possessed.
	def gold; @data.gold; end

	# Gets steps walked.
	#
	# @return steps walked.
  def steps; @data.steps; end

	# Gets actors in party list.
	#
	# @return actors in party list.
  def actors; @data.party.map { |v| Game_Actors.actor v }; end

	# Gets number of battles.
	#
	# @return number of battles.
  def battle_count; @data.battles; end

	# Gets number of battles wins.
	#
	# @return number of battles wins.
  def win_count; @data.victories; end

	# Gets number of battles defeats.
	#
	# @return number of battles defeats.
  def defeat_count; @data.defeats; end

	# Gets number of battles escapes.
	#
	# @return number of battles escapes.
  def run_count; @data.escapes end

  Timer1 = 0
  Timer2 = 1

  def set_timer(which, seconds)
    case which
    when Timer1; @data.timer1_secs = seconds * DEFAULT_FPS
    when Timer2; @data.timer2_secs = seconds * DEFAULT_FPS
    end
    Game_Map.need_refresh = true
  end

  def stop_timer(which)
    case which
    when Timer1
      @data.timer1_active = false
      @data.timer1_visible = false
    when Timer2
      @data.timer2_active = false
      @data.timer2_visible = false
    end
  end

  def start_timer(which, visible, battle)
    case which
    when Timer1
      @data.timer1_active = true
      @data.timer1_visible = visible
      @data.timer1_battle = battle
    when Timer2
      @data.timer2_active = true
      @data.timer2_visible = visible
      @data.timer2_battle = battle
    end
  end

  def update_timers
    battle = !Game_Battle.scene.nil?
    if (@data.timer1_active && (!@data.timer1_battle || !battle) && @data.timer1_secs > 0)
      @data.timer1_secs -= 1
      Game_Map.need_refresh = true
    end
    if (@data.timer2_active && (!@data.timer2_battle || !battle) && @data.timer2_secs > 0)
      @data.timer2_secs -= 1
      Game_Map.need_refresh = true
    end
  end

	def read_timer(which)
    case which
    when Timer1; return @data.timer1_secs
    when Timer2; return @data.timer2_secs
    end
  end
end
