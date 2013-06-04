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

// Headers
#include <cstdlib>
#include <cstdarg>
#include <ctime>

#include <iomanip>
#include <iostream>
#include <sstream>
#include <exception>

#ifdef GEKKO
	#include <unistd.h>
#endif

#include "filefinder.h"
#include "graphics.h"
#include "input.h"
#include "options.h"
#include "output.h"
#include "player.h"
#include "main_data.h"
#include "baseui.h"
#include "image_io.h"
#include "bitmap.h"

#include <boost/config.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/format.hpp>

#ifdef BOOST_NO_EXCEPTIONS
#include <boost/throw_exception.hpp>

void boost::throw_exception(std::exception const& exp) {
	Output_::Error("exception: %s", exp.what());
}
#endif

char const* Output_::Type2String(Type t) const {
	assert(t < TYPE_END);

	static char const* type_str[Output_::TYPE_END]
			= { "Debug", "Warning", "Error", };
	return type_str[t];
}

Output_::Output_()
		: ignore_pause_(false)
		, log_file_(OUTPUT_FILENAME, std::ios_base::out | std::ios_base::app)
		, buffer_(BUFFER_SIZE)
{}

Output_::Message::Message(Type t, std::string const& m, boost::optional<std::string> const& ss)
		: time(std::time(NULL)), type(t), message(m), screenshot(ss) {}

std::ostream& Output_::output_time(std::time_t const t) {
	char const time_fmt[] = "%Y/%m/%d %a %H:%M:%S";

	char buf[sizeof(time_fmt) + 10];
	strftime(buf, sizeof(buf), time_fmt, std::localtime(&t));
	log_file_ << "Local: "  << buf;

	strftime(buf, sizeof(buf), time_fmt, std::gmtime(&t));
	return log_file_ << ", UTC: " << buf << std::endl;
}

void Output_::IgnorePause(bool const val) {
	ignore_pause_ = val;
}

template<Output_::Type T>
void Output_::HandleScreenOutput(std::string const& msg, bool exit) {
	using std::endl;

	buffer_.push_back(Message(T, msg, TakeScreenshot()));
	Message const& m = buffer_.back();

	output_time(m.time) << Type2String(m.type) << ":" << endl << "  " << msg << endl;

	if(ignore_pause_) { return; }

	char const* const wait_message =
			exit
			? "EasyRPG Player will close now.\nPress any key to exit..."
			: "Press any key to continue...";

	if(DisplayUi) {
		std::ostringstream ss;
		ss << Type2String(m.type) << ":" << endl << msg << endl << endl << wait_message;
		Graphics().ScreenBuffer()->clear();
		DisplayUi->DrawScreenText(ss.str(), 10, 30 + 10);
		DisplayUi->UpdateDisplay();
		Input().ResetKeys();
		while (!Input().IsAnyPressed()) {
			DisplayUi->Sleep(1);
			DisplayUi->ProcessEvents();

			if (Player().exit_flag) break;

			Input().Update();
		}
		Input().ResetKeys();
		Graphics().FrameReset();
		Graphics().Update();
	} else {
		// Fallback to Console if the display is not ready yet
		std::cout << msg << endl << endl << wait_message;
#ifdef GEKKO
		// Wii stdin is non-blocking
		sleep(5);
#else
		std::cin.get();
#endif
	}
}

std::string Output_::CreateScreenshotPath(unsigned const idx) const {
	return FileFinder().MakePath(
		Main_Data::project_path,
		"screenshot_" + boost::lexical_cast<std::string>(idx) + ".png");
}

boost::optional<std::string> Output_::TakeScreenshot() {
	unsigned index = 0;
	std::string p;
	do {
		p = CreateScreenshotPath(index++);
	} while(FileFinder().Exists(p));
	return TakeScreenshot(p)? p : boost::optional<std::string>();
}

bool Output_::TakeScreenshot(std::string const& file) {
	EASYRPG_SHARED_PTR<std::fstream> ret =
		FileFinder().openUTF8(file, std::ios_base::binary | std::ios_base::out | std::ios_base::trunc);
	return ret? Output_::TakeScreenshot(*ret) : false;
}

bool Output_::TakeScreenshot(std::ostream& os) {
	return ImageIO::WritePNG(Graphics().ScreenBuffer(), os);
}

void Output_::Error(boost::format const& fmt) { Error(fmt.str()); }
void Output_::Error(std::string const& err) {
	HandleScreenOutput<TypeError>(err, true);
	exit(EXIT_FAILURE);
}

void Output_::Warning(boost::format const& fmt) { Warning(fmt.str()); }
void Output_::Warning(std::string const& warn) {
	HandleScreenOutput<TypeWarning>(warn, false);
}

void Output_::Debug(boost::format const& fmt) { Debug(fmt.str()); }
void Output_::Debug(std::string const& msg) {
	// save ignore pause state
	bool pause_state = true;
	std::swap(pause_state, ignore_pause_);

	HandleScreenOutput<TypeDebug>(msg, false);

	std::swap(pause_state, ignore_pause_);
}
