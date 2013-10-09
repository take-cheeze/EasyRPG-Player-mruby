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

module Game_Message
  MAX_LINE = 4
end

class << Game_Message

  def init
    @background = true
    @position = 2
    @texts = []

    full_clear
  end

  # Used by Window_Message to reset some flags.
  def semi_clear
    @texts.clear
    @choice_disabled = Array.new 8, false
    @choice_start = 99
    @choice_max = 0
    @choice_cancel_type = 0
    @num_input_start = nil
    @num_input_variable_id = 0
    @num_input_digits_max = 0
  end

  # Used by the Game_Interpreter to completly reset all flags.
  def full_clear
    semi_clear

    @face_name = ""
    @face_index = 0
    # @background = true
    # @position = 2
    # @fixed_position = false
    # @dont_halt = false
  end

  def busy; not @texts.empty? end

  attr_reader(:texts, :face_name, :face_index, :face_flipped,
              :face_left_position, :background, :choice_max,
              :choice_cancel_type, :num_input_variable_id,
              :num_input_digits_max, :position, :fixed_position,
              :dont_halt, :visible, :choice_result)
  attr_accessor :choice_start, :num_input_start, :message_waiting

  # Number of lines before the start
  # of selection options.
  # +-----------------------------------+
  # |  Hi, hero, What's your name?    |
  # |- Alex                |
  # |- Brian              |
  # |- Carol              |
  # +-----------------------------------+
  # In this case, choice_start would be 1.
  # Same with num_input_start.

  # Disabled choices:
  # choice_disabled is true if choice is disabled (zero-based).
  attr_reader :choice_disabled
end
