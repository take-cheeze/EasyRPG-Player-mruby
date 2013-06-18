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

#include "registry.h"
#include "output.h"
#include "filefinder.h"

#include <stdint.h>
#include <cassert>
#include <cctype>
#include <ciso646>
#include <cstdlib>

#include <algorithm>
#include <fstream>
#include <vector>

#include <boost/variant.hpp>
#include <boost/container/flat_map.hpp>
#include <boost/container/vector.hpp>
#include <boost/optional.hpp>
#include <boost/regex/pending/unicode_iterator.hpp>
#include <boost/format.hpp>

#include <boost/spirit/include/qi_action.hpp>
#include <boost/spirit/include/qi_parse.hpp>
#include <boost/spirit/include/qi_operator.hpp>
#include <boost/spirit/include/qi_char.hpp>
#include <boost/spirit/include/qi_symbols.hpp>
#include <boost/spirit/include/qi_uint.hpp>
#include <boost/spirit/include/support_ascii.hpp>
#include <boost/spirit/include/phoenix_core.hpp>
#include <boost/spirit/include/phoenix_bind.hpp>
#include <boost/spirit/include/phoenix_operator.hpp>
#include <boost/spirit/include/phoenix_stl.hpp>

namespace {
std::string get_wine_prefix() {
	return
			getenv("WINEPREFIX")? getenv("WINEPREFIX"):
			getenv("HOME")? std::string(getenv("HOME")).append("/.wine"):
			std::string();
}

using boost::container::vector;
using boost::format;

typedef vector<uint8_t> binary_type;
typedef boost::variant<std::string, binary_type, uint32_t> section_value;
typedef boost::container::flat_map<std::string, section_value> section;
typedef boost::container::flat_map<std::string, section> section_list;

namespace spirit = boost::spirit;
namespace qi = spirit::qi;
namespace phoenix = boost::phoenix;


struct parse_registry {
	std::string line;
	unsigned line_number;
	section_list result;
	std::string::const_iterator i, end;
	std::ifstream stream;

	void error(format const& fmt) {
		if(line_number > 0) {
			Output().Warning(
				boost::format("Wine registry error: %s\nline %d: \"%s\"")
				% fmt.str() % line_number % line);
		} else {
			Output().Warning(boost::format("Wine registry error: %s") % fmt.str());
		}
	}

	std::istream& getline() {
		line.clear();
		std::string tmp;
		do {
			if(not line.empty() and *line.rbegin() == '\\')
			{ line.resize(line.size() - 1); }
			std::getline(stream, tmp);
			++line_number;
			line += tmp;
		} while(stream and not tmp.empty() and *tmp.rbegin() == '\\');

		if(not line.empty()) { assert(*line.rbegin() != '\\'); }
		line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
		i = line.begin(), end = line.end();

		return stream;
	}

	template<char term> std::string parse_str() {
		using qi::phrase_parse;
		using qi::char_;
		using qi::symbols;
		using qi::uint_parser;

		symbols<char, char> escape;
		escape.add
				("\\a", '\a')("\\b", '\b')("\\e", '\e')("\\f", '\f')
				("\\n", '\n')("\\r", '\r')("\\t", '\t')("\\v", '\v')
				("\\\\", '\\')("\\\"", '"');

		std::string ret;
		if(not phrase_parse(
			   i, end, *(escape | ~char_(term)) >> term, ~char_, ret)) {

			error(format("string parse error"));
			return std::string();
		}

		typedef boost::u8_to_u32_iterator<std::string::const_iterator> u8_to_u32;
		typedef boost::u32_to_u16_iterator<vector<uint32_t>::const_iterator> u32_to_u16;
		typedef boost::u16_to_u32_iterator<vector<uint16_t>::const_iterator> u16_to_u32;
		typedef boost::u32_to_u8_iterator<vector<uint32_t>::const_iterator> u32_to_u8;

		// utf-8 -> utf-16
		vector<uint32_t> utf32(
			u8_to_u32(ret.begin(), ret.begin(), ret.end()),
			u8_to_u32(ret.end(), ret.begin(), ret.end()));
		vector<uint16_t> utf16(u32_to_u16(utf32.begin()), u32_to_u16(utf32.end()));

		vector<uint16_t> escaped;
		escaped.reserve(utf16.size());
		vector<uint16_t>::const_iterator
				escaping = utf16.begin(), escaping_end = utf16.end();
		uint_parser<uint16_t, 8, 1, 3> octal;
		uint_parser<uint16_t, 16, 1, 4> hex;

		if(not phrase_parse(
			   escaping, escaping_end,
			   *(('\\' >> (('x' >> hex) | octal)) | char_),
			   ~char_, escaped) or escaping != utf16.end()) {
			Output().Debug("unicode escaping error");
		}

		// utf-16 -> utf-8
		utf32.assign(u16_to_u32(escaped.begin(), escaped.begin(), escaped.end()),
					 u16_to_u32(escaped.end(), escaped.begin(), escaped.end()));
		ret.assign(u32_to_u8(utf32.begin()), u32_to_u8(utf32.end()));

		return ret;
	}

	section_value parse_value() {
		using qi::phrase_parse;
		using qi::_1;
		using qi::uint_parser;
		using qi::char_;
		using qi::uint_;
		using spirit::ascii::space;
		using phoenix::push_back;

		enum { STRING, BINARY, INTEGER };
		struct prefix {
			std::string pre;
			int type;
		} const prefixes[] = {
			{ "\"", STRING },
			{ "str:\"", STRING },
			{ "str(2):\"", STRING },
			{ "str(7):\"", STRING },
			{ "hex", BINARY },
			{ "dword:", INTEGER },
			{ "", -1 },
		};

		for(prefix const* pre = prefixes; not pre->pre.empty(); ++pre) {
			if(size_t(i - end) < pre->pre.size()) { continue; }

			if(not std::equal(i, i + pre->pre.size(), pre->pre.begin())) { continue; }

			i += pre->pre.size();
			switch(pre->type) {
				case STRING:
					return (*i == '\'')? std::string() : parse_str<'\"'>();
				case BINARY: {
					binary_type ret;
					uint_parser<uint8_t, 16, 2, 2> octed;
					if(not phrase_parse(i, end, -("(" >> uint_ >> ")") >> ":" >>
										octed[push_back(phoenix::ref(ret), _1)] % ',' >>
										-char_(')'), space)) {
						error(format("cannot parse %s") % pre->pre);
					}
					return ret;
				}
				case INTEGER: {
					uint32_t ret;
					uint_parser<uint32_t, 16, 8, 8> dword;
					if(not phrase_parse(i, end, dword, space, ret)) {
						error(format("cannot parse %s") % pre->pre);
					}
					return ret;
				}
				default: assert(false);
			}
		}

		return std::string();
	}

	void skip_space() {
		while(i < end and std::isspace(*i)) { ++i; }
	}

	parse_registry(std::string const& name, bool const is_wine_registry = true)
			: line_number(0)
			, stream(name.c_str(), std::ios_base::binary | std::ios_base::in)
	{
		if(not stream) {
			error(format("file open error: \"%s\"") % name);
			return;
		}

		if(is_wine_registry) {
			getline();
			if(line != "WINE REGISTRY Version 2") {
				error(format("file signature error"));
				return;
			}
		}

		section current_section;
		std::string current_section_name;

		while(getline()) {
			skip_space();
			if(i >= line.end()) { continue; } // empty line

			switch(*i) {
				case '[':
					if(not current_section_name.empty()) {
						assert(result.find(current_section_name) == result.end());
						result[current_section_name].swap(current_section);
					}
					++i; // skip '['
					parse_str<']'>().swap(current_section_name);
					break;
				case '@': break; // skip
				case '\"': {
					if(current_section_name.empty()) {
						error(format("value without key"));
						return;
					}
					++i; // skip '\"'
					std::string const val_name = parse_str<'\"'>();
					skip_space();
					if(i >= line.end() or *i != '=') {
						error(format("unexpected char or end of line"));
						return;
					}
					assert(*i == '=');
					++i; // skip '='
					skip_space();
					parse_value().swap(current_section[val_name]);
				} break;
				case '#': break; // skip
				case ';': break; // comment line

				default:
					if(not is_wine_registry and std::isalpha(*i)) {
						if(current_section_name.empty()) {
							error(format("value without key"));
							return;
						}
						current_section[parse_str<'='>()] =
								std::string(i, static_cast<std::string const&>(line).end());
						break;
					} else {
						error(format("invalid line"));
						return;
					}
			}
		}
		current_section.swap(result[current_section_name]);
	}
};

section_list const& get_section(HKEY key) {
	static section_list const empty_sec;
	static section_list local_machine, current_user;

	std::string const prefix = get_wine_prefix();

	if(prefix.empty() or not FileFinder().Exists(prefix)) {
		Output().Debug(boost::format("wine prefix not found: \"%s\"") % prefix);
		return empty_sec;
	}

	switch(key) {
		case HKEY_LOCAL_MACHINE:
			if(local_machine.empty()) {
				parse_registry(prefix + "/system.reg").result.swap(local_machine);
			}
			return local_machine;
		case HKEY_CURRENT_USER:
			if(current_user.empty()) {
				parse_registry(prefix + "/user.reg").result.swap(current_user);
			}
			return current_user;
		default: assert(false); return empty_sec;
	}
}

typedef boost::optional<section_value const&> section_value_opt;
section_value_opt get_value(section_list const& sec, std::string const& key, std::string const& val) {
	section_list::const_iterator sec_list_i = sec.find(key);
	if(sec_list_i == sec.end()) { return boost::none; }
	section::const_iterator sec_i = sec_list_i->second.find(val);
	if(sec_i == sec_list_i->second.end()) { return boost::none; }
	return section_value_opt(sec_i->second);
}
template<class T>
T const& get_value_with_type(HKEY hkey, std::string const& key, std::string const& val) {
	static T const err_val;
	section_value_opt const v = get_value(get_section(hkey), key, val);
	if(v == boost::none) {
		Output().Debug(boost::format("registry not found: %s, %s") % key % val);
		return err_val;
	}
	if(not boost::get<T>(&*v)) {
		Output().Debug(boost::format("type mismatch: %s, %s") % key % val);
		return err_val;
	}
	return boost::get<T const>(*v);
}

bool is_wine_path(std::string const& p) {
	return (p.size() >= 3 and std::isupper(*p.begin()) and
			std::string(p.c_str() + 1, 2) == ":\\");
}

std::string from_wine_path(std::string const& p) {
	std::string ret;
	char const drive = std::tolower(*p.begin());
	switch(drive) {
		default:
			ret.assign(get_wine_prefix()).append("/drive_")
					.append(&drive, 1).append(p.begin() + 2, p.end());
			break;
		case 'z':
			ret.assign(p.begin() + 2, p.end());
			break;
	}
	std::replace(ret.begin(), ret.end(), '\\', '/');

	return ret;
}
}

std::string Registry::ReadStrValue(HKEY hkey, std::string const& key, std::string const& val) {
	std::string const ret = get_value_with_type<std::string>(hkey, key, val);
	if(not is_wine_path(ret)) { return ret; }

	std::string const path = from_wine_path(ret);
	Output().Debug(boost::format("Path registry %s, %s: \"%s\"") % key % val % path);
	return path;
}
int Registry::ReadBinValue(HKEY hkey, std::string const& key, std::string const& val, unsigned char* out) {
	binary_type const bin = get_value_with_type<binary_type>(hkey, key, val);
	std::copy(bin.begin(), bin.end(), out);
	return bin.size();
}

std::string Registry::ReadStrValue(
	std::string const& file, std::string const& section, std::string const& key)
{
	if(not FileFinder().Exists(file)) { return std::string(); }

	std::string const ret = boost::get<std::string>(
		parse_registry(file, false).result[section][key]);
	return is_wine_path(ret)? from_wine_path(ret) : ret;
}
