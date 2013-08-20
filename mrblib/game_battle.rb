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

module Game_Battle
  attr_reader :scene
  attr_writer(:target_ally, :active_ally, :target_enemy, :active_enemy, :background,
              :item, :skill, :morph)

  def active_ally; @allies[@active_ally]; end
  def has_active_ally; not @active_ally.nil?; end
  def target_active_ally; @target_ally = @active_ally; end
  def target_random_ally
    @target_ally = rand.abs % @allies.length
  end

  def enemy(i); @enemies[i]; end
  def target_enemy; @enemies[@target_enemy]; end
  def has_target_enemy; not @target_enemy.nil?; end
  def clear_target_enemy; @target_enemy = nil; end
  def target_next_enemy
    @target_enemy += 1
    @target_enemy = @target_enemy % @enemies.length
  end
  def target_prev_enemy
    @target_enemy -= 1
    @target_enemy += @enemies.length
    @target_enemy = @target_enemy % @enemies.length
  end
  def active_enemy; @enemies[@active_enemy]; end
  def target_random_enemy
    @target_enemy = rand.abs % @enemies.length
  end

  def defend; active_ally.defending = true; end
  def attack
    attack_enemy active_ally, target_enemy
    active_ally.defending = false
  end
  def use_item
    use_item active_ally, Data.items[@item_id]
    active_ally.defending = false
  end
  def use_skill
    use_skill active_ally, Data.skills[@skill_id]
    active_ally.defending = false
  end

  def enemy_attack(target)
    enemy_attack_ally active_enemy, target
  end
  def enemy_defend
    msg = Data.terms.defending.empty? ? " is defending" : Data.terms.defending
    scene.message(active_enemy.rpg_enemy.name + msg)
    active_enemy.defending = true
  end
  def enemy_observe
    msg = Data.terms.observing.empty? ? " is observing" : Data.terms.observing
    scene.message(active_enemy.rpg_enemy.name + msg)
  end
  def enemy_charge
    msg = Data.terms.focus.empty? ? " is charging" : Data.terms.focus
    scene.message(active_enemy.rpg_enemy.name + msg)
    active_enemy.charged = true
  end
  def enemy_destruct
    msg = Data.terms.autodestruction.empty? ? "self-destruct" : Data.terms.autodestruction
    scene.message msg
    enemy.charged = true
    @allies.each { |v| enemy_attack v }
    enemy.game_enemy.hp = 0
  end
  def enemy_skill
    enemy_skill active_enemy, Data.skills[@skill_id]
  end
  def enemy_transform
    active_enemy.transform @morph_id
  end
  def enemy_action_done
    Game_Switches[@enemy_action.switch_on_id] = true if @enemy_action.switch_on
    Game_Switches[@enemy_action.switch_off_id] = false if @enemy_action.switch_off
  end

  def escape
    if Game_Temp.battle_escape_mode != 0
      # FIXME: escape probability
      Game_Temp.battle_result = Game_Temp::BattleEscape
      true
    else
      false
    end
  end

  def restart
    @scene.restart
    active_ally.next_turn
    clear_target_ally
    clear_target_enemy
  end

  def check_turns(turns, base, multiple)
    turns >= base and (turns - base) % multiple == 0
  end

  def check_events
    ret = @troop.pages.find { |v| check_condition v.condition }
    @interpreter.setup ret.event_commands, 0 if not ret.nil? and ret != @script_page
  end

  def check_condition(cond)
    return false if
      (cond.flags.switch_a && !Game_Switches[cond.switch_a_id]) or
      (cond.flags.switch_b && !Game_Switches[cond.switch_b_id]) or
      (cond.flags.variable && !(Game_Variables[cond.variable_id] >= cond.variable_value)) or
      (cond.flags.turn && !check_turns(turns, cond.turn_b, cond.turn_a)) or
      (cond.flags.turn_enemy && !check_turns(GetEnemy(cond.turn_enemy_id).turns(),
                                             cond.turn_enemy_b, cond.turn_enemy_a))

    if cond.flags.turn_actor
      ally = find_ally cond.turn_actor_id
      return false if !ally or !CheckTurns(ally.turns(), cond.turn_actor_b, cond.turn_actor_a)
    end

    if (cond.flags.enemy_hp)
      hp = enemy(cond.enemy_id).actor.hp
      return false if (hp < cond.enemy_hp_min || hp > cond.enemy_hp_max)
    end

    if cond.flags.actor_hp
      ally = find_ally cond.actor_id
      return false if !ally
      hp = ally.actor.hp
      return false if (hp < cond.actor_hp_min || hp > cond.actor_hp_max)
    end

    if cond.flags.command_actor
      ally = find_ally cond.actor_id
      return false if !ally or ally.last_command != cond.command_id
    end

    true
  end

  def enemy_skill(enemy, skill)
    sp = enemy.game_enemy.calculate_skill_cost skill.index
    return if sp > enemy.game_enemy.sp # not enough SP

    case skill.type
		when RPG::Skill::Type_teleport
			# FIXME: can monsters teleport?
			Game_Battle::EnemyEscape()
		when RPG::Skill::Type_escape
			Game_Battle::EnemyEscape()
		when RPG::Skill::Type_switch
			return if not skill.occasion_battle
			Game_Switches[skill.switch_id] = true
    else
			case skill.scope
      when RPG::Skill::Scope_enemy
        UseSkillAlly(enemy, skill, Game_Battle::GetTargetAlly())
        return
      when RPG::Skill::Scope_enemies
        @allies.each { |v| use_skill_ally enemy, skill, v }
      when RPG::Skill::Scope_self
        UseSkillEnemy(enemy, skill, enemy)
      when RPG::Skill::Scope_ally
        UseSkillEnemy(enemy, skill, Game_Battle::GetTargetEnemy())
        return
      when RPG::Skill::Scope_party
        @enemies.each { |v| use_skill_enemy enemy, skill, v }
      end
    end

    Game_System.se_play skill.sound_effect if skill.type != RPG::Skill::Type_normal

    enemy.game_enemy.sp = enemy.game_enemy.sp - sp
  end

  def enemy_escape
    e = active_enemy
    e.fade = 30
    e.escaped = true
  end

  def monster_flee(id = nil)
    if id.nil?
      @enemies.each_index { |i| monster_flee i }
    else
      active_enemy = id
      enemy_escape if active_enemy.game_enemy.exists?
    end
  end

  def next_active_enemy
    ret = @enemies.find { |v| v.ready }
    if ret.nil?; false
    else
      @active_enemy = ret.id
      ret.gauge = 0
      true
    end
  end

  def update
    @turn_fragments += 1

    (@allies + @enemies).each { |v|
			# FIXME: this should account for agility, paralysis, etc
      v.gauge += v.speed if v.gauge < Battle::Battler::gauge_full
    }
  end

  def has_corpse
    not @allies.find { |v| v.actor.dead? }.nil?
  end
  def check_win
    @enemies.find { |v| not v.game_enemy.dead? }.nil?
  end
  def check_lose
    @allies.find { |v| not v.actor.dead? }.nil?
  end

  def terminate; @terminate = true; end

  def active_actor
    (has_active_ally ? active_ally : ally(0)).game_actor.id
  end

  def turns; @turn_fragments / @turn_length; end

  def choose_enemy
    @target_enemy = 0 if @target_enemy.nil?
    return if target_enemy.game_enemy.exists?

    for i in 1...@enemies.length
      target_next_enemy
      break if target_enemy.game_enemy.exists?
    end

    clear_target_enemy if not target_enemy.game_enemy.exists
  end

  def attack_enemy(ally, enemy)
    weapon = Data.items[ally.game_actor.weapon]
    to_hit = 100 - (100 - weapon.hit) * (1 + (1.0 * enemy.agility / ally.agility - 1) / 2)

    if rand.abs % 100 < to_hit
      effect = 0, ally.attack / 2 - enemy.defence / 4
      effect += effect * (rand.abs % 40 - 20) / 100
      effect = [0, effect].max

      enemy.game_enemy.hp = enemy.game_enemy.hp - effect
      scene.floater enemy.sprite, Font::ColorDefault, effect, 60
    else
      scene.floater enemy.sprite, Font::ColorDefault, Data.terms.miss, 60
    end
  end

  def use_item(ally, item)
    return if item.type != RPG::Item::Type_medicine or item.occasion_field2

    (item.entire_party ? @allies : [target_ally]).each { |v| use_item_ally item, v }

    case item.uses
    when 0 # unlimited uses
    when 1 # single use
      Game_Party.lose_item item.index, 1
    else
			# multiple use
			# FIXME: we need a Game_Item type to hold the usage count
    end
  end

  def use_skill(ally, skill)
    sp = ally.actor.calculate_skill_cost skill.index
    return if sp > ally.actor.sp

    case skill.type
		when RPG::Skill::Type_teleport
			# FIXME: teleport skill
		when RPG::Skill::Type_escape
			escape
		when RPG::Skill::Type_switch
			return if not skill.occasion_battle
			Game_Switches[skill.switch_id] = true
		else
			case skill.scope
      when RPG::Skill::Scope_enemy
        UseSkillEnemy(ally, skill, Game_Battle::GetTargetEnemy())
        return
      when RPG::Skill::Scope_enemies
        @enemies.each { |v| use_skill_enemy ally, skill, v }
      when RPG::Skill::Scope_self
        use_skill_ally ally, skill, ally
      when RPG::Skill::Scope_ally
        use_skill_ally ally, skill, target_ally
      when RPG::Skill::Scope_party
        @allies.each { |v| use_skill_ally ally, skill, v }
      end
    end

    Game_System.se_play skill.sound_effect if skill.type != RPG::Skill::Type_normal
    ally.actor.sp = ally.actor.sp - sp
  end

  def use_skill_ally(user, skill, target)
    actor = target.actor
    miss = true

    if skill.power > 0 and rand % 100 < skill.hit
			miss = false

			# FIXME: is this still affected by stats for allies?
			effect = skill.power
			if skill.variance > 0
				var_perc = skill.variance * 5
				change = effect * (rand % (var_perc * 2) - var_perc) / 100
				effect += change
			end
      effect = [0, effect].max

      actor.hp = actor.hp + effect if skill.affect_hp
      actor.sp = actor.sp + effect if skill.affect_sp
      target.modify_attack(effect) if skill.affect_attack
      target.modify_defence(effect) if skill.affect_defense
      target.modify_spirit(effect) if skill.affect_spirit
      target.modify_agility(effect) if skill.affect_agility

      scene.floater target.sprite, 9, effect, 60 if skill.affect_hp || skill.affect_sp
    end

    skill.state_effect.each_with_index { |v,i|
      if v and rand % 100 < skill.hit
        miss = false
        skill.state_effect ? actor.add_state(i + 1) : actor.remove_state(i + 1)
      end
    }

    scene.floater target.sprite, Font::ColorDefault, Data.terms.miss, 60 if miss
  end

  def use_skill_enemy(user, skill, target)
    actor = target.actor
    miss = true

    if skill.power > 0 and rand() % 100 < skill.hit
			miss = false

			# FIXME: This is what the help file says, but it doesn't look right
			effect = skill.power +
        user.attack * skill.pdef_f / 20 +
        actor.defence * skill.mdef_f / 40
			if skill.variance > 0
				var_perc = skill.variance * 5
				change = effect * (rand % (var_perc * 2) - var_perc) / 100
				effect += change
			end
      effect = [0, effect].max

      target.hp = actor.hp - effect if skill.affect_hp
      target.sp = actor.sp - effect if skill.affect_sp
      target.modify_attack(-effect) if skill.affect_attack
      target.modify_defence(-effect) if skill.affect_defense
      target.modify_spirit(-effect) if skill.affect_spirit
      target.modify_agility(-effect) if skill.affect_agility

      scene.floater target.sprite, Font::ColorDefault, effect, 60 if  skill.affect_hp || skill.affect_sp
    end

    skill.state_effect.each_with_index { |v,i|
      if v and rand % 100 < skill.hit
        miss = false
        skill.state_effect ? target.add_state(i + 1) : target.remove_state(i + 1)
      end
    }

		scene.floater target.sprite, Font::ColorDefault, Data.terms.miss, 60 if miss
  end

  def enemy_action_valid(action, enemy)
    case action.condition_type
    when RPG::EnemyAction::ConditionType_always
      return true
    when RPG::EnemyAction::ConditionType_switch
      return Game_Switches[action.switch_id]
    when RPG::EnemyAction::ConditionType_turn
      interval = action.condition_param2 == 0 ? 1 : action.condition_param2
      return (turns - action.condition_param1) % interval == 0
    when RPG::EnemyAction::ConditionType_actors
      count = @enemies.count { |v| v.game_enemy.exists }
      return count >= action.condition_param1 && count <= action.condition_param2
    when RPG::EnemyAction::ConditionType_hp
      hp_percent = enemy.game_enemy.hp * 100 / enemy.game_enemy.max_hp
      return hp_percent >= action.condition_param1 && hp_percent <= action.condition_param2
    when RPG::EnemyAction::ConditionType_sp
      sp_percent = enemy.game_enemy.sp * 100 / enemy.game_enemy.max_sp
      return sp_percent >= action.condition_param1 && sp_percent <= action.condition_param2
    when RPG::EnemyAction::ConditionType_party_lvl
      party_lvl = @allies.inject { |sum,v| sum + v.game_actor.level } / @allies.length
      return party_lvl >= action.condition_param1 && party_lvl <= action.condition_param2
    when RPG::EnemyAction::ConditionType_party_fatigue
      party_exh = @allies.inject { |sum,v|
        sum + 100 - (200 * v.actor.hp / v.actor.hp -
                     100 * v.actor.sp / v.actor.sp / 3)
      } / @allies.length
      return party_exh >= action.condition_param1 && party_exh <= action.condition_param2
    else
      return true
    end
  end

  def choose_enemy_action(enemy)
    actions = enemy.rpg_enemy.actions
    valid = []

    total = 0
    actions.each_with_index do |v,i|
      if enemy_action_valid v, enemy
        valid << i
        total += v.rating
      end
    end

    enemy_action = nil
    which = rand % total
    valid.each do |v|
      action = actions[v]
      which >= action.rating ? which -= action.rating : enemy_action = action
    end
    enemy_action
  end

  def enemy_attack_ally(enemy, ally)
    return if ally.actor.dead?

    hit = enemy.rpg_enemy.miss ? 70 : 90
    to_hit = 100 - (100 - hit) * (1 + (1.0 * ally.agility / enemy.agility - 1) / 2)

    if rand % 100 < to_hit
      effect = enemy.attack() / 2 - ally.defence() / 4
      effect += effect * ((rand() % 40) - 20) / 100

      ally.actor.hp = ally.actor.hp - effect
      scene.floater ally.sprite, Font::ColorDefault, effect, 60
    else
      scene.floater ally.sprite, Font::ColorDefault, Data.terms.miss, 60
    end
  end

  def use_item_ally(ally, item, target)
    actor = target.actor
    return if item.ko_only and not actor.dead?

    # HP
    hp_effect = item.recover_hp_rate * actor.max_hp / 100 + item.recover_hp
    actor.hp = actor.hp + hp_effect
    # SP
    sp_effect = item.recover_sp_rate * actor.max_sp / 100 + item.recover_sp
    actor.sp = actor.sp + sp_effect

    scene.floater target.sprite, 9, sp_effect, 60 if sp_effect > 0
    scene.floater target.sprite, 9, hp_effect, 60 if hp_effect > 0

    item.state_set.each_with_index { |v,i| actor.remove_state i + 1 if v }
  end

	gauge_full = Battle::Battler::gauge_full
	turn_length = 333 # frames

	def init(s)
    @scene = s

    @troop = Data.troops[Game_Temp.battle_troop_id ]

    gauge = Game_Temp.battle_first_strike ? Battle::Battler::gauge_full : 0

    @allies = []
    Game_Party.actors.each_with_index do |v,i|
      @allies.push Battle::Ally.new(v, i)
      @allies.back.create_sprite
      @allies.back.gauge = gauge
    end

    @enemies = []
    @troop.members.each_with_index do |v,i|
      @enemies.push Battle::Ally.new(v, i)
      @enemies.back.create_sprite
    end

    @background_name = Game_Temp.battle_background

    @active_enemy = nil
    @active_ally = nil
    @target_enemy = nil
    @target_ally = nil
    @terminate = false
    @allies_flee = false
    @item_id = nil
    @skill_id = nil
    @morph_id = nil

    @script_page = nil

    @interpreter = Game_Interpreter_Battle.new
  end

	def quit
    # Remove conditions which end after battle
    @allies.each { |v| v.actor.remove_states }

    @allies = []
    @enemies = []

    interpreter = nil

    scene = nil
  end

  def ally(i); @allies[i]; end

  def target_ally; @allies[@target_ally];  end
  def clear_target_ally; @target_ally = nil; end
  def has_target_ally; not @target_ally.nil?; end
  def target_next_ally
    @target_ally += 1
    @target_ally = @target_ally % @allies.length
  end
  def target_prev_ally
    @target_ally -= 1
    @target_ally += @allies.length
    @target_ally = @target_ally % @allies.length
  end

  def find_ally(id)
    @allies.find { |v| v.rpg_actor.index == id }
  end

  def allies_centroid
    x = 0, y = 0
    @allies.each do |v|
      x += v.rpg_actor.battle_x
      y += v.rpg_actor.battle_y
    end
    [x, y].map { |v| v / @allies.length }
  end

  def enemies_centroid
    x = 0, y = 0
    @enemies.each do |v|
      x += v.member.x
      y += v.member.y
    end
    [x, y].map { |v| v / @enemies.length }
  end
end
