#ifndef EASYRPG_TINY_READER_FWD
#define EASYRPG_TINY_READER_FWD

#include "picojson_fwd.hxx"

#include <boost/shared_ptr.hpp>
#include <boost/container/container_fwd.hpp>
#include <boost/variant/variant_fwd.hpp>

#include <stdint.h>


namespace LCF {

	typedef boost::shared_ptr<std::istream> istream_ref;
	using boost::container::vector;

	struct event_command;
	typedef vector<event_command> event;
	struct element;
	struct array1d;
	struct array2d;
	struct change;
	struct lcf_file;

	namespace detail {
		template<class T> struct array;

		typedef boost::container::flat_map<uint32_t, element> array1d_base;
		typedef boost::container::flat_multimap<uint32_t, array1d> array2d_base;
	} // namespace detail

	typedef detail::array<uint8_t> int8_array;
	typedef detail::array<int16_t> int16_array;
	typedef detail::array<int32_t> int32_array;

} // namespace lcf_reader

#endif // EASYRPG_TINY_READER_FWD
