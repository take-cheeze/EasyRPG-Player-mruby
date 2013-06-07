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

#ifndef _CACHE_H_
#define _CACHE_H_

// Headers
#include <string>

#include "system.h"
#include "memory_management.h"

#include <boost/noncopyable.hpp>
#include <boost/container/flat_map.hpp>

/**
 * Cache_
 */
struct Cache_ : boost::noncopyable {
	BitmapRef Backdrop(const std::string& filename);
	BitmapRef Battle(const std::string& filename);
	BitmapRef Battle2(const std::string& filename);
	BitmapRef Battlecharset(const std::string& filename);
	BitmapRef Battleweapon(const std::string& filename);
	BitmapRef Charset(const std::string& filename);
	BitmapRef Faceset(const std::string& filename);
	BitmapRef Frame(const std::string& filename);
	BitmapRef Gameover(const std::string& filename);
	BitmapRef Monster(const std::string& filename);
	BitmapRef Panorama(const std::string& filename);
	BitmapRef Picture(const std::string& filename);
	BitmapRef Chipset(const std::string& filename);
	BitmapRef Title(const std::string& filename);
	BitmapRef System(const std::string& filename);
	BitmapRef System2(const std::string& filename);
	BitmapRef Tile(const std::string& filename, int tile_id);
	void Clear();

  private:
	typedef std::pair<std::string,std::string> string_pair;
	typedef std::pair<std::string, int> tile_pair;

	typedef boost::container::flat_map<string_pair, EASYRPG_WEAK_PTR<Bitmap> > cache_type;
	cache_type cache;

	typedef boost::container::flat_map<tile_pair, EASYRPG_WEAK_PTR<Bitmap> > cache_tiles_type;
	cache_tiles_type cache_tiles;

	struct Material {
		enum Type {
			REND = -1,
			Backdrop,
			Battle,
			Charset,
			Chipset,
			Faceset,
			Gameover,
			Monster,
			Panorama,
			Picture,
			System,
			Title,
			System2,
			Battle2,
			Battlecharset,
			Battleweapon,
			Frame,
			END,
		};

	}; // struct Material

	struct Spec;
	static Spec const specs_[];
	BitmapRef LoadBitmap(Spec const& spec, std::string const& filename);

	template<Material::Type T>
	BitmapRef LoadBitmap(std::string const& f);
};

Cache_& Cache();

#endif
