#include "lcf_reader.hxx"
#include "lcf_stream.hxx"
#include "lcf_sym.hxx"
#include "picojson.hxx"

#include <boost/bind.hpp>
#include <boost/container/list.hpp>
#include <boost/make_shared.hpp>
#include <boost/range/algorithm/find.hpp>
#include <boost/range/algorithm/find_if.hpp>
#include <boost/range/algorithm/remove_copy_if.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/variant.hpp>
#include <boost/detail/endian.hpp>
#include <boost/optional.hpp>

#include <algorithm>
#include <fstream>
#include <sstream>
#include <iterator>


extern char const* LCF_SCHEMA_JSON_STRING[];

namespace {
std::ios::openmode const write_flag = std::ios::binary | std::ios::out;
std::ios::openmode const read_flag = std::ios::binary | std::ios::in;

using boost::lexical_cast;
using boost::bind;
using boost::optional;
using boost::ref;

namespace sym = LCF::sym;
}

void LCF::event_command::swap(event_command& e) {
	std::swap(code, e.code);
	std::swap(nest, e.nest);
	str.swap(e.str);
	args.swap(e.args);
}

picojson const& LCF::get_schema(picojson::string const& name) {
	typedef boost::container::flat_map<picojson::string, picojson> cache_type;
	static cache_type cache_;

	if(cache_.empty()) {
		for(char const** src = LCF_SCHEMA_JSON_STRING; *src != NULL; ++src) {
			picojson json;
			char const* src_ = *src;
			std::string const err = picojson::parse(json, src_, src_ + strlen(src_));

			assert(err.empty());

			picojson::string const& key =
					json.contains(sym::signature)? json[sym::signature].s():
					json.contains(sym::name)? json[sym::name].s():
					picojson::string("");

			assert(not name.get().empty());
			assert(cache_.find(key) == cache_.end());

			cache_[key].swap(json);
		}
	}

	cache_type::const_iterator const i = cache_.find(name);
	static picojson const null_;
	return (i != cache_.end())? i->second : null_;
}

bool LCF::has_default(picojson const& sch) {
	picojson::string const& type_name = sch[sym::type].s();
	return sch.contains(sym::value)
			and not sch[sym::value].is<picojson::array>()
			and type_name != sym::array1d
			and type_name != sym::array2d
			;
}

picojson const& LCF::actual_schema(picojson const& sch, picojson::string const& type) {
	picojson const& val = sch[sym::value];
	picojson::string const& type_name = sch[sym::type].s();
	if(val.is<picojson::array>()) {
		assert(type_name == type);
		return sch;
	} else {
		picojson const& t = get_schema(type_name);
		if(not t.is<picojson::null>()) {
			assert(t[sym::type].s() == type);
			return t;
		} else {
			assert(type_name == type);
			picojson const& ret = get_schema(val.s());

			return ret;
		}
	}
}

picojson const& LCF::find_schema(picojson const& sch, uint32_t const k) {
	picojson::array const& ary = sch[sym::value].a();
	for(picojson::array::const_iterator i = ary.begin(); i != ary.end(); ++i) {
		if((*i)[sym::index].i() == int(k)) { return *i; }
	}

	static picojson const null_;
	return null_;
}

picojson const& LCF::find_schema(picojson const& sch, picojson::string const& k) {
	picojson::array const& ary = sch[sym::value].a();
	for(picojson::array::const_iterator i = ary.begin(); i != ary.end(); ++i) {
		if((*i)[sym::name].s() == k) { return *i; }
	}

	static picojson const null_;
	return null_;
}

LCF::array2d::array2d() : base_(0), size_(0), schema_(NULL) {}
LCF::array2d::array2d(array2d const& r)
		: detail::array2d_base(r), stream_(r.stream_)
		, base_(r.base_), size_(r.size_), schema_(r.schema_) {}

LCF::array2d::array2d(picojson const& sch, istream_ref const& is)
		: stream_(is), base_(is->tellg()), size_(0), schema_(&sch)
{
	size_t const elem_num = ber(*stream_);
	reserve(elem_num);

	uint32_t prev_idx = 0;
	for(size_t i = 0; i < elem_num; ++i) {
		uint32_t const idx = ber(*stream_);
		insert(value_type(idx, array1d(*schema_, stream_)));

		// check previous index
		assert(prev_idx <= idx);
		prev_idx = idx;
	}

	size_ = size_t(is->tellg()) - base_;
}

boost::optional<LCF::array1d const&> LCF::array2d::get(uint32_t const k) const {
	const_iterator i = find(k);
	if(i != end()) { return i->second; }
	else { return boost::none; }
}
LCF::array1d const& LCF::array2d::operator[](uint32_t const k) const {
	const_iterator i = find(k);
	assert(i != end());
	return i->second;
}

LCF::array2d& LCF::array2d::operator=(array2d const& rhs) {
	if(this != &rhs) { array2d(rhs).swap(*this); }
	return *this;
}

LCF::array1d::array1d() : base_(0), size_(0), schema_(NULL), index_(0) {}
LCF::array1d::array1d(array1d const& r)
		: detail::array1d_base(r), stream_(r.stream_)
		, base_(r.base_), size_(r.size_)
		, schema_(r.schema_), index_(r.index_) {}

LCF::array1d::array1d(picojson const& sch, istream_ref const& is)
		: stream_(is)
		, base_(is->tellg()), schema_(&sch), index_(0)
{
	picojson::array const& list = sch[sym::value].a();

	reserve(list.size());

	uint32_t prev_idx = 0;

	while(not is_eof(*stream_)) {
		uint32_t const idx = ber(*stream_);
		if(idx == 0) { break; }

		// check previous index
		assert(prev_idx <= idx);
		prev_idx = idx;

		size_t const s = ber(*stream_);
		insert(value_type(idx, element(find_schema(sch, idx), stream_, s)));
		stream_->seekg(s, std::istream::cur);
	}
	size_ = size_t(is->tellg()) - base_;
}

LCF::array1d& LCF::array1d::operator=(array1d const& rhs) {
	if(this != &rhs) { array1d(rhs).swap(*this); }
	return *this;
}

boost::optional<LCF::element> LCF::array1d::get(picojson::string const& k) const {
	picojson const& sch = find_schema(*schema_, picojson::string(k));
	if(sch.is<picojson::null>()) { return boost::none; }
	else { return (*this).get(sch[sym::index].i()); }
}
boost::optional<LCF::element> LCF::array1d::get(char const* k) const {
	return (*this).get(picojson::string(k));
}
boost::optional<LCF::element> LCF::array1d::get(uint32_t const k) const {
	const_iterator const i = find(k);
	if(i != end()) { return i->second; }

	picojson const& sch = find_schema(*schema_, k);
	if(not sch.is<picojson::null>() and has_default(sch))
	{ return element(sch, istream_ref(), 0); }
	else { return boost::none; }
}

LCF::element LCF::array1d::operator[](picojson::string const& k) const {
	return (*this)[find_schema(*schema_, picojson::string(k))[sym::index].i()];
}
LCF::element LCF::array1d::operator[](char const* k) const {
	return (*this)[picojson::string(k)];
}
LCF::element LCF::array1d::operator[](uint32_t const k) const {
	const_iterator const i = find(k);
	if(i != end()) { return i->second; }
	else {
		picojson const& sch = find_schema(*schema_, k);
		assert(has_default(sch));
		return element(sch, istream_ref(), 0);
	}
}

int LCF::array1d::index() const {
	assert(is_a2d());
	return index_;
}
bool LCF::array1d::is_a2d() const {
	return (index_ != 0);
}
bool LCF::array1d::is_valid() const {
	return schema_;
}

LCF::map_tree::map_tree(std::istream& is) : vector<int32_t>(ber(is)) {
	for(vector<int32_t>::iterator i = begin(); i != end(); ++i) { *i = ber(is); }
	active_node = ber(is);
}

LCF::ber_array::ber_array(std::istream& is, size_t const len) {
	size_t const base = is.tellg();
	while(size_t(is.tellg()) < (base + len)) { push_back(ber(is)); }
}

LCF::element::element(picojson const& sch, istream_ref const& is, size_t const s)
		: schema_(&sch), stream_(is), base_(is? size_t(is->tellg()) : 0), size_(s) {}

namespace LCF {

template<>
map_tree element::to_impl<map_tree>() const {
	return map_tree(*stream_);
}

template<>
ber_array element::to_impl<ber_array>() const {
	return ber_array(*stream_, size_);
}

template<>
array1d element::to_impl<array1d>() const {
	return array1d(actual_schema(*schema_, sym::array1d), stream_);
}
template<>
array2d element::to_impl<array2d>() const {
	return array2d(actual_schema(*schema_, sym::array2d), stream_);
}

template<>
int8_array element::to_impl<int8_array>() const {
	return int8_array(stream_, size_);
}
template<>
int16_array element::to_impl<int16_array>() const {
	return int16_array(stream_, size_);
}
template<>
int32_array element::to_impl<int32_array>() const {
	return int32_array(stream_, size_);
}

template<>
int element::to_impl<int>() const {
	check_type(sym::integer);
	return exists()? int32_t(ber(*stream_))
			: (*schema_)[sym::value].i();
}

template<>
bool element::to_impl<bool>() const {
	check_type(sym::bool_);
	return exists()? bool(ber(*stream_))
			: (*schema_)[sym::value].b();
}

template<>
std::string element::to_impl<std::string>() const {
	check_type(sym::string);
	return exists()? read_string(*stream_, size_)
			: schema_->get(sym::value).s();
}

template<>
double element::to_impl<double>() const {
	check_type(sym::float_);
	if(!exists()) { return schema_->get(sym::value).d(); }

	char data[sizeof(double)];
	stream_->read(data, sizeof(double));
#ifdef BOOST_LITTLE_ENDIAN
	// don't do anything
#elif defined BOOST_BIG_ENDIAN
	// swap endianess
	std::swap(data[0], data[7]);
	std::swap(data[1], data[6]);
	std::swap(data[2], data[5]);
	std::swap(data[3], data[4]);
#else
#error unknown endianess
#endif
	return *reinterpret_cast<double*>(data);
}

template<>
event element::to_impl<event>() const {
	check_type(sym::event);

	event ret;
	while(size_t(stream_->tellg()) < (base_ + size_)) {
		ret.resize(ret.size() + 1);
		ret.back().code = ber(*stream_);
		ret.back().nest = ber(*stream_);
		ret.back().str = read_string(*stream_);

		size_t const len = ber(*stream_);
		ret.back().args.reserve(len);
		for(size_t i = 0; i < len; ++i) {
			ret.back().args.push_back(ber(*stream_));
		}
	}
	return ret;
}

}

template<class T>
T LCF::element::to() const {
	if(stream_) { stream_->seekg(base_); }
	T const ret = to_impl<T>();
	if(stream_) { assert(stream_->tellg() == int(base_ + size_)); }
	return ret;
}

LCF::array1d LCF::element::a1d() const { return to<array1d>(); }
LCF::array2d LCF::element::a2d() const { return to<array2d>(); }

int LCF::element::i() const { return to<int>(); }
bool LCF::element::b() const { return to<bool>(); }
double LCF::element::d() const { return to<double>(); }
double LCF::element::f() const { return to<double>(); }
std::string LCF::element::s() const { return to<std::string>(); }
LCF::event LCF::element::e() const { return to<event>(); }
LCF::int8_array LCF::element::i8a() const { return to<int8_array>(); }
LCF::int16_array LCF::element::i16a() const { return to<int16_array>(); }
LCF::int32_array LCF::element::i32a() const { return to<int32_array>(); }
LCF::map_tree LCF::element::mt() const { return to<map_tree>(); }
LCF::ber_array LCF::element::ba() const { return to<ber_array>(); }

LCF::array1d LCF::element::operator[](uint32_t const k) const { return a2d()[k]; }
LCF::element LCF::element::operator[](picojson::string const& k) const { return a1d()[k]; }
LCF::element LCF::element::operator[](char const* k) const { return a1d()[picojson::string(k)]; }

boost::optional<LCF::array1d const&> LCF::element::get(uint32_t const k) const
{ return a2d().get(k); }
boost::optional<LCF::element> LCF::element::get(picojson::string const& k) const
{ return a1d().get(k); }
boost::optional<LCF::element> LCF::element::get(char const* k) const
{ return a1d().get(picojson::string(k)); }

void LCF::element::check_type(picojson::string const& name) const {
	assert(schema_->get(sym::type).s() == name);
}

picojson::string const& LCF::element::type() const {
	return schema_->get(sym::type).s();
}
picojson const& LCF::element::schema() const {
	assert(schema_);
	return *schema_;
}

void LCF::element::write(std::ostream& os) const {
	assert(stream_);
	stream_->seekg(base_);
	vector<char> tmp(size_);
	BOOST_VERIFY(stream_->readsome(tmp.data(), size_) == int(size_));
	os.write(tmp.data(), tmp.size());
}

LCF::lcf_file::lcf_file() : schema_(NULL) {}
LCF::lcf_file::lcf_file(std::string const& file) {
	std::ifstream ifs(file.c_str(), read_flag);
	assert(ifs);

	ifs.seekg(0, std::ios::end);
	vector<char> tmp(ifs.tellg());
	ifs.seekg(0, std::ios::beg);
	ifs.read(tmp.data(), tmp.size());
	stream_ = boost::make_shared<std::istringstream>(
		std::string(tmp.data(), tmp.size()), read_flag);

	init();
}
LCF::lcf_file::lcf_file(istream_ref const& is) : stream_(is) {
	init();
}
LCF::lcf_file::lcf_file(BOOST_RV_REF(lcf_file) rhs) : schema_(NULL) {
	using std::swap;
	swap(schema_, rhs.schema_);
	swap(stream_, rhs.stream_);
	swap(signature_, rhs.signature_);
	swap(error_, rhs.error_);
	swap(elem_, rhs.elem_);
}

void LCF::lcf_file::swap(lcf_file& x) {
	using std::swap;
	swap(schema_, x.schema_);
	swap(stream_, x.stream_);
	swap(signature_, x.signature_);
	swap(error_, x.error_);
	swap(elem_, x.elem_);
}

void LCF::lcf_file::init() {
	signature_ = read_string(*stream_);
	schema_ = &get_schema(signature_);

	picojson::array const& root = (*schema_)[sym::root].a();
	elem_.reserve(root.size());
	for(size_t i = 0; i < root.size(); ++i) {
		size_t const pos = stream_->tellg();

		picojson::string const& type = root[i][sym::type].s();
		if(type == sym::array1d) { (void)array1d(root[i], stream_); }
		else if(type == sym::array2d) { (void)array2d(root[i], stream_); }
		else if(type == sym::map_tree) { (void)map_tree(*stream_); }
		else { assert(false); }

		size_t const size = size_t(stream_->tellg()) - pos;
		stream_->seekg(pos);
		elem_.push_back(element(root[i], stream_, size));
		stream_->seekg(size, std::istream::cur);
	}
	assert(is_eof(*stream_));

	// assert(LCF::to_json(*this).is<picojson::object>());
}

bool LCF::lcf_file::valid() const {
	return(schema_ != NULL && stream_);
}

LCF::lcf_file::~lcf_file() {}

LCF::element const& LCF::lcf_file::root(size_t const index) const {
	return elem_[index];
}

boost::optional<LCF::element> LCF::lcf_file::get(picojson::string const& n) const {
	return root(0).get(n);
}
boost::optional<LCF::element> LCF::lcf_file::get(char const* n) const {
	return root(0).get(picojson::string(n));
}
boost::optional<LCF::array1d const&> LCF::lcf_file::get(uint32_t const idx) const {
	return root(0).get(idx);
}

LCF::element LCF::lcf_file::operator[](picojson::string const& n) const {
	return root(0)[n];
}
LCF::element LCF::lcf_file::operator[](char const* n) const {
	return root(0)[picojson::string(n)];
}
LCF::array1d LCF::lcf_file::operator[](uint32_t const idx) const {
	return root(0)[idx];
}

bool LCF::operator==(LCF::array1d const& lhs, LCF::array1d const& rhs) {
	return to_json(lhs) == to_json(rhs);
}
bool LCF::operator==(LCF::array2d const& lhs, LCF::array2d const& rhs) {
	return to_json(lhs) == to_json(rhs);
}
