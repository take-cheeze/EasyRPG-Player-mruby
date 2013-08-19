#ifndef LCF_SYM_HXX
#define LCF_SYM_HXX

#include "picojson_fwd.hxx"

namespace LCF {
namespace sym {
extern picojson_string
	index, name, value, type,
	signature, code, nest, string,
	args, root, array1d, array2d,
	integer, bool_, float_, event,
	map_tree, int8array, int16array, int32array,
	ber_array, _rest;
}
}

#endif
