#include "filefinder.h"
#include "player.h"
#include <cstdlib>
#include <ciso646>

namespace {
void CheckIsRPG2kProject() {
	EASYRPG_SHARED_PTR<FileFinder_::ProjectTree> const
			tree = FileFinder().CreateProjectTree(".");
	assert(FileFinder().IsRPG2kProject(*tree));
}

void CheckIsDirectory() {
	assert(FileFinder().IsDirectory("."));
}

void CheckEnglishFilename() {
	assert(not FileFinder().FindImage("Backdrop", "castle").empty());
}
}

int main(int argc, char** argv) {
	PlayerRef const player = CreatePlayer();
	player->ParseArgs(argc, argv);

	CheckIsDirectory();
	CheckIsRPG2kProject();
	CheckEnglishFilename();

	return EXIT_SUCCESS;
}
