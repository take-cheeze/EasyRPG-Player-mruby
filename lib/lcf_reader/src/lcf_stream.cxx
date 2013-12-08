#include <iconv.h>
#include <istream>
#include <memory>
#include <sstream>

#include <boost/assert.hpp>
#include <boost/type_traits/remove_pointer.hpp>
#include <boost/type_traits/function_traits.hpp>
#include <boost/noncopyable.hpp>
#include <boost/container/vector.hpp>

#include "lcf_stream.hxx"
#include "lcf_reader_fwd.hxx"

bool LCF::is_eof(std::istream& is) {
	bool const ret = (is.get() == EOF);
	is.unget();
	is.clear();
	return ret;
}

uint32_t LCF::ber(std::istream& is) {
	uint32_t ret = 0;
	int cur = 0;

	do {
		cur = is.get();
		ret = (ret << 7) | (cur & 0x7fU);
	} while((cur & 0x80U) != 0);

	return ret;
}

static size_t const BER_MAX = sizeof(uint32_t)*8 / 7 + 1;

size_t LCF::ber_size(uint32_t v) {
	size_t ret = 1;
	while((v >>= 7) != 0) { ++ret; }
	assert(ret <= BER_MAX);
	return ret;
}
std::ostream& LCF::ber(std::ostream& os, uint32_t const v) {
	size_t const s = ber_size(v);

	char data[BER_MAX];
	data[s - 1] = v & 0x7fU;
	for(size_t i = s - 1; i > 0; --i) {
		data[i - 1] = ((v >> (7*(s - i))) & 0x7fU) | 0x80U;
	}
	return os.write(data, s);
}

namespace {

template<class F>
static std::string run_iconv(std::string const& target, F func, iconv_t const h) {
	size_t src_left = target.size();
	boost::container::vector<char> dst_buf(target.size() * 5 + 10);
	size_t dst_left = dst_buf.size();

	typedef typename boost::remove_pointer<
		typename boost::function_traits<
			typename boost::remove_pointer<F>::type
			>::arg2_type
		>::type src_type;
	src_type src = (src_type)target.c_str();
	char *dst = dst_buf.data();

	if(func(h, &src, &src_left, &dst, &dst_left) == (size_t)-1) {
		std::cout << target << std::endl;
		assert(false);
	}
	assert(src_left == 0);

	return std::string(dst_buf.data(), dst);
}

struct iconv_wrap : boost::noncopyable {
	iconv_wrap(char const* to, char const* from);
	~iconv_wrap();

	std::string operator()(std::string const& str) const;
  private:
	iconv_t handle_;
}; // struct iconv_wrap

std::string iconv_wrap::operator()(std::string const& str) const {
	return run_iconv(str, ::iconv, handle_);
}

iconv_wrap::iconv_wrap(char const* to, char const* from) {
	BOOST_VERIFY((handle_ = iconv_open(to, from)) != (iconv_t)-1);
}
iconv_wrap::~iconv_wrap() {
	BOOST_VERIFY(iconv_close(handle_) == 0);
}

char const LCF_ENCODING[] = "UTF-8";

std::unique_ptr<::iconv_wrap> convert_to_sys(new iconv_wrap("CP932", LCF_ENCODING));
std::unique_ptr<::iconv_wrap> convert_to_lcf(new iconv_wrap(LCF_ENCODING, "CP932"));

}

void LCF::set_codepage(unsigned cp) {
	std::ostringstream oss("CP");
	oss << cp;
	std::string const cp_name = oss.str();
	convert_to_sys.reset(new iconv_wrap(cp_name.c_str(), LCF_ENCODING));
	convert_to_lcf.reset(new iconv_wrap(LCF_ENCODING, cp_name.c_str()));
}

std::string LCF::read_string(std::istream& is, size_t const s) {
	vector<char> ret(s);
	is.read(ret.data(), ret.size());
	return (*convert_to_lcf)(std::string(ret.begin(), ret.end()));
}

std::string LCF::read_string(std::istream& is) {
	return read_string(is, ber(is));
}

std::string LCF::convert(std::string const& data, char const* to, char const* from) {
	return ::iconv_wrap(to, from)(data);
}

void LCF::write_string(std::ostream& os, std::string const& str) {
	std::string const sjis = (*convert_to_sys)(str);
	ber(os, sjis.size());
	os.write(sjis.c_str(), sjis.size());
}

void LCF::write_string_without_size(std::ostream& os, std::string const& str) {
	std::string const sjis = (*convert_to_sys)(str);
	os.write(sjis.c_str(), sjis.size());
}

size_t LCF::writing_string_size(std::string const& str) {
	return (*convert_to_sys)(str).size();
}
