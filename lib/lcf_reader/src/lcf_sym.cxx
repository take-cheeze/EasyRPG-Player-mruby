#include "picojson.hxx"
#include "lcf_sym.hxx"

namespace LCF {
namespace sym {
picojson_string index("index"), name("name"),
	value("value"), type("type"),
	signature("signature"), code("code"),
	nest("nest"), string("string"),
	args("args"), root("root"),
	array1d("array1d"), array2d("array2d"),
	integer("integer"), bool_("bool"),
	float_("float"), event("event"),
	map_tree("map_tree"), int8array("int8array"),
	int16array("int16array"), int32array("int32array"),
	ber_array("ber_array"), _rest("_rest");
}
}
