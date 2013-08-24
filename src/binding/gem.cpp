#include "binding.hxx"

extern "C" void mrb_EasyRPG_Player_gem_init(mrb_state* M) {
	EasyRPG::register_audio(M);
	EasyRPG::register_bitmap(M);
	EasyRPG::register_cache(M);
	EasyRPG::register_color(M);
	EasyRPG::register_filefinder(M);
	EasyRPG::register_graphics(M);
	EasyRPG::register_image_io(M);
	EasyRPG::register_input(M);
	EasyRPG::register_keys(M);
	EasyRPG::register_output(M);
	EasyRPG::register_plane(M);
	EasyRPG::register_rect(M);
	EasyRPG::register_sprite(M);
	EasyRPG::register_text(M);
	EasyRPG::register_tilemap(M);
	EasyRPG::register_tone(M);
	EasyRPG::register_utils(M);
	EasyRPG::register_window(M);
}

extern "C" void mrb_EasyRPG_Player_gem_final(mrb_state*) {}
