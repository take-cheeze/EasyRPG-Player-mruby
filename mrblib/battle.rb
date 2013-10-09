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


module Battle
  class Battler
    Side_Ally = 0
    Side_Enemy = 1

    def self.gauge_full; 10000; end

    attr_reader :turns

    def ready?; @gauge >= gauge_full; end

    def next_turn
      @turns += 1
      @gauge = 0
    end

    def attack; actor.attack + atk_mod; end
    def defence; actor.defence + def_mod; end
    def spirit; actor.spirit + spi_mod; end
    def agility; actor.agility + agi_mod; end

    def modify_attack(v); @atk_mod += v; end
    def modify_defence(v); @def_mod += v; end
    def modify_spirit(v); @spi_mod += v; end
    def modify_agility(v); @agi_mod += v; end
  end

  class Ally < Battler
    Idle = 1
    RightHand = 2
    LeftHand = 3
    SkillUse = 4
    Dead = 5
    Damage = 6
    BadStatus = 7
    Defending = 8
    WalkingLeft = 9
    WalkingRight = 10
    Victory = 11
    Item = 12

    def actor; @game_actor; end

    def initialize(game_actor, id)
      super id
      @game_actor = game_actor
      @rpg_actor = Data.actor[@game_actor.index]
      @sprite_frame = nil
      @sprite_file = ""
      @anime_state = Idle
      @defending = false
      @last_command = 0
      @speed = 30 + rand.abs % 10
    end

    def create_sprite
      return if Player.rpg2k?

      @sprite = Sprite.new
      @sprite.ox, @sprite.oy = 24, 24
      @sprite.x, @sprite.y = @rpg_actor.battle_x, @rpg_actor.battle_y
      @sprite.z = @rpg_actor.battle_y

      anim_state = @anim_state
      update_anim 0
    end

    def can_act; not actor.dead? end
    def enable_combo(id, multiple)
      @combo_command = id
      @combo_multiple = multiple
      # FIXME: make use of this data
    end
    def update_anime(cycle)
      return if Player.rpg2k?

      frames = [0, 1, 2, 1]
      frame = frames[(cycle / 15) % 4]
      return if frame == sprite_frame

      anime = Data.battleranimation[@rpg_actor.battle_animation]
      @sprite.src_rect =
        Rect.new(frame * 48, anime.base_data[@anim_state - 1].battler_index * 48, 48, 48)
    end
    def anime_state=(state)
      return if Player.rpg2k?

      @anim_state = state

      ext = Data.battleranimations[rpg_actor.battler_animation].base_data[@anim_state - 1]
      return if ext.battler_name == @sprite_file

      @sprite_file = ext.battler_name
      @sprite.bitmap = Cache.battle_charset @sprite_file
    end
  end

  class Enemy < Battler
    def initialize(member, id)
      super id
      @member = member
      @game_enemy = Game_Enemy.new @member.enemy_id
      @rpg_enemy = Data.enemies[@member.enemy_id]
      @fade = 0
      @defending = false
      @charged = false
      @escaped = false
      @speed = 25 + rand.abs % 10
      @game_enemy.hidden = @member.invisible
    end

    def actor; @game_enemy; end
    def can_act; actor.exists and not @escaped end

    def transform(id)
      @rpg_enemy = Data.enemies[id]
      @game_enemy.transform id
      create_sprite
    end

    def create_sprite
      graphic = Cache.monster @rpg_enemy.battler_name
      (graphic = Bitmap.new(graphic)).hue_change(@rpg_enemy.battler_hue) if
        @rpg_enemy.battler_hue != 0

      @sprite = Sprite.new
      @sprite.bitmap = graphic
      @sprite.ox, @sprite.oy = graphic.width / 2, graphic.height / 2
      @sprite.x, @sprite.y = @member.x, @member.y
      @sprite.z = @member.y
      @sprite.visible = !@game_enemy.hidden?
    end
  end

  class Action
  end

  class WaitAction < Action
    def initialize(dur) @duration = dur; end

    def act
      @duration -= 1
      @duration <= 0
    end
  end

  class SpriteAction < Action
    def initialize(ally, anim_state)
      @ally = ally
      @anim_state = anim_state
    end

    def act
      Player.find("Battle").set_anim_stat @ally, @anim_state
      true
    end
  end

  class AnimationAction < Action
    def initialize(x, y, anim)
      @animation = BattleAnimation.new target.x, target.y, anim
    end

    def act
      @animation.visible ? @animation.update : @animation.visible = true
      @animation.frame >= @animation.frames
    end
  end

  class MoveAction < Action
    def initialize(sprite, x0, x1, speed)
      @sprite = sprite
      @x0, @x1 = x0, x1
      @speed = speed
    end

    def act
      x = @sprite.x
      done = false

      if x0 < x1; x += speed; done = x >= x1; end
      if x0 > x1; x -= speed; done = x <= x1; end

      done = true if x0 == x1
      x = x1 if done
      sprite.x = x

      done
    end
  end

  class CommandAction < Action
    def initialize(*args, &block)
      @args = args
      @block = block
    end

    def act
      @block.call(*@args)
      true
    end
  end
end
