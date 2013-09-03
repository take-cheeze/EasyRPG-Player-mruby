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

class Game_Battler
end

class Game_Actor < Game_Battler
  # Constructor.
  #
  # @param actor_id database actor ID.
  def initialize(actor_id)
    @actor_id = actor_id
    @data = Data.game_data.actors[actor_id]
    @data.setup actor_id

    make_exp_list
  end

  def max_exp
    Player.rpg2k3? ? 9999999 : 999999
  end

  # Calculates the Experience curve for every level.
  def make_exp_list
    @exp_list = Array.new max_level, 0

    src = data.changed_class ? Data.classes[class_id] : Data.actors[data.index]
    base = src.exp_base
    inflation = src.exp_inflation
    correction = src.exp_correction

    if Player.rpg2k?
      inflation = 1.5 + inflation * 0.01
    end

    current_exp = 0
    for i in 0...@exp_list.length
      if Player.rpg2k?
        current_exp += (correction + base).floor
        base = base * inflation
        inflation = ((i + 1) * 0.002 + 0.8) * (inflation - 1) + 1
      elsif Player.rpg2k3?
        current_exp += base + i * inflation + correction
      end

      current_exp = [current_exp, max_exp].min
      @exp_list = current_exp
    end
  end

  # Initializes the game actor to the database state.
  # Sets the skills, HP, SP and experience.
  # If save_data is passed it overwrites the values with it.
  def load(save_data)
    Data.actors[data.index].skills.each do |v|
      if (v.level <= level())
        learn_skill(v.skill_id)
      end
      hp = max_hp
      sp = max_sp
      exp = exp_list[level - 1]
    end
  end

  # Learns a new skill.
  #
  # @param skill_id database skill ID.
  # @return If skill was learned (fails if already had the skill)
  def learn_skill(skill_id)
    if skill_id > 0 and not skill_learned?(skill_id)
      data.skills.push skill_id
      data.skills.sort
      true
    else
      false
    end
  end

  # Unlearns a skill.
  #
  # @param skill_id database skill ID.
  # @return If skill was unlearned (fails if didn't had the skill)
  def forget_skill(skill_id)
    idx = data.skills.find_index skill_id
    data.skills[idx] = nil if not idx.nil?
    not idx.nil?
  end

  # Checks if the actor has the skill learned.
  #
  # @param skill_id ID of skill to check.
  # @return true if skill has been learned.
  def skill_learned?(skill_id)
    not data.find_index(skill_id).nil?
  end

  # Checks if the actor can use the skill.
  #
  # @param skill_id ID of skill to check.
  # @return true if skill can be used.
  def skill_usable?(skill_id)
    skill_learned?(skill_id) and Game_Battler.skill_usable?(skill_id)
  end

  # Gets the actor ID.
  #
  # @return Actor ID
  def id
    data.index
  end

  # Calculates the Exp needed for a level up.
  #
  # @param level level to calculate exp for.
  # @return Needed experience.
  def calculate_exp(level)
  end

  # Converts the currect Exp to a string.
  #
  # @return Exp-String or ------ if Level is max.
  def exp_string
    exp.to_s
  end

  # Converts the Exp for the next LV to a string.
  #
  # @return Exp-String or ------ if Level is max.
  def next_exp_string
    begin next_exp.to_s
    rescue "------"
    end
  end

  # Returns how many Exp are minimum for a level.
  #
  # @param level to return base Exp for.
  # @return Exp needed
  def base_exp(lv = nil)
    next_exp((lv.nil? ? level : lv) - 1)
  end

  # Returns how many Exp are needed for a level up based on the current
  # level.
  #
  # @param level to return NextExp for.
  # @return Exp needed
  def next_exp(lv = nil)
    lv.nil? ? next_exp(level) : @exp_list[lv]
  end

  # Gets actor name.
  #
  # @return name.
  def name; data.name end

  # Gets actor character graphic filename.
  #
  # @return character graphic filename.
  def charset; data.charset end

  # Gets actor character graphic index.
  #
  # @return character graphic index.
  def charset_index; data.charset_index end

  # Gets actor face graphic filename.
  #
  # @return face graphic filename.
  def faceset; data.faceset end

  # Gets actor face graphic index.
  #
  # @return face graphic index.
  def faceset_index; data.faceset_index end

  # Gets actor title.
  #
  # @return title.
  def title; data.title end

  # Gets actor current level.
  #
  # @return current level.
  def level; data.level end

  # Gets final level of current actor.
  #
  # @return final level
  def max_level
    Data.actors[data.index].final_level
  end

  # Gets actor current experience points.
  #
  # @return current experience points.
  def exp; data.exp; end

  # Sets exp of actor.
  # The value is adjusted to the boundary 0 up 999999.
  # Other actor attributes are not altered. Use ChangeExp to do a proper
  # experience change.
  #
  # @param _exp exp to set.
  def exp=(v)
    data.exp = [0, [v, max_exp].min].max
  end

  # Changes exp of actor and handles level changing based on the new
  # experience.
  #
  # @param exp new exp.
  # @param level_up_message Whether to show level up message and learned skills.
  def change_exp(exp, level_up_message)
    new_level = level
    new_exp = [0, [exp, max_exp].min].max

    if new_exp > exp
      for i in (level + 1)...max_level
        break if next_exp(new_level) > new_exp
        new_level += 1
      end
    elsif new_exp < exp
      i = level - 1
      while i >= 1
        break if new_exp > next_exp(i)
        new_level--
          i -= 1
      end
    end

    exp = new_exp

    if new_level != data.level
      change_level new_level, level_up_message
    end
  end

  # Changes level of actor and handles experience changes, skill
  # learning and other attributes based on the new level.
  #
  # @param level new level.
  # @param level_up_message Whether to show level up message and learned skills.
  def change_level(lv, level_up_message)
    level_up = false

    old_level = level
    level = new_level
    new_level = level # Level adjusted to max

    if new_level > old_level
      if level_up_message
        Game_Message::texts.push("%s %s%d%s" % [name, Data.tems.level, new_level, Data.terms.level_up])
        level_up = true
      end

      # Learn new skills
      Data.actors[data.index].skills.each do |v|
        # Skill learning, up to current level
        if learn_skill(v.skill_id) and level_up_message
          Game_Message::texts.push("%s%s" % [Data.skills[v.skill_id].name, Data.terms.skill_learned])
          level_up = true
        end
      end
    end

    if level_up
      Game_Message.texts.last += "\f"
      Game_Message.message_waiting = true

      # Experience adjustment:
      # At least level minimum
      exp = [base_exp, exp].max
    elsif new_level < old_level
      # Set HP and SP to maximum possible value
      hp = hp
      sp = sp

      # Experience adjustment:
      # Level minimum if higher then Level maximum
      if exp >= next_exp
        exp = base_exp
      end
    end
  end

  # Sets level of actor.
  # The value is adjusted to the boundary 1 up to max level.
  # Other actor attributes are not altered. Use ChangeLevel to do a proper
  # level change.
  #
  # @param _level level to set.
  def level=(v)
    data.level = [1, [v, max_level].min].max
  end

  # Checks if the actor can equip the item.
  #
  # @param item_id ID of item to check.
  # @return true if it can equip the item.
  def equippable?(item_id)
    if double_hand? and Data.item[item_id].type == RPG::Item::Type_shield
      false
      # If the actor ID is out of range this is an optimization in the ldb file
      # (all actors missing can equip the item)
    elsif Data.items[item_id].actor_set.length <= (data.index - 1)
      true
    else
      Data.items[item_id].actor_set[data.index - 1]
    end
  end

  # Sets face graphic of actor.
  # @param file_name file containing new face.
  # @param index index of face graphic in the file.
  def set_face(file_name, index)
    data.face_name = file_name
    data.face_id = index
  end

  # Gets the equipped equipment based on the type.
  # @param equip_type type of equipment.
  # @return item_id or 0 if no equipment or -1 if invalid.
  def equipment(equip_type)
    raise "invalid equip type" unless (0 <= equip_type and equip_type < data.equipped.length)
    return data.equipped[equip_type]
  end

  # Sets the equipment based on the type.
  #
  # @param equip_type type of equipment.
  # @param new_item_id item to equip.
  # @return item_id of old item, or 0
  def set_equipment(equip_type, new_item_id)
    raise "invalid equip type" unless (0 <= equip_type and equip_type < data.equipped.length)

    old_item_id = data.equipped[equip_type]
    data.equipped[equip_type] = new_item_id
    old_item_id
  end

  # Changes the equipment of the actor.
  # Removes one instance of that item from the Inventory.
  # and adds the old one of the actor to it.
  # If you don't want this use SetEquipment instead.
  #
  # @param equip_type type of equipment.
  # @param item_id item to equip.
  def ChangeEquipment(equip_type, item_id)
    prev_item = set_equipment(equip_type, item_id)

    Game_Party.gain_item(prev_item, 1) if prev_item != 0
    Game_Party.lose_item(item_id, 1) if item_id != 0
  end

  # Gets learned skills list.
  #
  # @return learned skills list.
  def skills; data.skills end

  # Gets actor states list.
  #
  # @return vector containing the IDs of all states the actor has.
  def states; data.states end

  def hp; data.current_hp; end
  def hp=(p)
    data.current_hp = [0, [p, max_hp].min].max
  end

  def sp; data.current_sp; end
  def sp=(p)
    data.current_sp = [0, [p, max_sp].min].max
  end

  # Gets the max HP for the current level.
  #
  # @param mod include the modifier bonus.
  def base_max_hp
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.maxhp[level - 1]
    [1, [r + data.hp_mod, 999].min].max
  end

  # Gets the max SP for the current level.
  #
  # @param mod include the modifier bonus.
  def base_max_sp
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.maxsp[level - 1]
    [1, [r + data.sp_mod, 999].min].max
  end

  # Gets the attack for the current level.
  def base_attack
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.attack[level - 1]
    data.equiped.each { |v| r += Data.items[v].attack }
    [1, [r + data.attack_mod, 999].min].max
  end

  # Gets the defense for the current level.
  def base_defense
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.defense[level - 1]
    data.equiped.each { |v| r += Data.items[v].defense }
    [1, [r + data.defense_mod, 999].min].max
  end

  # Gets the spirit for the current level.
  def base_spirit
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.spirit[level - 1]
    data.equiped.each { |v| r += Data.items[v].spirit }
    [1, [r + data.spirit_mod, 999].min].max
  end

  # Gets the agility for the current level.
  def base_agility
    r = (data.changed_class ? Data.classes[class_id] : Data.actors[data.index]).parameters.agility[level - 1]
    data.equiped.each { |v| r += Data.items[v].agility }
    [1, [r + data.agility_mod, 999].min].max
  end

  # Sets the base max HP by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _maxhp max HP.
  def max_hp=(v)
    data.hp_mod += v - max_hp
    hp = hp
  end

  # Sets the base max SP by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _maxsp max SP.
  def max_sp=(v)
    data.sp_mod += v - max_sp
    sp = sp
  end

  # Sets the base attack by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _atk attack.
  def attack=(v) data.attack_mod += v - attack end

  # Sets the base defense by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _def defense.
  def defense=(v) data.defense_mod += v - defense end

  # Sets the base spirit by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _spi spirit.
  def spirit=(v) data.spirit_mod += v - spirit end

  # Sets the base agility by adjusting the modifier bonus.
  # The existing modifier bonus and equipment bonuses
  # are taken into account.
  #
  # @param _agi agility.
  def agility=(v) data.agility_mod += v - agility end

  # Gets if actor has two weapons.
  #
  # @return true if actor has two weapons.
  def double_hand?; data.two_weapon end

  # Sets new actor name.
  #
  # @param new_name new name.
  def name=(n) data.name = n end

  # Sets new actor title.
  #
  # @param new_title new title.
  def title=(t) data.title = t end

  # Sets actor sprite.
  #
  # @param file graphic file.
  # @param index graphic index.
  # @param transparent transparent flag.
  def set_charset(file, index, transparent)
    data.charset = file
    data.charset_index = index
    data.charset_flags = transparent ? 3 : 0
  end

  # Changes battle commands.
  #
  # @param add true => add the command, false => remove the command.
  # @param id command to add/remove, 0 to remove all commands.
  def change_battle_commands(add, id)
    if add
      if not data.battle_commands.find_index(id).nil?
        data.battle_commands.push id
        data.battle_commands.sort
      end
    elsif id == 0; data.battle_commands = []
    else
      idx = data.battle_commands.find_index id
      data.battle_commands.delete idx if not idx.nil?
    end
  end

  # Gets Rpg2k3 hero class.
  #
  # @return Rpg2k3 hero class.
  def class_id; data.class_id end

  # Sets new Rpg2k3 hero class.
  #
  # @param class_id mew Rpg2k3 hero class.
  def class_id=(v)
    data.class_id = v
    make_exp_list
  end

  # Gets the actor's class name as a string.
  #
  # @return Rpg2k3 hero class name
  def class_name
    class_id == 0 ? "" : Data.classes[class_id].name
  end

  # Gets battle commands.
  #
  # @return all Rpg2k3 battle commands.
  def battle_commands; data.battle_commands end

  # Gets battle row for Rpg2k3 battles.
  #
  # @return row for Rpg2k3 battles (-1 front, 1 back).
  def battle_row; data.row end

  # Sets battle row for Rpg2k3 battles.
  #
  # @param battle_row new row for Rpg2k3 battles (-1 front, 1 back).
  def battle_row=(v) data.row = v end
end
