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

#ifndef _GRAPHICS_H_
#define _GRAPHICS_H_

// Headers
#include <string>
#include <list>
#include <map>
#include <vector>

#include "system.h"
#include "color.h"
#include "memory_management.h"

#include <boost/noncopyable.hpp>

class ZObj;
class Drawable;

/**
 * Graphics.
 * Handles screen drawing.
 */
struct Graphics_ : boost::noncopyable {
	/**
	 * Initializes Graphics.
	 */
	Graphics_();

	/**
	 * Updates the screen.
	 */
	void Update();

	/**
	 * Resets the fps count, should be called after an
	 * expensive operation.
	 */
	void FrameReset();

	/**
	 * Waits frames.
	 * @param duration frames to wait.
	 */
	void Wait(int duration);

	/**
	 * Gets a bitmap with the actual contents of the screen.
	 * @return screen contents
	 */
	BitmapRef SnapToBitmap();

	/** Transition types. */
	enum TransitionType {
		TransitionFadeIn,
		TransitionFadeOut,
		TransitionRandomBlocks,
		TransitionRandomBlocksUp,
		TransitionRandomBlocksDown,
		TransitionBlindOpen,
		TransitionBlindClose,
		TransitionVerticalStripesIn,
		TransitionVerticalStripesOut,
		TransitionHorizontalStripesIn,
		TransitionHorizontalStripesOut,
		TransitionBorderToCenterIn,
		TransitionBorderToCenterOut,
		TransitionCenterToBorderIn,
		TransitionCenterToBorderOut,
		TransitionScrollUpIn,
		TransitionScrollDownIn,
		TransitionScrollLeftIn,
		TransitionScrollRightIn,
		TransitionScrollUpOut,
		TransitionScrollDownOut,
		TransitionScrollLeftOut,
		TransitionScrollRightOut,
		TransitionVerticalCombine,
		TransitionVerticalDivision,
		TransitionHorizontalCombine,
		TransitionHorizontalDivision,
		TransitionCrossCombine,
		TransitionCrossDivision,
		TransitionZoomIn,
		TransitionZoomOut,
		TransitionMosaicIn,
		TransitionMosaicOut,
		TransitionWaveIn,
		TransitionWaveOut,
		TransitionErase,
		TransitionNone
	};

	/**
	 * Does a screen transition.
	 *
	 * @param type transition type.
	 * @param duration transition duration.
	 * @param erase erase screen flag.
	 */
	void Transition(TransitionType type, int duration, bool erase = false);

	/**
	 * Freezes the screen, and prepares it for a
	 * transition.
	 */
	void Freeze();

	/**
	 * Gets frame count.
	 *
	 * @return frame count since player started.
	 */
	int GetFrameCount();

	/**
	 * Sets frame count.
	 *
	 * @param framecount frame count since player started.
	 */
	void SetFrameCount(int framecount);

	ZObj* RegisterZObj(int z, Drawable* ID);
	void RegisterZObj(int z, Drawable* ID, bool multiz);
	void RemoveZObj(Drawable* ID);
	void RemoveZObj(Drawable* ID, bool multiz);
	void UpdateZObj(ZObj* zobj, int z);

	bool fps_on_screen;
	uint32_t drawable_id;

	void Push();
	void Pop();

	unsigned SecondToFrame(float second);

	BitmapRef const& ScreenBuffer() const;

	/**
	 * Gets background color.
	 *
	 * @return background color.
	 */
	Color const& GetBackcolor() const;

	/**
	 * Sets background color.
	 *
	 * @param color new background color.
	 */
	void SetBackcolor(const Color &color);

	/**
	 * Cleans video buffer.
	 */
	void CleanScreen();

  private:
	void InternUpdate();
	void UpdateTitle(double fps);
	void DrawFrame();
	void DrawOverlay();

	bool overlay_visible;
	double current_fps_;
	int framerate;
	int framecount;
	double frame_interval;

	unsigned next_fps_calculation_time;
	unsigned fps_draw_counter;
	double expected_next_frame_end_time;

	void UpdateTransition();

	BitmapScreenRef frozen_screen, black_screen, screen1, screen2;
	bool frozen;
	TransitionType transition_type;
	int transition_duration;
	int transition_frame;
	bool screen_erased;

	uint32_t drawable_creation;

	struct State {
		State() : zlist_dirty(false) {}
		std::list<EASYRPG_SHARED_PTR<ZObj> > zlist;
		bool zlist_dirty;
	};
	EASYRPG_SHARED_PTR<State> state;
	std::vector<EASYRPG_SHARED_PTR<State> > stack;

	static bool SortZObj(EASYRPG_SHARED_PTR<ZObj> const& first, EASYRPG_SHARED_PTR<ZObj> const& second);

	BitmapRef const screen_buffer_;

	/** Color for display background. */
	Color back_color;
};

Graphics_& Graphics();

#endif
