#include "lcf_reader.hxx"
#include "lcf_stream.hxx"

#include <fstream>
#include <sstream>
#include <memory>
#include <cstdlib>

#include <boost/assign/list_of.hpp>
#include <boost/variant.hpp>

#include "binding.hxx"


namespace {

using boost::assign::list_of;

std::ios::openmode const stream_flag =
		std::ios::binary | std::ios::out | std::ios::in;

std::string const ldb_path =
		std::string(getenv("RPG_TEST_GAME_PATH"))
		.append("/").append("RPG_RT.ldb");
std::string const lmt_path =
		std::string(getenv("RPG_TEST_GAME_PATH"))
		.append("/").append("RPG_RT.lmt");

void open_lmt(mrb_state* M) {
	LCF::lcf_file lmt(lmt_path);

	picojson tmp;
	lmt.to_json(tmp);

	std::shared_ptr<std::stringstream> const ios =
			std::make_shared<std::stringstream>(stream_flag);
	bool const result = LCF::save_lcf(tmp, *ios);
	easyrpg_verify(result);
	ios->seekg(0);

	easyrpg_verify(tmp == to_json(LCF::lcf_file(ios)));
}

/*
void open_ldb(mrb_state* M) {
	LCF::lcf_file ldb(ldb_path);

	picojson tmp;
	ldb.to_json(tmp);

	std::shared_ptr<std::stringstream> const ios =
			std::make_shared<std::stringstream>(stream_flag);
	bool const result = LCF::save_lcf(tmp, *ios);
	easyrpg_verify(result);
	ios->seekg(0);

	easyrpg_verify(tmp == to_json(LCF::lcf_file(ios)));
}
*/

void test_ber(mrb_state* M) {
	easyrpg_verify(LCF::ber_size(0) == 1);
	easyrpg_verify(LCF::ber_size(0x81) == 2);

	std::srand(std::time(0));

	std::stringstream ss;
	for(size_t i = 0; i < 100; ++i) {
		ss.str("");
		uint32_t const r = std::rand();
		LCF::ber(ss, r);
		ss.seekg(0);
		easyrpg_verify(LCF::ber(ss) == r);
	}
}

}

extern "C" void mrb_lcf_reader_gem_test(mrb_state* M) {
	test_ber(M);
	open_lmt(M);
	// open_ldb(M);
}
