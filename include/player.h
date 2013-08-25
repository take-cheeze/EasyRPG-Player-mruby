#ifndef EASYRPG_PLAYER_H
#define EASYRPG_PLAYER_H

#include <mruby.h>
#include <string>

namespace Player {

mrb_state* create_vm();
mrb_state* current_vm();
void make_current(mrb_state* M);
void parse_args(int argc, char* argv[], mrb_state* M = NULL);
void parse_args(mrb_value const& args, mrb_state* M = NULL);

bool exit_flag(mrb_state* M = NULL);
void exit_flag(bool v, mrb_state* M = NULL);

bool reset_flag(mrb_state* M = NULL);
void reset_flag(bool v, mrb_state* M = NULL);

bool window_flag(mrb_state* M = NULL);

void pause(mrb_state* M = NULL);
void resume(mrb_state* M = NULL);
void update(mrb_state* M = NULL);
void run(mrb_state* M = NULL);

bool is_rpg2k(mrb_state* M = NULL);
bool is_rpg2k3(mrb_state* M = NULL);

std::string system_graphic(mrb_state* M = NULL);

}

#endif
