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


=begin
Notes about MessageBox Open/Close:
RPG2k does open a MessageBox when the first ShowMsgBox-Event
on an event page occurs (or when there is a MsgBox event anywhere?).
The Box is then open until the whole event page ended
(Interpreter::CommandEnd).
The following behaviour is not implemented yet:
The MsgBox must stay open when the event following the current event
is an auto start (or parallel process?)-event. RPG2k scans the whole event
for a MsgBox call and keeps the MsgBox open when it finds one.
=end

# Window Message Class.
# This class displays the message boxes from
# ShowMessageBox command code.
class Window_Message < Window_Selectable
  speed_table = [0, 0, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
                 7, 7, 8, 8, 9, 9, 10, 10, 11]

  def alpha?(v); (?a[0] <= v and v <= ?z[0]) or (?A[0] <= v and v <= ?Z[0]); end

	def initialize(x, y, w, h)
    super x, y, w, h
    @contents_x, @contents_y = 0, 0
    @line_count = 0
    @text = []
    @kill_message = false
    @speed_modifier = 0
    @speed_frame_counter = 0
    @new_page_after_pause = false
    @number_input_window = Window_NumberInput.new 0, 0
    @gold_window = Window_Gold.new 232, 0, 88, 32

    self.contents = Bitmap.new w - 16, h - 16
    @visible = false
    self.z = 10000

    @active = false
    @index = nil
    @text_color = Font::ColorDefault

    @number_input_window.visible = false
    @gold_window.visible = false

    Game_Message.init

    @sleep_until = -1
  end

  def dispose
    terminate_message
    Game_Message.visible
  end

  LeftMargin = 8,
  FaceSize = 48,
  RightFaceMargin = 16,
  TopMargin = 6

	# Starts message processing by reading all
	# non-displayed from Game_Message.
  def start_message_processing
    contents.clear
    @text = []
    Game_Message.texts.each { |v| @text += v.to_utf32 + "\n".to_utf32 }
    @item_max = Game_Message.choice_max

    @text_index = 0
    @text_end = @text.length

    insert_new_page
  end

	# Ends the message processing.
	def finish_message_processing
    if Game_Message.choice_max > 0; start_choice_processsing
    elsif Game_Message.num_input_variable_id > 0; start_number_input_processsing
    elsif @kill_message
      terminate_message
      @kill_message = false
    else; @pause = true
    end

    @text = []
    @text_index = 0
    @text_end = text.length
  end

	# Does the initial steps to start a choice selection.
  def start_choice_processsing
    @active =  true
    @index = 0
  end

	# Does the initial steps to start a number input.
	def start_number_input_processsing
    @number_input_window.max_digits = Game_Message.num_input_digits_max
    if (!Game_Message.face_name.empty? && Game_Message.face_left_position)
      @number_input_window.x = LeftMargin + FaceSize + RightFaceMargin
    else; @number_input_window.x = x
    end
    @number_input_window.y = @y + @contents_y - 2
    @number_input_window.active = true
    @number_input_window.visible = true
    @number_input_window.update
  end

	# Clears the Messagebox and places the write pointer
	# in the top left corner.
	def insert_new_page
    if !Game_Message.face_name.empty? && Game_Message.face_left_position
      @contents_x = LeftMargin + FaceSize + RightFaceMargin
    else; @contents_x = 0
    end

    @contents_y += 16
    @line_count += 1

    if (@line_count >= Game_Message::choice_start && Game_Message::choice_max > 0)
      # A choice resets the font color
      @text_color = Font::ColorDefault

      # Check for disabled choices
      @text_color = Font::ColorDisabled if
        Game_Message.choice_disabled.test(@line_count - Game_Message.choice_start)

      @contents_x += 12
    end
  end

	# Inserts a line break.
  def insert_new_line
    contents.claer

    if Game_Message.fixed_position; self.y = Game_Message.position * 80
    else # Move Message Box to prevent player hiding
    end
		disp = $game_player.screen_y

		case (Game_Message::position)
		when 0 # Up
			y = disp > (16 * 7) ? 0 : 2 * 80
		when 1 # Center
			if disp <= 16 * 7; y = 2 * 80
			elsif disp >= 16 * 10; y = 0
			else; y = 80
			end
		when 2 # Down
			y = disp >= (16 * 10) ? 0 : 2 * 80
		end

    @opacity = Game_Message.background ? 255 : 0

    unless Game_Message.face_name.empty?
      if Game_Message.face_left_position
        @contents_x = LeftMargin + FaceSize + RightFaceMargin
        draw_face Game_Message.face_name, Game_Message.face_index, LeftMargin, TopMargin, Game_Message.face_flipped
      else
        @contents_x = 0
        draw_face Game_Message.face_name, Game_Message.face_index, 248, TopMargin, Game_Message.face_flipped
      end
    else; @contents_x = 0
    end

    contents_x += 12 if Game_Message.choice_start == 0 && Game_Message.choice_max > 0

    @contents_y = 2
    @line_count = 0
    @text_color = Font.default_color
    @speed_modifier = 0

    # If there is an input window on the first line
    start_number_input_processsing if
      Game_Message.num_input_start == 0 && Game_Message.num_input_variable_id > 0
  end

	# Closes the Messagebox and clears the waiting-flag
	# (allows the interpreter to continue).
  def terminate_message
    @active = false
    @pause = false
    @index = nil

    Game_Message.message_waiting = false
    if @number_input_window.visible
      @number_input_window.active = false
      @number_input_window.visible = false
    end

    gold_window.visible = false
    # The other flag resetting is done in Game_Interpreter::CommandEnd
    Game_Message.semi_clear
  end

	# Checks if the next message page can be displayed.
	#
	# @return If the text output can start.
  def next_message_possible?
    return true if Game_Message.num_input_variable_id > 0
    return false if Gmae::texts.empty?
    true
  end

	# Stub.
  def reset_window
  end

	def update
    super
    @number_input_window.update

    if visible && !Game_Message.visible
      # The Event Page ended but the MsgBox was used in this Event
      # It can be closed now.
      terminate_message
      self.close_animation = 5
      # Remove this when the Close Animation is implemented
      # The close animation must set the visible false flag
      self.visible = false
    elsif @pause; wait_for_input
    elsif @active; input_choice
    elsif @number_input_window.visible; input_number
    elsif !text.empty?; update_message # Output the remaining text for the current page
    elsif next_message_possible?
      # Output a new page
      start_message_processing
      #printf("Text: %s\n", text.c_str())
      if !visible
        # The MessageBox is not open yet but text output is needed
        self.open_animation = 5
        self.visible = true
      end
      Game_Message.visible = true
    end
  end

	# Continues outputting more text. Also handles the
	# CommandCode parsing.
	def update_message
    # Message Box Show Message rendering loop

    # Contains at what frame the sleep is over
    if @sleep_until > -1
      if Graphics.frame_count >= @sleep_until
        # Sleep over
        @sleep_until = -1
      else
        return
      end
    end

    instant_speed = false
    loop_count = 0
    loop_max = speed_table[@speed_modifier] == 0 ? 2 : 1

    while instant_speed || loop_count < loop_max
      # It's assumed that speed_modifier is between 0 and 20
      @speed_frame_counter += 1

      break if speed_table[@speed_modifier] != 0 && speed_table[@speed_modifier] != @speed_frame_counter

      @speed_frame_counter = 0

      @loop_count += 1
      if @text_index == @text_end
        finish_message_processing
        break
      elsif @line_count == 4
        @pause = true
        @new_page_after_pause = true
        break
      end

      if @text[@text_index] == ?\n
        @instant_speed = false
        insert_new_line
        break if @pause
      elsif @text[@text_index] == ?\f
        @instant_speed = false
        @text_index += 1
        @text_index += 1 if @text[@text_index] == ?\n
        if @text_index != @text_end
          @pause = true
          @new_page_after_pause = true
        end
        break
      elsif @text[@text_index] == ?\\ && @text_end - @text_index > 1
        # Special message codes
        @text_index += 1

        case @text[@text_index, 1].to_utf8.downcase.to_utf32[0].chr
        when ?c, ?n, ?s, ?v
          # These commands support indirect access via \v[]
          command_result = parse_command_code
          @contents.draw_text_2k @contents_x, @contents_y, @command_result, @text_color
          @contents_x += @contents.text_size(command_result).width
        when ?\\
          # Show Backslash
          @contents.draw_text_2k @contents_x, @contents_y, '\\', @text_color
          @contents_x += @contents.text_size('\\').width
        when ?_
          # Insert half size space
          @contents_x += contents.text_size(" ").width / 2
        when ?$
          # Show Gold Window
          @gold_window.y = y == 0 ? 240 - 32 : 0
          @gold_window.refresh
          @gold_window.open_animation = 5
          @gold_window.visible = true
        when ?!
          # Text pause
          @pause = true
        when ?^
          # Force message close
          # The close happens at the end of the message, not where
          # the ^ is encoutered
          @kill_message = true
        when ?>
          # Instant speed start
          @instant_speed = true
        when ?<
          # Instant speed stop
          @instant_speed = false
        when ?.
          # 1/4 second sleep
          @sleep_until = Graphics.frame_count + 60 / 4
          @text_index += 1
          return
        when ?|
          # Second sleep
          @sleep_until = Graphics.frame_count + 60
          @text_index += 1
          return
        end
      elsif @text[@text_index] == ?$ and
          @text_end - @text_index > 1 and
          alpha?(@text[@text_index + 1])
        # ExFont
        @contents.draw_text_2k @contents_x, @contents_y, @text[@text_index, 2].to_utf8, @text_color
        @contents_x += 12
        @text_index += 1
      else
        glyph = @text[@text_index, 1].to_utf8
        @contents.draw_text_2k @contents_x, @contents_y, glyph, @text_color
        @contents_x += contents.text_size(glyph).width
      end

      text_index += 1
    end
    @loop_count = 0
  end

	# Parses the parameter part of a \-message-command.
	# It starts parsing after the [ and stops after
	# encountering ], a non-number or a line break.
	#
	# @param is_valid contains if a number was read
	# @param call_depth how many ] to skip, used for
	#                   chained commands.
	# @return the read number.
	def parse_parameter(is_valid, call_depth = 1)
    text_index += 1

    if @text_index == @text_end || @text[@text_index] != ?[
      @text_index -= 1
      return 0, false
    end
    @text_index += 1 # Skip the [

    null_at_start = false
    ss = ''

    while @text_index < @text_end
      if @@text[@text_index] == ?\n
        @text_index -= 1
        break
      elsif @text[@text_index] == ?0
        # Truncate 0 at the start
        unless ss.empty?; null_at_start = true
        else; ss << '0'
        end
      elsif @text[@text_index] >= ?1 && @text[@text_index] <= ?9
        ss << @text[@text_index]
      elsif @text[@text_index] == ?]
        call_depth -= 1
        break if call_depth == 0
      else
        # End of number
        # Search for ] or line break
        while @text_index != @text_end
					if @text[@text_index] == ?\n
						text_index -= 1
						break
					elsif @text[@text_index] == ?]
						call_depth -= 1
            break if call_depth == 0
					end
					@text_index += 1
        end
        break
      end
      @text_index += 1
    end

    if ss.empty?
      if null_at_start; ss << ?0
      else return 0, false
      end
    end

    return ss.to_i, true
  end

	# Parses a message command code (\ followed by a char).
	# This should only be used for codes that accept
	# parameters!
	# The text_index must be on the char following \ when
	# calling.
	#
	# @param call_depth directly passed to ParseParameter
	#                   and automatically increased by 1
	#                   in every recursion.
	# @return the final text output of the code.
	def parse_command_code(call_depth = 1)
    int parameter
    bool is_valid
    # sub_code is used by chained arguments like \v[\v[1]]
    # In that case sub_code contains the result from \v[1]
    sub_code = nil
    cmd_char = @text[@text_index, 1].to_utf8.downcase.to_utf32[0]

    if @text_end - @text_index > 3 && @text[@text_index + 2] == ?\ &&
        @text[@text_index + 3, 1].to_utf8.downcase == 'v'
      @text_index += 3
      # The result is an int value, str-to-int is safe in this case
      call_depth += 1
      sub_code = parse_command_code(call_depth).to_i
    end

    case cmd_char
    when ?c
      # Color
      if (sub_code >= 0)
        parameter = sub_code
      else
        parameter, is_valid = parse_parameter(call_depth)
      end
      text_color = parameter > 19 ? 0 : parameter
    when ?n
      # Output Hero name
      if (sub_code >= 0)
        is_valid = true
        parameter = sub_code
      else; parameter, is_valid = parse_parameter(call_depth)
      end
      if (is_valid)
        # 0: Party hero
        actor = parameter == 0 ? Game_Party.actors[0] : Game_Actors.actors(parameter)
        return actor.name unless actor.nil?
      else; Output.warning 'Invalid argument for \\n-Command'
      end
    when ?s
      # Speed modifier
      if sub_code >= 0
        is_valid = true
        parameter = sub_code
      else; parameter, is_valid = parse_parameter(call_depth)
      end

      @speed_modifier = [0, [parameter, 20].min].max
    when ?v
      # Show Variable value
      if (sub_code >= 0)
        is_valid = true
        parameter = sub_code
      else; parameter, is_valid = parse_parameter(call_depth)
      end
      if is_valid && Game_Variables.valid_var?(parameter)
        return Game_Variables[parameter].to_s
      else; return '0' # Invalid Var is always 0
      end
    else # When this happens text_index was not on a \ during calling
    end

    ''
  end

	# Stub. For choice.
  def update_cursor_rect
    if (@index >= 0)
      x_pos = 2
      y_pos = (Game_Message.choice_start + @index) * 16
      width = contents.width

      if !Game_Message.face_name.empty?
        x_pos += LeftMargin + FaceSize + RightFaceMargin if (Game_Message.face_left_position)
        width = width - LeftMargin - FaceSize - RightFaceMargin - 4
      end

      cursor_rect = Rect.new x_pos, y_pos, width, 16
    else
      cursor_rect = Rect.new 0, 0, 0, 0
    end
  end

	# Waits for a key press before the text output
	# continutes.
  def wait_for_input
    @active = true; # Enables the Pause arrow
    if Input.trigger?(Input::DECISION) || Input.trigger?(Input::CANCEL)
      @active = false
      @pause = false

      if @text.empty?; terminate_message
      elsif @text_index != text_end && @new_page_after_pause
        @new_page_after_pause = false
        insert_new_page
      end
    end
  end

	# Stub. Handles choice selection.
  def input_choice
    if Input.trigger?(Input::CANCEL) and Game_Message.choice_cancel_type > 0
			Game_System.se_play $game_data.system.cancel_se
			Game_Message.choice_result = Game_Message.choice_cancel_type - 1; # Cancel
			terminate_message
    elsif Input.trigger? Input::DECISION
      if Game_Message.choice_disabled.test index
        Game_System.se_play $game_data.system.buzzer_se
        return
      end

      Game_System.se_play $game_data.system.decision_se
      Game_Message.choice_result = index
      terminate_message
    end
  end

	# Handles number input.
  def input_number
    return if not Input.trigger? Input::DECISION

		Game_System.se_play $game_data.system.decision_se
		Game_Variables[Game_Message.num_input_variable_id] = @number_input_window.number
		Game_Map.need_refresh = true
		terminate_message
		@number_input_window.number = 0
  end
end
