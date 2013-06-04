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
#ifdef _MSC_VER
#  pragma warning(disable: 4003)
#endif

#include <map>

#include <boost/format.hpp>
#include <boost/preprocessor/seq/for_each.hpp>
#include <boost/static_assert.hpp>

#include "cache.h"
#include "filefinder.h"
#include "bitmap.h"
#include "output.h"
#include "player.h"

struct Cache_::Spec {
	char const* directory;
	bool transparent;
	size_t min_width , max_width ;
	size_t min_height, max_height;
};

Cache_::Spec const Cache_::specs_[] = {
	{ "Backdrop", false, 320, 320, 160, 160 },
	{ "Battle", true, 480, 480, 96, 480 },
	{ "CharSet", true, 288, 288, 256, 256 },
	{ "ChipSet", true, 480, 480, 256, 256 },
	{ "FaceSet", true, 192, 192, 192, 192 },
	{ "GameOver", false, 320, 320, 240, 240 },
	{ "Monster", true, 16, 320, 16, 160 },
	{ "Panorama", false, 80, 640, 80, 480 },
	{ "Picture", true, 1, 640, 1, 480 },
	{ "System", true, 160, 160, 80, 80 },
	{ "Title", false, 320, 320, 240, 240 },
	{ "System2", true, 80, 80, 96, 96 },
	{ "Battle2", true, 640, 640, 640, 640 },
	{ "BattleCharSet", true, 144, 144, 384, 384 },
	{ "BattleWeapon", true, 192, 192, 512, 512 },
	{ "Frame", true, 320, 320, 240, 240 },
};

template<Cache_::Material::Type T>
BitmapRef Cache_::LoadBitmap(std::string const& f) {
	BOOST_STATIC_ASSERT(Material::REND < T && T < Material::END);

	Spec const& s = specs_[T];
	BitmapRef const ret = LoadBitmap(s, f);

	if(ret->width () < s.min_width  || s.max_width  < ret->width () ||
	   ret->height() < s.min_height || s.max_height < ret->height()) {
		Output().Debug(boost::format("Image size error in: %s/%s") % s.directory % f);
		Output().Debug(boost::format("width  (min, max, actual) = (%d, %d, %d)") % s.min_width  % s.max_width  % ret->width ());
		Output().Debug(boost::format("height (min, max, actual) = (%d, %d, %d)") % s.min_height % s.max_height % ret->height());
	}

	return ret;
}

BitmapRef Cache_::LoadBitmap(Spec const& spec, std::string const& filename) {
	string_pair const key(spec.directory, filename);

	cache_type::const_iterator const it = cache.find(key);

	if (it == cache.end() || it->second.expired()) {
		std::string const path = FileFinder().FindImage(spec.directory, filename);

		if (path.empty()) {
			// TODO:
			// Load a dummy image with correct size (issue #32)
			Output().Warning(boost::format("Image not found: %s/%s\n\nPlayer will exit now.") % spec.directory % filename);
			// Delayed termination, otherwise it segfaults in Graphics().Quit
			Player().exit_flag = true;
		}

		return (cache[key] = path.empty()
				? Bitmap::Create(16, 16)
				: Bitmap::Create(path, spec.transparent)
				).lock();
	} else { return it->second.lock(); }
}

#define macro(r, data, elem)						\
	BitmapRef Cache_::elem(const std::string& f) {	\
		return LoadBitmap<Material::elem>(f);		\
	}												\

BOOST_PP_SEQ_FOR_EACH(macro, ,
					  (Backdrop)(Battle)(Battle2)(Battlecharset)(Battleweapon)
					  (Charset)(Chipset)(Faceset)(Gameover)(Monster)
					  (Panorama)(Picture)(System)(System2)(Frame)(Title)
					  )

#undef macro

BitmapRef Cache_::Tile(const std::string& filename, int tile_id) {
	tile_pair const key(filename, tile_id);
	cache_tiles_type::const_iterator const it = cache_tiles.find(key);

	if (it == cache_tiles.end() || it->second.expired()) {
		BitmapRef chipset = Cache_::Chipset(filename);
		Rect rect = Rect(0, 0, 16, 16);

		int sub_tile_id = 0;

		if (tile_id > 0 && tile_id < 48) {
			sub_tile_id = tile_id;
			rect.x += 288;
			rect.y += 128;
		} else if (tile_id >= 48 && tile_id < 96) {
			sub_tile_id = tile_id - 48;
			rect.x += 384;
		} else if (tile_id >= 96 && tile_id < 144) {
			sub_tile_id = tile_id - 96;
			rect.x += 384;
			rect.y += 128;
		} else { // Invalid -> Use empty file (first one)
			rect.x = 288;
			rect.y = 128;
		}

		rect.x += sub_tile_id % 6 * 16;
		rect.y += sub_tile_id / 6 * 16;

		return(cache_tiles[key] = chipset->sub_image(rect)).lock();
	} else { return it->second.lock(); }
}

void Cache_::Clear() {
	for(cache_type::const_iterator i = cache.begin(); i != cache.end(); ++i) {
		if(i->second.expired()) { continue; }
		Output().Debug(boost::format("possible leak in cached bitmap %s/%s")
					   % i->first.first % i->first.second);
	}
	cache.clear();

	for(cache_tiles_type::const_iterator i = cache_tiles.begin(); i != cache_tiles.end(); ++i) {
		if(i->second.expired()) { continue; }
		Output().Debug(boost::format("possible leak in cached tilemap %s/%d")
					   % i->first.first % i->first.second);
	}
	cache_tiles.clear();
}
