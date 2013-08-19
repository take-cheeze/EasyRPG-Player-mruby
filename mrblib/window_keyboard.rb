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

# Window Input Number Class.
# The number input window.
class Window_Keyboard < Window_Base
	# Constructor.
	#
	# @param ix window x position.
	# @param iy window y position.
	# @param iwidth window width.
	# @param iheight window height.
  def initialize(x, y, w = 320, h = 80)
    super x, y, w, h

    @mode = Letter
    @play_cursor = false
    @row, @col = 0, 0
    @row_spacing = 16
    @col_spacing = (contents.width - 2 * border_x) / col_max

    self.contents = Bitmap.new w - 16, h - 16
    self.z = 9999

    refresh
    update_cursor_rect
  end

  Hiragana = 0
  Katakana = 1
  Letter = 2
  Symbol = 3

  def update
    super

    if @active
      if Input.repeated? Input::DOWN
        @play_cursor = true
        @row = (@row + 1) % @row_max
        @col -= 1 if(@col > 0 and selected.nil? and not items[@mode][@row][@col - 1].nil?)
      end

      if Input.repeated? Input::UP
        @play_cursor = true
        @row = (@row + @row_max - 1) % @row_max
        @col -= 1 if(@col > 0 and selected.nil? and not items[@mode][@row][@col - 1].nil?)
      end

      if Input.repeated? Input::RIGHT
        @play_cursor = true
        @col += 1
        if (@col >= @col_max)
          @col = 0
          @row = (@row + 1) % @row_max if mode == Letter
        end
      end

      if Input.repeated? Input::LEFT
        @play_cursor = true
        @col -= 1
        if (@col < 0)
          @col = @col_max - 1
          row = (row + row_max - 1) % row_max if @mode == Letter
        end
      end
    end

    if selected.nil?
      update
      return
    end

    if @play_cursor
      Game_System.se_play Main_Data.game_data.system.cursor_se
      @play_cursor = false
    end
    update_cursor_rect
  end

  def refresh
    contents.clear
    for j in 0...@row_max
      for i in 0...@col_max
        r = item_rect j, i
        contents.draw_text_2k r.x + 4, r.y, items[@mode][j][i], Font::ColorDefault
      end
    end
  end

  def update_cursor_rect
    r = item_rect @row, @col
    r.y -= 2
    self.cursor_rect = r
  end

  def item_rect(r, c)
    Rect.new(c * @col_spacing + border_x, r * @row_spacing + border_y,
             contents.text_size(items[@mode][r][c]).width + 8, @row_spacing)
  end

  def mode=(v)
    @mode = v
    refresh
    update_cursor_rect
  end
	def selected; items[@mode][@row][@col]; end

	border_x = 8
	border_y = 4
	row_max = 9
	col_max = 10
	min_width = 2

	TO_SYMBOL = 'Symbol'
	TO_LETTER = 'Letter'
	DONE = 'Done'
	SPACE = 'SPACE'

  TO_KATAKANA = [0x3C, 0x30AB, 0x30CA, 0x3E].to_utf8
  TO_HIRAGANA = [0x3C, 0x304B, 0x306A, 0x3E].to_utf8
  DONE_JP = [0x3C, 0x6C7A, 0x5B9A, 0x3E].to_utf8

  # hiragana -> katakana -> letter -> symbol -> hiragana -> ...
  items = [
           # Hiragana
           Array.new(row_max) { Array.new col_max },

           [ # Katakana
            Array.new(col_max),Array.new(col_max),Array.new(col_max),
            Array.new(col_max),Array.new(col_max),Array.new(col_max),
            Array.new(col_max),Array.new(col_max),
            [nil,nil,nil,nil,nil,nil,Window_Keyboard::TO_LETTER,],
           ],

           [ # Letter
            ['A','B','C','D','E','a','b','c','d','e'],
            ['F','G','H','I','J','f','g','h','i','j'],
            ['K','L','M','N','O','k','l','m','n','o'],
            ['P','Q','R','S','T','p','q','r','s','t'],
            ['U','V','W','X','Y','u','v','w','x','y'],
            ['Z',nil ,nil ,nil ,nil ,'z',nil,nil,nil],
            ['0','1','2','3','4','5','6','7','8','9'],
            [SPACE,nil,nil,nil,nil,nil,nil, nil,nil,nil],
            [nil,nil,nil,nil,nil,nil,TO_SYMBOL,nil,DONE],
           ],

           [ # Symbol
            ['$A','$B','$C','$D','$E','$a','$b','$c','$d','$e'],
            ['$F','$G','$H','$I','$J','$f','$g','$h','$i','$j'],
            ['$K','$L','$M','$N','$O','$k','$l','$m','$n','$o'],
            ['$P','$Q','$R','$S','$T','$p','$q','$r','$s','$t'],
            ['$U','$V','$W','$X','$Y','$u','$v','$w','$x','$y'],
            ['$Z',nil  ,nil  ,nil  ,nil  ,'$z'],
            Array.new(col_max),
            Array.new(col_max),
            [nil,nil,nil,nil,nil,nil,nil,nil,Window_Keyboard::DONE],
           ]
          ]

  def self.write_range(k, num, y, x, base, diff)
    for i in 0...num; k[y][x + i] = [base + diff * i].to_utf8; end
  end

	def self.write_kana(k, base)
		# left half
		write_range k, 5, 0, 0, base + 0x02, 2 #  a -  o
		write_range k, 5, 1, 0, base + 0x0B, 2 # ka - ko
		write_range k, 5, 2, 0, base + 0x15, 2 # sa - so
		write_range k, 2, 3, 0, base + 0x1F, 2 # ta - ti
		write_range k, 3, 3, 0 + 2, base + 0x24, 2 # tu - to
		write_range k, 5, 4, 0, base + 0x2A, 1 # na - no
		write_range k, 5, 5, 0, base + 0x2F, 3 # ha - ho
		write_range k, 5, 6, 0, base + 0x3E, 1 # ma - mo
		write_range k, 3, 7, 0, base + 0x44, 2 # ya - yo
		k[7][3] = [base + 0x4F].to_utf8 # wa
		k[7][4] = [base + 0x53].to_utf8 # nn
		write_range k, 5, 8, 0, base + 0x49, 1 # ra - ro

		# right half
		write_range k, 5, 0, 5, base + 0x0C, 2 # ga - go
		write_range k, 5, 1, 5, base + 0x16, 2 # za - zo
		write_range k, 2, 2, 5, base + 0x20, 2 # da - di
		write_range k, 3, 2, 5 + 2, base + 0x25, 2 # du - do
		write_range k, 5, 3, 5, base + 0x30, 3 # ba - bo
		write_range k, 5, 4, 5, base + 0x31, 3 # pa - po
		write_range k, 5, 5, 5, base + 0x01, 2 # small a - o
		# small other
		k[6][5] = [base + 0x23].to_utf8 # small tu
		write_range k, 3, 6, 5 + 1, base + 0x43, 2 # small ya - yo
		k[6][9] = [base + 0x4E].to_utf8 # small wa
		# Symbol [cho-on, wave dash, dot, equal, star]
    [0x30FC, 0x301C, 0x30FB, 0xFF1D, 0x2606].each_with_index { |v,i|
      k[7][5 + i] = [v].to_utf8
    }
		k[8][5] = [0x30F4].to_utf8 # va

    k[8][8] = DONE_JP
	end

  write_kana items[Hiragana], 0x304B
  write_kana items[Katakana], 0x30A0

  items[Symbol][8][6] = TO_HIRAGANA
  items[Hiragana][8][6] = TO_KATAKANA
end
