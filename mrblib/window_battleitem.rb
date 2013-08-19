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

# Window BattleItem class.
# Displays all items of the party for use in battle.
class Window_BattleItem < Window_Item
	# Constructor.
  def initialize(x, y, w, h)
    super x, y, w, h
    @actor_id = 0
  end

  attr_writer :index

	# Checks if item should be enabled.
	#
	# @param item_id item to check.
	def check_enable(item_id)
    item = Data.items[item_id]

    case item.type
    when RPG::Item::Type_normal; return false
    when RPG::Item::Type_weapon, RPG::Item::Type_shield, RPG::Item::Type_armor, RPG::Item::Type_helmet, RPG::Item::Type_accessory
      return item.use_skill && can_use_item?(item) && can_use_skill?(item.skill_id)
    when RPG::Item::Type_medicine
			return can_use_item?(item) && !item.occasion_field1 && (!item.ko_only || Game_Battle.have_corpse)
		when RPG::Item::Type_book, RPG::Item::Type_material; return false
		when RPG::Item::Type_special; return can_use_item?(item) && can_use_skill?(item.skill_id)
		when RPG::Item::Type_switch; return item.occasion_battle
    else; return false
    end
  end

	def can_use_item?(item)
    return false if @actor_id <= 0
    return true if actor_id >= item.actor_set.length || item.actor_set[@actor_id]
    return false if Player.rpg2k?
    actor = Data.actors[@actor_id]
    return false if actor.class_id < 0
    return true if actor.class_id >= item.class_set.length || item.class_set[actor.class_id]
    false
  end

	def can_use_skill?(skill_id)
    skill = Data.skills[skill_id]
    skill.type != RPG::Skill::Type_switch or skill.occasion_battle
  end
end
