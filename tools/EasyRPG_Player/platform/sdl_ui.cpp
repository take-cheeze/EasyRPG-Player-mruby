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
#include "sdl_ui.h"
#include "color.h"
#include "graphics.h"
#include "keys.h"
#include "output.h"
#include "player.h"
#include "bitmap.h"
#include "audio.h"
#include "sdl_audio.h"
#include "utils.h"
#include "matrix.h"

#include <cstdlib>
#include <cstring>
#include <SDL.h>
#include <pixman.h>
#include <boost/format.hpp>


namespace {

Keys::InputKey SdlKey2InputKey(SDL_Keycode sdlkey) {
	switch (sdlkey) {
		case SDLK_BACKSPACE		: return Keys::BACKSPACE;
		case SDLK_TAB			: return Keys::TAB;
		case SDLK_CLEAR			: return Keys::CLEAR;
		case SDLK_RETURN		: return Keys::RETURN;
		case SDLK_PAUSE			: return Keys::PAUSE;
		case SDLK_ESCAPE		: return Keys::ESCAPE;
		case SDLK_SPACE			: return Keys::SPACE;
		case SDLK_PAGEUP		: return Keys::PGUP;
		case SDLK_PAGEDOWN		: return Keys::PGDN;
		case SDLK_END			: return Keys::ENDS;
		case SDLK_HOME			: return Keys::HOME;
		case SDLK_LEFT			: return Keys::LEFT;
		case SDLK_UP			: return Keys::UP;
		case SDLK_RIGHT			: return Keys::RIGHT;
		case SDLK_DOWN			: return Keys::DOWN;
		case SDLK_PRINTSCREEN	: return Keys::SNAPSHOT;
		case SDLK_INSERT		: return Keys::INSERT;
		case SDLK_DELETE		: return Keys::DEL;
		case SDLK_LSHIFT		: return Keys::LSHIFT;
		case SDLK_RSHIFT		: return Keys::RSHIFT;
		case SDLK_LCTRL			: return Keys::LCTRL;
		case SDLK_RCTRL			: return Keys::RCTRL;
		case SDLK_LALT			: return Keys::LALT;
		case SDLK_RALT			: return Keys::RALT;
		case SDLK_0				: return Keys::N0;
		case SDLK_1				: return Keys::N1;
		case SDLK_2				: return Keys::N2;
		case SDLK_3				: return Keys::N3;
		case SDLK_4				: return Keys::N4;
		case SDLK_5				: return Keys::N5;
		case SDLK_6				: return Keys::N6;
		case SDLK_7				: return Keys::N7;
		case SDLK_8				: return Keys::N8;
		case SDLK_9				: return Keys::N9;
		case SDLK_a				: return Keys::A;
		case SDLK_b				: return Keys::B;
		case SDLK_c				: return Keys::C;
		case SDLK_d				: return Keys::D;
		case SDLK_e				: return Keys::E;
		case SDLK_f				: return Keys::F;
		case SDLK_g				: return Keys::G;
		case SDLK_h				: return Keys::H;
		case SDLK_i				: return Keys::I;
		case SDLK_j				: return Keys::J;
		case SDLK_k				: return Keys::K;
		case SDLK_l				: return Keys::L;
		case SDLK_m				: return Keys::M;
		case SDLK_n				: return Keys::N;
		case SDLK_o				: return Keys::O;
		case SDLK_p				: return Keys::P;
		case SDLK_q				: return Keys::Q;
		case SDLK_r				: return Keys::R;
		case SDLK_s				: return Keys::S;
		case SDLK_t				: return Keys::T;
		case SDLK_u				: return Keys::U;
		case SDLK_v				: return Keys::V;
		case SDLK_w				: return Keys::W;
		case SDLK_x				: return Keys::X;
		case SDLK_y				: return Keys::Y;
		case SDLK_z				: return Keys::Z;
		case SDLK_LGUI			: return Keys::LOS;
		case SDLK_RGUI			: return Keys::ROS;
		case SDLK_MENU			: return Keys::MENU;
		case SDLK_KP_0			: return Keys::KP0;
		case SDLK_KP_1			: return Keys::KP1;
		case SDLK_KP_2			: return Keys::KP2;
		case SDLK_KP_3			: return Keys::KP3;
		case SDLK_KP_4			: return Keys::KP4;
		case SDLK_KP_5			: return Keys::KP5;
		case SDLK_KP_6			: return Keys::KP6;
		case SDLK_KP_7			: return Keys::KP7;
		case SDLK_KP_8			: return Keys::KP8;
		case SDLK_KP_9			: return Keys::KP9;
		case SDLK_KP_MULTIPLY	: return Keys::MULTIPLY;
		case SDLK_KP_PLUS		: return Keys::ADD;
		case SDLK_KP_ENTER		: return Keys::RETURN;
		case SDLK_KP_MINUS		: return Keys::SUBTRACT;
		case SDLK_KP_PERIOD		: return Keys::PERIOD;
		case SDLK_KP_DIVIDE		: return Keys::DIVIDE;
		case SDLK_F1			: return Keys::F1;
		case SDLK_F2			: return Keys::F2;
		case SDLK_F3			: return Keys::F3;
		case SDLK_F4			: return Keys::F4;
		case SDLK_F5			: return Keys::F5;
		case SDLK_F6			: return Keys::F6;
		case SDLK_F7			: return Keys::F7;
		case SDLK_F8			: return Keys::F8;
		case SDLK_F9			: return Keys::F9;
		case SDLK_F10			: return Keys::F10;
		case SDLK_F11			: return Keys::F11;
		case SDLK_F12			: return Keys::F12;
		case SDLK_CAPSLOCK		: return Keys::CAPS_LOCK;
		case SDLK_NUMLOCKCLEAR	: return Keys::NUM_LOCK;
		case SDLK_SCROLLLOCK	: return Keys::SCROLL_LOCK;
		default					: return Keys::NONE;
	}
}

int FilterUntilFocus(void* /* data */, SDL_Event* evnt) {
	switch (evnt->type) {
	case SDL_QUIT:
		Player::exit_flag(true);
		return 1;

	case SDL_WINDOWEVENT:
		return evnt->window.event == SDL_WINDOWEVENT_FOCUS_GAINED;

	default:
		return 0;
	}
}
}

AudioInterface& SdlUi::GetAudio() {
	return *audio_;
}

SdlUi::SdlUi(unsigned width, unsigned height, const std::string& title, bool fs_flag)
		: is_full_screen_(fs_flag)
		, mouse_focus_(false), mouse_x_(0), mouse_y_(0)
		, initial_width_(width), initial_height_(height)
{
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0) {
		Output().Error(boost::format("couldn't initialize SDL: %s") % SDL_GetError());
	}

	uint32_t const window_flags = fs_flag? SDL_WINDOW_FULLSCREEN : 0;
	window_.reset(SDL_CreateWindow(
		title.c_str(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		width, height, window_flags), &SDL_DestroyWindow);
	SetAppIcon();
	ShowCursor(true);

	SetZoom(true);

	renderer_.reset(SDL_CreateRenderer(window_.get(), -1, 0), &SDL_DestroyRenderer);

#if defined(HAVE_SDL_MIXER)
	audio_.reset(new SdlAudio());
#elif defined(HAVE_OPENAL)
	audio_.reset(new ALAudio());
#else
	audio_.reset(new EmptyAudio());
#endif
}

SdlUi::~SdlUi() {
	screen_.reset();
	renderer_.reset();
	window_.reset();
	SDL_Quit();
}

uint32_t SdlUi::GetTicks() const {
	return SDL_GetTicks();
}

void SdlUi::Sleep(uint32_t time) {
	SDL_Delay(time);
}

void SdlUi::Resize(long width, long height) {
	initial_width_ = width;
	initial_height_ = height;
	SetZoom(is_zoomed_);
}

void SdlUi::SetFullscreen(bool f) {
	is_full_screen_ = f;
	SDL_SetWindowFullscreen(window_.get(), f? SDL_WINDOW_FULLSCREEN : 0);
}

void SdlUi::SetZoom(bool z) {
	is_zoomed_ = z;
	int const p = z? 2 : 1;
	SDL_SetWindowSize(window_.get(), initial_width_ * p, initial_height_ * p);
	SDL_SetWindowPosition(window_.get(), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
}

bool SdlUi::IsZoomed() const {
	return is_zoomed_;
}

void SdlUi::ProcessEvents() {
	SDL_Event evnt;

	// Poll SDL events and process them
	while (SDL_PollEvent(&evnt)) {
		ProcessEvent(evnt);

		if (Player::exit_flag())
			break;
	}
}

void SdlUi::UpdateDisplay() {
	BitmapRef const& bmp = Graphics().ScreenBuffer();

	uint32_t const texture_format =
			SDL_BYTEORDER == SDL_LIL_ENDIAN
			? SDL_PIXELFORMAT_ABGR8888
			: SDL_PIXELFORMAT_RGBA8888;

	if(not screen_) {
		screen_.reset(SDL_CreateTexture(
			renderer_.get(), texture_format, SDL_TEXTUREACCESS_STREAMING,
			bmp->width(), bmp->height()), &SDL_DestroyTexture);
	}

	SDL_Rect src_rect;
	src_rect.x = 0; src_rect.y = 0; src_rect.w = bmp->width(); src_rect.h = bmp->height();

	SDL_UpdateTexture(
		screen_.get(), &src_rect, &bmp->get_pixel(0, 0), sizeof(Color) * bmp->width());
	SDL_RenderClear(renderer_.get());
	SDL_RenderCopy(renderer_.get(), screen_.get(), NULL, NULL);
	SDL_RenderPresent(renderer_.get());
}

void SdlUi::SetTitle(const std::string &title) {
	SDL_SetWindowTitle(window_.get(), title.c_str());
}

void SdlUi::ShowCursor(bool flag) {
	SDL_ShowCursor(flag);
}

void SdlUi::ProcessEvent(SDL_Event &evnt) {
	switch (evnt.type) {
		case SDL_WINDOWEVENT:
			ProcessActiveEvent(evnt);
			return;

		case SDL_QUIT:
			Player::exit_flag(true);
			return;

		case SDL_KEYDOWN:
			ProcessKeyDownEvent(evnt);
			return;

		case SDL_KEYUP:
			ProcessKeyUpEvent(evnt);
			return;

		case SDL_MOUSEMOTION:
			ProcessMouseMotionEvent(evnt);
			return;

		case SDL_MOUSEBUTTONDOWN:
		case SDL_MOUSEBUTTONUP:
			ProcessMouseButtonEvent(evnt);
			return;
	}
}

void SdlUi::ProcessActiveEvent(SDL_Event &evnt) {
	switch(evnt.window.event) {
		case SDL_WINDOWEVENT_FOCUS_LOST: {
			Player::pause();

			bool const last = CursorVisible();

			ShowCursor(not last);

			// Filter SDL events with FilterUntilFocus until focus is
			// regained
			SDL_SetEventFilter(&FilterUntilFocus, NULL);
			SDL_WaitEvent(NULL);
			SDL_SetEventFilter(NULL, NULL);

			ShowCursor(last);

			ResetKeys();

			Player::resume();
		} return;

		case SDL_WINDOWEVENT_ENTER:
			mouse_focus_ = true;
			break;
		case SDL_WINDOWEVENT_LEAVE:
			mouse_focus_ = false;
			break;
	}
}

void SdlUi::ProcessKeyDownEvent(SDL_Event &evnt) {
	switch (evnt.key.keysym.sym) {
	case SDLK_F4:
		// Close program on LeftAlt+F4
		if (evnt.key.keysym.mod & KMOD_LALT) {
			Player::exit_flag(true);
			return;
		}

		// Toggle fullscreen on F4 and no alt is pressed
		if (!(evnt.key.keysym.mod & KMOD_RALT) && !(evnt.key.keysym.mod & KMOD_LALT)) {
			SetFullscreen(not IsFullscreen());
		}
		return;

	case SDLK_F5:
		// Toggle fullscreen on F5
		SetZoom(not IsZoomed());
		return;

	case SDLK_F12:
		// Reset the game engine on F12
		Player::reset_flag(true);
		return;

	case SDLK_RETURN:
	case SDLK_KP_ENTER:
		// Toggle fullscreen on Alt+Enter
		if (evnt.key.keysym.mod & KMOD_LALT || (evnt.key.keysym.mod & KMOD_RALT)) {
			SetFullscreen(not IsFullscreen());
			return;
		}

		// Continue if return/enter not handled by fullscreen hotkey
	default:
		// Update key state
		keys[SdlKey2InputKey(evnt.key.keysym.sym)] = true;
		return;
	}
}

void SdlUi::ProcessKeyUpEvent(SDL_Event &evnt) {
	keys[SdlKey2InputKey(evnt.key.keysym.sym)] = false;
}

void SdlUi::ProcessMouseMotionEvent(SDL_Event& evnt) {
	mouse_focus_ = true;
	mouse_x_ = evnt.motion.x;
	mouse_y_ = evnt.motion.y;
}

void SdlUi::ProcessMouseButtonEvent(SDL_Event& evnt) {
	switch (evnt.button.button) {
	case SDL_BUTTON_LEFT:
		keys[Keys::MOUSE_LEFT] = evnt.button.state == SDL_PRESSED;
		break;
	case SDL_BUTTON_MIDDLE:
		keys[Keys::MOUSE_MIDDLE] = evnt.button.state == SDL_PRESSED;
		break;
	case SDL_BUTTON_RIGHT:
		keys[Keys::MOUSE_RIGHT] = evnt.button.state == SDL_PRESSED;
		break;
	}
}

extern uint32_t EasyRPGAppIcon[];

void SdlUi::SetAppIcon() {
	boost::shared_ptr<SDL_Surface> icon(SDL_CreateRGBSurfaceFrom(
		EasyRPGAppIcon, 48, 48, 4, 4 * 48, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff), SDL_FreeSurface);
	SDL_SetWindowIcon(window_.get(), icon.get());
}

void SdlUi::ResetKeys() {
	for (size_t i = 0; i < keys.size(); i++) {
		keys[i] = false;
	}
}

bool SdlUi::IsFullscreen() const {
	return is_full_screen_;
}

bool SdlUi::GetMouseFocus() const {
	return mouse_focus_;
}

int SdlUi::GetMousePosX() const {
	return mouse_x_;
}
int SdlUi::GetMousePosY() const {
	return mouse_y_;
}

bool SdlUi::CursorVisible() const {
	return SDL_ShowCursor(-1) > 0;
}

unsigned SdlUi::GetWidth() const {
	int w = 0, h = 0;
	SDL_GetWindowSize(window_.get(), &w, &h);
	return w;
}
unsigned SdlUi::GetHeight() const {
	int w = 0, h = 0;
	SDL_GetWindowSize(window_.get(), &w, &h);
	return h;
}
