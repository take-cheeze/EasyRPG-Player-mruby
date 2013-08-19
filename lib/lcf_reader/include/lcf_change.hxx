#ifndef LCF_CHANGE_HXX
#define LCF_CHANGE_HXX

#include "lcf_reader_fwd.hxx"
#include "picojson.hxx"


namespace LCF {
	struct change {
		key_list key;
		picojson value;

		change(key_list const& k, picojson const& v);
	};
}

#endif
