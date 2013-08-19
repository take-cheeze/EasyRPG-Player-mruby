#ifndef picojson_fwd_h
#define picojson_fwd_h

#include <string>

#include <boost/container/container_fwd.hpp>
#include <boost/flyweight/flyweight_fwd.hpp>
#include <boost/flyweight/no_locking.hpp>

class picojson;

typedef boost::flyweights::flyweight<std::string, boost::flyweights::no_locking> picojson_object_key;
typedef picojson_object_key picojson_string;
typedef boost::container::vector<picojson> picojson_array;
typedef boost::container::flat_map<picojson_object_key, picojson> picojson_object;

#endif
