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

#ifndef _BITMAP_H_
#define _BITMAP_H_

#include <pixman.h>
#include <string>
#include <boost/container/vector.hpp>

#include "memory_management.h"
#include "text.h"
#include "rect.h"
#include "color.h"


class Tone;
struct Matrix;

struct BlitCommon {
	BlitCommon(int x_, int y_, Bitmap const& src_, Rect const& src_rect_)
			: x(x_), y(y_), src(src_), src_rect(src_rect_) {}

	int x, y;
	Bitmap const& src;
	Rect src_rect;
};

typedef EASYRPG_SHARED_PTR<pixman_image_t> pixman_image_ptr;

class Bitmap {
  public:
	static BitmapRef Create(std::string const& file, bool transparent = true);
	static BitmapRef Create(size_t width, size_t height, Color const& col = Color(0, 0, 0, 0));
	static BitmapRef Create(BitmapRef const& another);
	static BitmapRef Create(uint8_t const* data, size_t data_size, bool transparent = true);

	size_t width() const;
	size_t height() const;

	Rect rect() const;

	void blit(int x, int y, Bitmap const& src, Rect const& src_rect, int opacity = 255);
	void fill(Rect const& rect, Color const& col);

	void clear();

	Color const& get_pixel(int x, int y) const;
	void set_pixel(int x, int y, Color const& col);

	void hue_change(int hue);

	void draw_text(int x, int y, std::string const& str, Text::Alignment aln = Text::AlignLeft);
	void draw_text(Rect const& rect, std::string const& str, Text::Alignment aln = Text::AlignLeft);

	void draw_text(int x, int y, std::string const& str, int color, Text::Alignment aln = Text::AlignLeft);
	void draw_text(Rect const& rect, std::string const& str, int color, Text::Alignment aln = Text::AlignLeft);
	Rect text_size(std::string const& str) const;

	void effect_blit(BlitCommon const& info,
					  int top_opacity, int bottom_opacity, int opacity_split,
					  Tone const& tone, double zoom_x, double zoom_y, double angle,
					  int waver_depth, double waver_phase);
	void effect_blit(BlitCommon const& info, Matrix const& mat,
					 int top_opacity, int bottom_opacity, int opacity_split);
	void transform_blit(BlitCommon const& info, Matrix const& mat, int opacity);

	void flip_blit(BlitCommon const& info, bool horizontal, bool vertical);
	void tone_blit(BlitCommon const& info, Tone const& tone);
	void blend_blit(BlitCommon const& info, Color const& color);
	void waver_blit(BlitCommon const& info, int depth, double phase, int opacity);

	void tiled_blit(BlitCommon const& info, Rect const& dst_rect, int opacity);
	void stretch_blit(Rect const& dst_rect, Bitmap const& src, Rect const& src_rect, int opacity);

	void flip(Rect const& rect, bool horizontal, bool vertical);

	BitmapRef resample(int scale_w, int scale_h, Rect const& src_rect) const;
	BitmapRef sub_image(Rect const& rect) const;
	BitmapRef tone_change(Tone const& tone, Rect const& rect) const;
	BitmapRef waver(int waver_depth, double phase, Rect const& rect) const;

	bool clear_dirty_flag();

	pixman_image_t* image();

  public:
	FontRef font;

  private:
	Bitmap(size_t width, size_t height, Color const& col);
	Bitmap(Bitmap const& bmp);

	void mark_dirty();

	void pixman_image_composite(pixman_image_ptr const& src,
								pixman_image_ptr const& mask,
								int16_t src_x, int16_t src_y,
								int16_t mask_x, int16_t mask_y,
								int16_t dest_x, int16_t dest_y,
								uint16_t width, uint16_t height);

	void pixman_image_composite(pixman_image_ptr const& src,
								pixman_image_ptr const& mask,
								pixman_image_ptr const& dst,
								int16_t src_x, int16_t src_y,
								int16_t mask_x, int16_t mask_y,
								int16_t dest_x, int16_t dest_y,
								uint16_t width, uint16_t height) const;

  private:
	bool dirty_;
	size_t const width_, height_;
	boost::container::vector<Color> data_;

	pixman_image_ptr const ref_;
};

#endif
