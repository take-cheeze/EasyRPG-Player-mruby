/*
 * This file is part of EasyRPG Player.
 *
 * EasyRPG Player is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EasyRPG Player is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _OUTPUT_H_
#define _OUTPUT_H_

// Headers
#include <string>
#include <fstream>
#include <ctime>

#include <boost/optional.hpp>
#include <boost/noncopyable.hpp>
#include <boost/circular_buffer.hpp>
#include <boost/format/format_fwd.hpp>

class Color;

/**
 * Output
 */
struct Output_ : boost::noncopyable {
	/**
	 * generate path to screenshot image file from index
	 *
	 * @param idx index of screenshot
	 * @return generated screenshot path
	 */
	std::string CreateScreenshotPath(unsigned idx) const;

	/**
	 * Takes screenshot and save it to Main_Data::project_path.
	 *
	 * @return path of screenshot if success, otherwise none.
	 */
	boost::optional<std::string> TakeScreenshot();

	/**
	 * Takes screenshot and save it to specified file.
	 *
	 * @param file file to save.
	 * @return true if success, otherwise false.
	 */
	bool TakeScreenshot(std::string const& file);

	/**
	 * Takes screenshot and save it to specified stream.
	 *
	 * @param os output stream that PNG will be stored.
	 * @return true if success, otherwise false.
	 */
	bool TakeScreenshot(std::ostream& os);

	/**
	 * Ignores pause in Warning and Error.
	 *
	 * @param val whether to ignore pause.
	 */
	void IgnorePause(bool val);

	/**
	 * Display a warning with formatted string.
	 *
	 * @param fmt formatted warning to display.
	 */
	void Warning(boost::format const& fmt);
	void Warning(std::string const& fmt);

	/**
	 * Raises an error message with formatted string and
	 * closes the player afterwards.
	 *
	 * @param fmt formatted error to display.
	 */
	void Error(boost::format const& fmt);
	void Error(std::string const& fmt);

	/**
	 * Prints a debug message to the console.
	 *
	 * @param fmt formatted debug text to display.
	 */
	void Debug(boost::format const& fmt);
	void Debug(std::string const& fmt);

	Output_();

	enum Type { TypeDebug, TypeWarning, TypeError, TYPE_END };

	/*
	 * convert Type to string
	 *
	 * @param t type
	 * @return string expression of type
	 */
	char const* Type2String(Type t) const;

	/*
	 * get color corresponding to output type
	 * this color will be used in screen output
	 *
	 * Debug: blue
	 * Warning: orange
	 * Error: red
	 *
	 * @param t type
	 * @return color of output type
	 */
	Color const& TypeColor(Type t) const;

	/*
	 * generate time string from time_t
	 *
	 * @param t time
	 * @param time_only if true returns string without date and day of week
	 * @param string expression of time
	 */
	std::string local_time(std::time_t const t, bool time_only = false) const;
	std::string utc_time(std::time_t const t, bool time_only = false) const;

	struct Message {
		std::time_t time;
		Type type;
		std::string message;
		boost::optional<std::string> screenshot;

		Message();
		Message(Type t, std::string const& m, boost::optional<std::string> const& ss);
	};

	enum { BUFFER_SIZE = 100, };
	typedef boost::circular_buffer<Message> buffer_type;

	/*
	 * returns circular buffer with size BUFFER_SIZE
	 *
	 * @return output log buffer
	 */
	buffer_type const& buffer() const;

	/*
	 * clear frame screenshot
	 */
	void Update();

  private:
	bool ignore_pause_;
	std::ofstream log_file_;

	buffer_type buffer_;

	boost::optional<std::string> frame_screenshot_;

  private:
	std::ostream& output_time(std::time_t t);
	template<Type T>
	void HandleScreenOutput(std::string const& msg, bool exit);
};

#include <mruby.h>

Output_& Output(mrb_state* M = NULL);

#endif
