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

#include <cstdint>
#include <cassert>
#include <cctype>
#include <ciso646>
#include <cstdlib>

#include <algorithm>
#include <fstream>
#include <vector>
#include <functional>

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
typedef std::function<bool(std::string const&, std::string const&, section_value&& val)> value_hooker;

namespace spirit = boost::spirit;
namespace qi = spirit::qi;
namespace phoenix = boost::phoenix;


struct parse_registry {
	std::string line;
	unsigned line_number;
	std::string::const_iterator i, end;
	std::istream& stream;
	qi::symbols<char, char> escape;
	qi::uint_parser<uint16_t, 8, 1, 3> octal;
	qi::uint_parser<uint16_t, 16, 1, 4> hex;
	qi::uint_parser<uint8_t, 16, 2, 2> octet;
	qi::uint_parser<uint32_t, 16, 8, 8> dword;

	void error(format const& fmt) {
		if(line_number > 0) {
			Output().Warning(
				boost::format("Wine registry error: %s, line %d: \"%s\"")
				% fmt.str() % line_number % line);
		} else {
			Output().Warning(boost::format("Wine registry error: %s") % fmt.str());
		}
	}

	std::istream& getline() {
		line.clear();
		do {
			if(not line.empty() and line.back() == '\\') { line.pop_back(); }
			std::string tmp;
			std::getline(stream, tmp);
			++line_number;
			if(line.empty()) { tmp.swap(line); }
			else { line.append(tmp); }
		} while(stream and not line.empty() and line.back() == '\\');

		if(not line.empty()) { assert(line.back() != '\\'); }
		line.erase(std::remove(line.begin(), line.end(), '\r'), line.end());
		i = line.begin(), end = line.end();

		return stream;
	}

	template<char term> std::string parse_str() {
		using qi::phrase_parse;

		std::string ret;
		if(not phrase_parse(
			   i, end, *(escape | ~qi::char_(term)) >> term, ~qi::char_, ret)) {
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

		if(not phrase_parse(
			   escaping, escaping_end,
			   *(('\\' >> (('x' >> hex) | octal)) | qi::char_),
			   ~qi::char_, escaped) or escaping != utf16.end()) {
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
		using spirit::ascii::space;
		using phoenix::push_back;

		enum { STRING, BINARY, INTEGER };
		static struct prefix {
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
					if(not phrase_parse(i, end, -("(" >> qi::uint_ >> ")") >> ":" >>
										octet[push_back(phoenix::ref(ret), _1)] % ',' >>
										-qi::char_(')'), space)) {
						error(format("cannot parse %s") % pre->pre);
					}
					return ret;
				}
				case INTEGER: {
					uint32_t ret;
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

	// break parsing when hook returned true
	parse_registry(std::istream& strm, value_hooker const& hook, bool const is_wine_registry)
			: line_number(0) , stream(strm)
	{
		// init escape
		escape.add
				("\\a", '\a')("\\b", '\b')("\\e", '\e')("\\f", '\f')
				("\\n", '\n')("\\r", '\r')("\\t", '\t')("\\v", '\v')
				("\\\\", '\\')("\\\"", '"');

		if(is_wine_registry) {
			getline();
			if(line != "WINE REGISTRY Version 2") {
				error(format("file signature error"));
				return;
			}
		}

		std::string current_section;

		while(getline()) {
			skip_space();
			if(i >= line.end()) { continue; } // empty line

			switch(*i) {
				case '[':
					++i; // skip '['
					parse_str<']'>().swap(current_section);
					break;
				case '@': break; // skip
				case '\"': {
					if(current_section.empty()) {
						error(format("value without key"));
						return;
					}
					++i; // skip '\"'
					std::string const var_name = parse_str<'\"'>();
					skip_space();
					if(i >= line.end() or *i != '=') {
						error(format("unexpected char or end of line"));
						return;
					}
					assert(*i == '=');
					++i; // skip '='
					skip_space();
					if(hook(current_section, var_name, parse_value())) { return; }
				} break;
				case '#': break; // skip
				case ';': break; // comment line

				default:
					if(not is_wine_registry and std::isalpha(*i)) {
						if(current_section.empty()) {
							error(format("value without key"));
							return;
						}
						if(hook(current_section, parse_str<'='>(),
								std::string(i, line.cend()))) { return; }
						break;
					} else {
						error(format("invalid line"));
						return;
					}
			}
		}
	}
};

struct section_list_creater : public section_list {
	bool operator()(std::string const& section, std::string const& var, section_value const& v) {
		(*this)[section][var] = v;
		return false;
	}
};

struct section_finder {
	boost::optional<section_value> result;

	std::string const section, variable;
	section_finder(std::string const& s, std::string const& v)
			: section(s), variable(v) {}

	bool operator()(std::string const& s, std::string const& var, section_value const& val) {
		if(s == section and var == variable) {
			result = val;
			return true;
		}
		return false;
	}
};

std::string get_registry_filename(HKEY key) {
	std::string prefix = get_wine_prefix();

	if(prefix.empty() or not FileFinder().Exists(prefix)) {
		Output().Debug(boost::format("wine prefix not found: \"%s\"") % prefix);
		return std::string();
	}

	switch(key) {
		case HKEY_LOCAL_MACHINE: return prefix.append("/system.reg");
		case HKEY_CURRENT_USER: return prefix.append("/user.reg");
		default: assert(false); return std::string();
	}
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

template<class T>
T get_value_with_type(std::string const& file, std::string const& key, std::string const& var, bool is_wine_registry) {
	static T const err_val;

	std::ifstream ifs(file, std::ios::binary | std::ios::in);
	if(not ifs) {
		Output().Debug(boost::format("registry file open error: %s") % file);
		return err_val;
	}

	section_finder finder(key, var);
	parse_registry(ifs, std::ref(finder), is_wine_registry);
	if(finder.result == boost::none) {
		Output().Debug(boost::format("registry not found: %s, %s") % key % var);
		return err_val;
	}

	if(T* ret = boost::get<T>(&*finder.result)) { return *ret; }
	else {
		Output().Debug(boost::format("type mismatch: %s, %s") % key % var);
		return err_val;
	}
}
}

std::string Registry::ReadStrValue(HKEY hkey, std::string const& key, std::string const& var) {
	std::string const ret = get_value_with_type<std::string>(
		get_registry_filename(hkey), key, var, true);
	if(not is_wine_path(ret)) { return ret; }

	std::string const path = from_wine_path(ret);
	Output().Debug(boost::format("Path registry %s, %s: \"%s\"") % key % var % path);
	return path;
}
int Registry::ReadBinValue(HKEY hkey, std::string const& key, std::string const& var, unsigned char* out) {
	binary_type const bin = get_value_with_type<binary_type>(
		get_registry_filename(hkey), key, var, true);
	std::copy(bin.begin(), bin.end(), out);
	return bin.size();
}

std::string Registry::ReadStrValue(
	std::string const& file, std::string const& key, std::string const& var)
{
	if(not FileFinder().Exists(file)) { return std::string(); }

	std::string const ret = get_value_with_type<std::string>(file, key, var, false);
	return is_wine_path(ret)? from_wine_path(ret) : ret;
}
