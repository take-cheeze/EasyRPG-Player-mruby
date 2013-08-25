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

# Scene_Battle class.
# Manages the battles.
class Scene_Battle < Scene
  def initialize
    super 'Battle'
    @floaters = []
    @animations = []
    @actions = []
  end

  def dispose; Game_Battle.quit; end

  def start
    if Player.battle_test_flag
      if Player.battle_test_troop_id.nil?
        Output.error 'Invalid Monster Party ID'
      else
        Game_Temp.battle_troop_id = Player.battle_test_troop_id
        # TODO: Rpg2k does specify a background graphic instead
        Game_Temp.battle_terrain_id = 1
      end
    end

    Game_Battle.init self

    @cycle = 0
    @auto_battle = false
    @enemy_action = nil

    # CreateCursors
    create_windows

    @help_window.text = 'Battle System not implemented yet. Select result.'

    @animation = nil
    @animations = []

    unless Game_Temp.battle_background.empty?
      @background = Background.new Game_Temp.battle_background
    else; @background = Background.new Game_Temp.battle_terrain_id
    end

    self.state = State_Options
  end

  def update
    @background.update unless @background.nil?
  end

  def message(msg, pause = true)
    @help_window.text = msg
    @help_window.visible = true
    @help_window.pause = pause
    @message_timer = 60 unless pause
  end

  State_Options = 0
  State_Battle = 1
  State_AutoBattle = 2
  State_Command = 3
  State_Item = 4
  State_Skill = 5
  State_TargetEnemy = 6
  State_TargetAlly = 7
  State_AllyAction = 8
  State_EnemyAction = 9
  State_Victory = 10
  State_Defeat = 11

	class FloatText
		def initialize(x, y, color, text, duration)
      rect = Font.default.size(text)
      graphic = Bitmap.new rect.width, rect.height
      graphic.draw_text_2k(-rect.x, -rect.y, text, color)

      @sprite = Sprite.new
      @sprite.bitmap = graphic
      @sprite.ox, @sprite.oy = rect.width / 2, rect.height + 5
      @sprite.x, @sprite.y, @sprite.z = x, y, 500 + y

      @duration = duration
    end

    attr_accessor :duration, :sprite
	end

	def create_cursors
    system2 = Cache.system2 Data.system.system2_name

    @ally_cursor = Sprite.new
    @ally_cursor.bitmap = system2
    @ally_cursor.src_rect = Rect.new 0, 16, 16, 16
    @ally_cursor.z = 999
    @ally_cursor.visible = false

    @enemy_cursor = Sprite.new
    @enemy_cursor.bitmap system2
    @enemy_cursor.src_rect = Rect.new 0, 0, 16, 16
    @enemy_cursor.z = 999
    @enemy_cursor.visible = false
  end

  def create_windows
    @help_window = Window_Help.new 0, 0, 320, 32
    @help_window.visible = false

    @options_window = Window_BattleOption.new 0, 172, 76, 68
    @status_window = Window_BattleStatus.new
    @command_window = Window_BattleCommand.new 244, 172, 76, 68

    @skill_window = Window_BattleSkill.new 0, 172, 320, 68
    @skill_window.visible = false

    @item_window = Window_BattleItem.new 0, 172, 320, 68
    @item_window.visible = false
    @item_window.refresh
    @item_window.index = 0
  end

  def floater(ref, color, v, duration)
    @floaters.push FloatText.new(ref.x, ref.y, color, v.to_s, duration)
  end

	def show_animation(animation_id, allies, ally, enemy, wait)
    rpg_anim = Data.animations[animation_id]
    if not ally.nil?; x, y = ally.sprite.x, ally.sprite.y
    elsif not enemy.nil?; x, y = enemy.sprite.x, enemy.sprite.y
    elsif allies; x, y = Game_Battle.allies_centroid
    else x, y = Game_Battle.enemies_centroid
    end

    new_animation = BattleAnimation.new x, y, rpg_anim
    if wait; @animation = new_animation
    else @animations.push new_animation
    end
  end

	def update_animations
    if not @animation.nil?
      @animation.update
      @animation = nil if @animation.done?
    end

    @animations.map! { |v|
      return nil if v.nil?
      v.update
      v.done? ? nil : v
    }.compact!
  end

  def animation_waiting?; not @animation.nil?; end

  def state=(s)
    @target_state = @state
    @state = s
    @state = State_AutoBattle if @state == State_Battle && @auto_battle

    @options_window.active = false
    @status_window.active = false
    @command_window.active = false
    @item_window.active = false
    @skill_window.active = false

    case @state
		when State_Options
			@options_window.active = true
		when State_Battle
			@status_window.active = true
		when State_AutoBattle
		when State_Command
			@command_window.active = true
			@command_window.actor = Game_Battle.active_actor
		when State_TargetEnemy
		when State_TargetAlly
			@status_window.active = true
		when State_Item
			@item_window.active = true
			@item_window.actor = Game_Battle.active_actor
			@item_window.refresh
		when State_Skill
			@skill_window.active = true
			@skill_window.actor = Game_Battle.active_actor
			@skill_window.index = 0
		when State_AllyAction, State_EnemyAction, State_Victory, State_Defeat
    end

    @options_window.visible = false
    @status_window.visible = false
    @command_window.visible = false
    @item_window.visible = false
    @skill_window.visible = false
    @help_window.visible = false

    @item_window.help_window = nil
    @skill_window.help_window = nil

    case @state
		when State_Options
			@help_window.visible = true
			@options_window.visible = true
			@status_window.visible = true
			@status_window.x = 76
		when
      State_Battle,State_AutoBattle, State_Command, State_TargetEnemy,
      State_TargetAlly, State_AllyAction, State_EnemyAction
			@status_window.visible = true
			@status_window.x = 0
			@command_window.visible = true
		when State_Item
			@item_window.visible = true
			@item_window.help_window = @help_window
			@help_window.visible = true
		when State_Skill
			@skill_window.visible = true
			@skill_window.help_window = help_window
			help_window.visible = true
		when State_Victory, State_Defeat
			@status_window.visible = true
			@status_window.x = 0
			@command_window.visible = true
			@help_window.visible = true
    end
  end

  def set_anim_state(ally, state)
    ally.anim_state = state
    ally.update_anim @cycle
  end

  def update_anim_state
    ally = Game_Battle.active_ally
    anim_state = ally.defending ? Battle::Ally::Defending : Battle::Ally::Idle
    state = ally.actor.significant_state
		anim_state = state.battler_animation_id == 100 ? 7 : state.battler_animation_id + 1 unless state.nil?
    set_anim_state ally, anim_state
  end

  def restart
    update_anim_state
    self.state = State_Battle
    Game_Battle.active_ally.last_command = pending_command
  end

  def command
    command = @command_window.command
    @pending_command = command.index

    case (command.type)
		when RPG::BattleCommand::Type_attack
			Game_Battle.target_enemy = 0
			self.state = State_TargetEnemy
		when RPG::BattleCommand::Type_skill
			self.state = State_Skill
			@skill_window.subset = RPG::Skill::Type_normal
		when RPG::BattleCommand::Type_subskill
			self.state = State_Skill
			@skill_window.subset = @command_window.skill_subset
		when RPG::BattleCommand::Type_defense; defend
		when RPG::BattleCommand::Type_item; self.state = State_Item
		when RPG::BattleCommand::Type_escape; escape
		when RPG::BattleCommand::Type_special; sepcial
    end
  end

  def escape
    if Game_Battle.espace; Scene.pop
    else; Game_Battle.restart
    end
  end

  def special
    # FIXME: special commands (link to event)

    Game_Battle.restart
  end

  def defend
    Game_Battle.defend
    Game_Battle.restart
  end

	def item
    item_id = @item_window.item_id
    if item_id.nil?
      Game_System.se_play $game_data.system.buzzer_se
      return
    end

    item = Data.items[item_id]
    case (item.type)
    when RPG::Item::Type_normal
			Game_System.se_play($game_data.system.buzzer_se)
    when RPG::Item::Type_weapon, RPG::Item::Type_shield, RPG::Item::Type_armor,
      RPG::Item::Type_helmet, RPG::Item::Type_accessory
      if item.use_skill; item_skill(item)
			else
				# can't be used
				Game_System.se_play $game_data.system.buzzer_se
      end
		when RPG::Item::Type_medicine
			if item.entire_party; begin_item
			else
				Game_Battle.target_active_ally
				self.state = State_TargetAlly
			end
		when RPG::Item::Type_book, RPG::Item::Type_material
			# can't be used in battle?
			Game_System.se_play $game_data.system.buzzer_se
		when RPG::Item::Type_special; item_skill item
		when RPG::Item::Type_switch
			Game_Switches[item.switch_id] = true
			Game_Battle.restart
    end
  end

	def item_skill(item); skill Data.skills[item.skill_id]; end

  def skill(s = nil)
    if s.nil?
      @skill_id = @skill_window.skill_id
      if @skill_id.nil?
        Game_System.se_play $game_data.system.buzzer_se
        return
      end

      s = Data.skills[@skill_id]
    end

    @skill_id = s.index

    case s.type
    when RPG::Skill::Type_teleport, RPG::Skill::Type_escape, RPG::Skill::Type_switch
      begin_skill
    end

    case s.scope
    when RPG::Skill::Scope_enemy
      Game_Battle.target_enemy = 0
      self.state = State_TargetEnemy
    when RPG::Skill::Scope_ally
      Game_Battle.target_active_ally
      self.state = State_TargetAlly
    when RPG::Skill::Scope_enemies, RPG::Skill::Scope_self, RPG::Skill::Scope_party
      begin_skill
    end
  end

  def target_done
    case @target_state
    when State_Command; begin_attack
    when State_Item; begin_item
    when State_Skill; begin_skill
    end
  end

  def begin_attack
    ally = Game_Battle.active_ally
    enemy = Game_Battle.active_enemy

    x0 = ally.rpg_actor.battle_x
    x1 = enemy.sprite.x - enemy.sprite.ox + enemy.sprite.width + ally.sprite.ox

    @actions = [
      Battle::SpriteAction.new(ally, Battle::Ally::WalkingLeft),
      Battle::MoveAction.new(ally.sprite, x0, x1, 8),
      Battle::SpriteAction.new(ally, Battle::Ally::RightHand),
      Battle::WaitAction.new(15),
      Battle::CommandAction.new { Game_Battle.attack },
      Battle::SpriteAction.new(ally, Battle::Ally::WalkingRight),
      Battle::MoveAction.new(ally.sprite, x1, x0, 8),
      Battle::CommandAction.ne { Game_Battle.restart },
      Battle::WaitAction.new(20),
    ]

    self.state = State_AllyAction
  end

  def begin_item
    ally = Game_Battle.active_ally
    Game_Battle.item = @item_window.item_id

    @actions = [
      Battle::SpriteAction.new(ally, Battle::Ally::Item),
      Battle::WaitAction.new(60),
      Battle::CommandAction.new { Game_Battle.use_item },
      Battle::CommandAction.new { Game_Battle.restart },
      Battle::WaitAction.new(20),
    ]

    self.state = State_AllyAction
  end

	def begin_skill
    ally = Game_Battle.active_ally
    skill = Data.skills[@skill_id]
    anim_state = skill_animation skill, ally
    animation = skill.animation_id != 0 ? Data.animations[skill.animation_id] : nil
    action = nil

    case (skill.type)
		when RPG::Skill::Type_teleport, RPG::Skill::Type_escape, RPG::Skill::Type_switch
		else
			case skill.scope
      when RPG::Skill::Scope_enemy
        action = Battle::AnimationAction.new Game_Battle.target_enemy.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_enemies
        unless animation.nil?
          x, y = Game_Battle.enemies_centroid
          action = Battle::AnimationAction.new x, y, animation
        end
      when RPG::Skill::Scope_self
        action = Battle::AnimationAction.new ally.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_ally
        action = Battle::AnimationAction.new Game_Battle.target_ally.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_party
        unless animation.nil?
          x, y = Game_Battle::allies_centroid
          action = Battle::AnimationAction.new x, y, animation
        end
			end
    end

		action = EASYRPG_MAKE_SHARED<Battle::WaitAction>(10) if action.nil?

    @actions = [
      Battle::SpriteAction.new(ally, anim_state),
      action,
      Battle::CommandAction.new { Game_Battle.use_skill },
      Battle::CommandAction.new { Game_Battle.restart },
      Battle::WaitAction.new(20),
    ]

    self.state = State_AllyAction
  end

  def do_item
    Game_Battle.use_item
  end

  def do_skill
    Game_Battle.skill = @skill_id
    Game_Battle.use_skill
  end

  def skill_animation(skill, ally)
    ret = skill.battler_animation_data.find { |v| v.index == ally.game_actor.id }
    ret.nil? or ret.pose == 0 ? Battle::Ally::SkillUse : data.pose
  end

  def enemy_action
    enemy = Game_Battle.active_enemy
    return unless enemy.game_enemy.exists

    enemy.defending = false

    @enemy_action = Game_Battle.choose_enemy_action enemy
    return if @enemy_action.nil?

    @actions.clear

    case enemy_action.kind
		when RPG::EnemyAction::Kind_basic; enemy_action_basic
		when RPG::EnemyAction::Kind_skill; enemy_action_skill
		when RPG::EnemyAction::Kind_transformation
			Game_Battle.morph = @enemy_action.enemy_id
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::CommandAction.new { Game_Battle.enemy_transform }
    end

    actions.push Battle::CommandAction.new(Game_Battle::EnemyActionDone)
    actions.push Battle::CommandAction.new(self) { |v| v.state = State_Battle }
    actions.push Battle::WaitAction.new(20)

    self.state = State_EnemyAction
  end

  def enemy_action_basic
    case @enemy_action.basic
		when RPG::EnemyAction::Basic_attack
			Game_Battle.target_random_ally
			ally = Game_Battle.target_ally
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::AnimationAction.new(ally.sprite, Data.animations[0])
			actions.push Battle::CommandAction.new(ally) { |v| Game_Battle.enemy_attack v }
		when RPG::EnemyAction::Basic_dual_attack
      (0...2).each { |v|
        Game_Battle.target_random_ally
        ally = Game_Battle.target_ally
        actions.push Battle::WaitAction.new(20)
        actions.push Battle::AnimationAction.new(ally.sprite, Data.animations[0])
        actions.push Battle::CommandAction.new(ally) { |v| Game_Battle.enemy_attack }
      }
		when RPG::EnemyAction::Basic_defense
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::CommandAction.new { Game_Battle.enemy_defend }
		when RPG::EnemyAction::Basic_observe
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::CommandAction.new { Game_Battle.enemy_observe }
		when RPG::EnemyAction::Basic_charge
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::CommandAction.new { Game_Battle.enemy_charge }
		when RPG::EnemyAction::Basic_autodestruction
			actions.push Battle::WaitAction.new(20)
			actions.push Battle::CommandAction.new { Game_Battle.enemy_destruct }
		when RPG::EnemyAction::Basic_nothing
			actions.push Battle::WaitAction.new(20)
    end
  end

	def enemy_action_skill
    enemy = Game_Battle.active_enemy
    skill = Data.skills[@enemy_action.skill_id]
    animation = skill.animation_id != 0 ? Data.animations[skill.animation_id] : nil
    action = nil
    x, y = 0, 0

    Game_Battle.skill = @enemy_action.skill_id

    case skill.type
		when RPG::Skill::Type_teleport, RPG::Skill::Type_escape
			action = Battle::MoveAction.new enemy.sprite, enemy.sprite.x, -enemy.sprite.width, 8
		when RPG::Skill::Type_switch
		when RPG::Skill::Type_normal
		else
			case skill.scope
      when RPG::Skill::Scope_enemy
        Game_Battle.target_random_ally
        action = Battle::AnimationAction.new Game_Battle.target_ally.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_self
        action = Battle::AnimationAction.new enemy.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_ally
        Game_Battle.target_random_ally
        action = Battle::AnimationAction.new Game_Battle.target_enemy.sprite, animation unless animation.nil?
      when RPG::Skill::Scope_enemies
        unless animation.nil?
          x, y = Game_Battle.allies_centroid
          action = Battle::AnimationAction.new x, y, animation
        end
      when RPG::Skill::Scope_party
        unless animation.nil?
          x, y = Game_Battle.enemies_centroid
          action = Battle::AnimationAction.new x, y, animation
        end
			end
    end

		action = Battle::WaitAction.new 30 if action.nil?

    @actions.push action
    @actions.push Battle::CommandAction.new { Game_Battle.enemy_skill }
  end


	def process_actions
    case @state
		when State_Battle, State_AutoBattle
			Game_Battle.update

			check_win
			check_lose
			check_abort
			check_flee

			if @help_window.visible && @message_timer > 0
				@message_timer -= 1
				@help_window.visible = false if @message_timer <= 0
			end

      while Game_Battle.next_active_enemy; EnemyAction(); end
    when State_AllyAction, State_EnemyAction
			unless actions.empty?
				action = @actions.first
				@actions.shift if action.act
			end
    end
  end

  def process_input
    if Input.trigger? Input::DECISION
      Game_System.se_play $game_data.system.decision_se
      case @state
			when State_Options
				case @options_window.index
        when 0
          Game_Temp.battle_result = Game_Temp::BattleVictory
          Scene.pop
          # @auto_battle = false
          # self.state = State_Battle
        when 1
          if Game_Temp.battle_defeat_mode != 0
            Game_Temp.battle_result = Game_Temp::BattleDefeat
            Scene.pop
          end
          # @auto_battle = true
          # self.state = State_Battle
        when 2
          if Game_Temp.battle_escape_mode != 0
            Game_Temp.battle_result = Game_Temp::BattleEscape
            Scene.pop
          end
          # escape
				end
			when State_Battle
				Game_Battle.active_ally = @status_window.active_character
				self.state = State_Command if Game_Battle.have_active_ally?
			when State_AutoBattle # no-op
			when State_Command; command
			when State_TargetEnemy, State_TargetAlly; target_done
			when State_Item; item
			when State_Skill; skill
			when State_AllyAction, State_EnemyAction
			when State_Victory, State_Defeat; Scene.pop
      end
    end

    if Input.trigger? Input::CANCEL
      Game_System.se_play $game_data.system.cancel_se
      case @state
			when State_Options; Scene.pop
			when State_Battle, State_AutoBattle; self.state = State_Options
			when State_Command; self.state = State_Battle
			when State_TargetEnemy, State_Item, State_Skill; self.state = State_Command
			when State_TargetAlly; self.state = State_Item
			when State_AllyAction, State_EnemyAction
			when State_Victory, State_Defeat; Scene.pop
      end
    end

    if (state == State_TargetEnemy && Game_Battle::HaveTargetEnemy())
      Game_Battle::TargetNextEnemy() if (Input().IsRepeated(Input_::DOWN))
      Game_Battle::TargetPreviousEnemy() if (Input().IsRepeated(Input_::UP))
      Game_Battle::ChooseEnemy()
    end

    if (state == State_TargetAlly && Game_Battle::HaveTargetAlly())
      Game_Battle::TargetNextAlly() if (Input().IsRepeated(Input_::DOWN))
      Game_Battle::TargetPreviousAlly() if (Input().IsRepeated(Input_::UP))
    end
  end

  def do_auto
    return if @state != State_AutoBattle

    Game_Battle.active_ally = @status_window.active_character
    return unless Game_Battle.has_active_ally?

    # FIXME: this assumes that the character has an "Attack" command.
    # FIXME: should try to use some intelligence

    Game_Battle.choose_enemy
    return unless Game_Battle.have_target_enemy?

    @pending_command = 1
    Game_Battle.attack
    Game_Battle.restart
  end

  def update_background
    return if Game_Temp.battle_background == Game_Battle.background_name

    Game_Temp.battle_background = Game_Battle.background_name
    @background = Background.new Game_Temp.battle_background
  end

  def update_cursors
    frames = [0, 1, 2, 1]

    if Game_Battle.have_active_ally?
      ally = state == State_TargetAlly and Game_Battle.have_target_ally? ? Game_Battle.target_ally : Game_Battle.active_ally
      @ally_cursor.visible = true
      @ally_cursor.x = ally.rpg_actor.battle_x - @ally_cursor.width / 2
      @ally_cursor.y = ally.rpg_actor.battle_y - @ally.sprite.height  / 2 - @ally_cursor.height - 2
      @ally_cursor.src_rect = Rect.new frames[(@cycle / 15) % 4] * 16, 16, 16, 16
    else; @ally_cursor.visible = false
    end

    if @state == State_TargetEnemy and Game_Battle.have_target_enemy?
      enemy = Game_Battle.target_enemy
      @enemy_cursor.visible = true
      @enemy_cursor.x = enemy.member.x + enemy.sprite.width / 2 + 2
      @enemy.cursor.y = enemy.member.y + @enemy_cursor.height / 2
      @enemy_cursor.src_rect = Rect.new frames[(@cycle / 15) % 4], 0, 16, 16
    else; @enemy_cursor.visible = false
    end
  end

  def update_sprites
    Game_Battle.enemies.each { |v|
      v.fade = 60 if v.sprite.visible and not v.game_enemy.exists and v.fade == 0

      if v.fade > 0
        v.sprite.opacity = v.fade * 255 / 60
        v.fade -= 1
        v.sprite.visible = false if v.fade == 0
      end

      v.sprite.y = v.sprite.z = v.member.y + 3 * Math.sin(@cycle / 30.0) if v.rpg_enemy.levitate
    }

    Game_Battle.allies.each { |v| v.update_anim @cycle }
  end

  def update_floaters
    @floaters.map! { |v|
      v.duration -= 1
      v.duration <= 0 ? nil : v
    }.compact!
  end

  def check_win
    return if @state = State_Victory or @state = State_Defeat
    return if not Game_Battle.check_win

    Game_Battle.allies.each { |v| v.anim_state = Battle::Ally::Victory }
    Game_Temp.battle_result = Game_Temp::BattleVictory
    self.state = State_Victory
    message Data.terms.victory || 'Victory'
  end

  def check_lose
    return if @state = State_Victory or @state == State_Defeat
    return if not Game_Battle.check_lose

    Game_Temp.battle_result = Game_Temp::BattleDefeat
    self.state = State_Defeat
    message Data.terms.defeat || 'Defeat'
  end

  def check_abort
    return if not Game_Battle.terminate
    Game_Temp.battle_result = Game_Temp::BattleAbort
    Scene.pop
  end

  def check_flee
    return if not Game_Battle.allies_flee
    Game_Battle.allies_flee = false
    Game_Temp.battle_result = Game_Temp::BattleEscape
    Scene.pop
  end

  def update
    [@options_window, @status_window, @command_window, @help_window,
      @item_window, @skill_window].each { |v| v.update }

    Game_Battle.active_ally = @status_window.active_character
    @command_window.actor = Game_Battle.active_actor

    # cycle += 1

    process_actions
    process_input
    do_auto

    update_background
    # update_cursors
    update_sprites
    update_floaters
    update_animations
  end
end
