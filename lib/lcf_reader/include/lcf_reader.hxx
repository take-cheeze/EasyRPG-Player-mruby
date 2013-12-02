#ifndef LCF_READER_HXX
#define LCF_READER_HXX

#include <cstdint>
#include <istream>
#include <vector>
#include <string>

#include <boost/container/flat_map.hpp>
#include <boost/optional.hpp>

#include "lcf_reader_fwd.hxx"
#include "picojson.hxx"

namespace LCF {
	picojson const& get_schema(picojson_string const& name);
	bool has_default(picojson const& sch);

	namespace detail {
		template<class T>
		struct array {
			typedef T value_type;

			array() : base_(0), size_(0) {}
			array(istream_ref const& is, size_t const s)
				: stream_(is), base_(is->tellg()), size_(s)
			{
				assert((s % sizeof(value_type)) == 0);
				stream_->seekg(s, std::istream::cur);
			}

			size_t size() const { return (size_ == 0)? 0 : size_ / sizeof(value_type); }

			void to_vector(vector<value_type>& ret) const {
				stream_->seekg(base_);
				ret.resize(size());
				for(size_t i = 0; i < size(); ++i) {
					value_type v = 0;
					for(size_t j = 0; j < sizeof(T); ++j) {
						v |= (stream_->get() & 0xffU) << (8*j);
					}
					ret[i] = v;
				}
			}

			operator vector<value_type>() const {
				vector<value_type> v;
				to_vector(v);
				return v;
			}

			value_type operator[](size_t const idx) const {
				assert(idx < size());
				value_type ret = 0;
				stream_->seekg(base_ + sizeof(T) * idx);
				for(size_t i = 0; i < sizeof(T); ++i) {
					ret |= (stream_->get() & 0xff) << (8*i);
				}
				return ret;
			}
		private:
			istream_ref stream_;
			size_t base_, size_;
		}; //struct array
	} // namespace detail

	struct event_command {
		uint32_t code;
		size_t nest;
		std::string str;
		vector<int32_t> args;

		void swap(event_command& rhs);
	}; // struct event_command

	struct map_tree : public vector<int32_t> {
		map_tree(std::istream& is);

		int active_node;
	};

	struct ber_array : public vector<int32_t> {
		ber_array(std::istream& is, size_t len);
	};

	struct element {
		element(picojson const& sch, istream_ref const& is, size_t const s);

		bool exists() const { return bool(stream_); }

		template<class T> T get() const { return to<T>(); }

		array1d a1d() const;
		array2d a2d() const;

		int i() const;
		bool b() const;
		double d() const;
		double f() const;
		std::string s() const;
		event e() const;
		int8_array i8a() const;
		int16_array i16a() const;
		int32_array i32a() const;
		map_tree mt() const;
		ber_array ba() const;

		template<class T>
		detail::array<T> ary() { return to<detail::array<T> >(); }

		array1d operator[](uint32_t const k) const;
		element operator[](picojson_string const& k) const;
		element operator[](char const* k) const;

		boost::optional<array1d const&> get(uint32_t const k) const;
		boost::optional<element> get(picojson_string const& k) const;
		boost::optional<element> get(char const* k) const;

		void to_json(picojson& ret) const;
		void write(std::ostream& os) const;

		picojson_string const& type() const;
		picojson const& schema() const;

	  private:
		template<class T> T to() const;
		template<class T> T to_impl() const;
		void check_type(picojson_string const& name) const;

		picojson const* schema_;
		istream_ref stream_;
		size_t base_, size_;
	}; // struct element

	struct array1d : public detail::array1d_base {
		array1d();
		array1d(picojson const& sch, istream_ref const& is);
		array1d(picojson const& sch, istream_ref const& is, int index);
		array1d(array1d const& rhs);

		array1d& operator =(array1d const&);

		element operator[](picojson_string const& k) const;
		element operator[](char const* k) const;
		element operator[](uint32_t const k) const;

		boost::optional<element> get(picojson_string const& k) const;
		boost::optional<element> get(char const* k) const;
		boost::optional<element> get(uint32_t const k) const;

		int index() const;
		bool is_a2d() const;
		bool is_valid() const;

		void to_json(picojson& ret) const;

	private:
		istream_ref stream_;
		size_t base_, size_;
		picojson const* schema_;
		int index_;
	}; // class array1d

	struct array2d : public detail::array2d_base {
		array2d();
		array2d(picojson const& sch, istream_ref const& is);
		array2d(array2d const& rhs);

		array1d const& operator[](uint32_t const k) const;
		boost::optional<array1d const&> get(uint32_t const k) const;

		array2d& operator =(array2d const&);

		void to_json(picojson& ret) const;

	private:
		istream_ref stream_;
		size_t base_, size_;
		picojson const* schema_;
	}; // class array2d

	struct lcf_file {
		lcf_file();
		lcf_file(istream_ref const& is);
		lcf_file(std::string const& file);
		lcf_file(BOOST_RV_REF(lcf_file) rhs);
		~lcf_file();

		element operator[](picojson_string const& n) const;
		element operator[](char const* n) const;
		array1d operator[](uint32_t const idx) const;

		boost::optional<element> get(picojson_string const& n) const;
		boost::optional<element> get(char const* n) const;
		boost::optional<array1d const&> get(uint32_t const idx) const;

		element const& root(size_t index) const;

		void to_json(picojson& ret) const;

		bool valid() const;
		std::string const& error() const { return error_; }

		void swap(lcf_file& x);

	private:
		void init();

		picojson const* schema_;
		istream_ref stream_;
		picojson_string signature_;

		std::string error_;

		vector<element> elem_;
	}; // struct lcf_file

	size_t calculate_size(picojson const& data, picojson const& schema);
	bool save_lcf(picojson const& data, std::ostream& os);
	void save_element(picojson const& data, picojson const& schema, std::ostream& os);
	void save_array1d(picojson const& data, picojson const& schema, std::ostream& os);
	void save_array2d(picojson const& data, picojson const& schema, std::ostream& os);
	picojson const& actual_schema(picojson const& sch, picojson_string const& type);
	picojson const& find_schema(picojson const& sch, uint32_t k);
	picojson const& find_schema(picojson const& sch, picojson_string const& k);

	bool operator==(array1d const& lhs, array1d const& rhs);
	bool operator==(array2d const& lhs, array2d const& rhs);
	inline bool operator!=(array1d const& lhs, array1d const& rhs) {
		return !(lhs == rhs);
	}
	inline bool operator!=(array2d const& lhs, array2d const& rhs) {
		return !(lhs == rhs);
	}

	template<class T>
	picojson to_json(T const& v) {
		picojson ret;
		v.to_json(ret);
		return ret;
	}
} // namespace LCF

#endif
