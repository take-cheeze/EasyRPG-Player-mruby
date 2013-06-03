#include "scene_project_finder.h"
#include "filefinder.h"
#include "sprite.h"
#include "font.h"
#include "input.h"
#include "bitmap.h"
#include "main_data.h"
#include "scene_title.h"
#include "player.h"

#include <cstdlib>

#include <sstream>
#include <algorithm>

#ifdef _WIN32
#  include "windows.h"
#endif


namespace {
std::string get_home_path() {
	return
			std::getenv("HOME")? std::getenv("HOME"):
			std::getenv("HOMEDRIVE") and std::getenv("HOMEPATH")
			? std::string(std::getenv("HOMEDRIVE")).append(std::getenv("HOMEPATH")):
			std::string() // empty string that means home path not found
			;
}

enum { COLUMN_MAX = 25, ROW_MAX = 18, };
}

struct Scene_ProjectFinder::Entry {
	Entry(std::string const& n, std::string const& p)
			: name(n), path(FileFinder().fullpath(p))
			, cursor(0), offset(0) {}

	std::string fullpath() const {
		return parent
				? FileFinder().MakePath(parent->fullpath(), path)
				: FileFinder().fullpath(path);
	}

	boost::optional<Entry&> parent;
	std::string const name;
	std::string const path;

	unsigned cursor, offset;

	Sprite& sprite() {
		if(not sprite_.GetBitmap()) {
			children_ = create_children();
			sprite_.SetBitmap(children_.empty()
							  ? Bitmap::Create(1, 1) : create_bitmap(children_));

			size_t const font_size = Font::Default()->pixel_size();
			sprite_.SetX(font_size);
			sprite_.SetY(font_size);
			sprite_.visible = false;
		}
		return sprite_;
	}

	EntryList const& children() {
		// assert(not children_.empty());
		sprite();
		return children_;
	}

	static bool no_children(EntryRef const& e) {
		assert(e);
		return e->children_.empty();
	}

  private:
	EntryList children_;
	Sprite sprite_;

	EntryList create_children() {
		typedef FileFinder_::Directory Directory;
		FileFinder_& f = FileFinder();

		EntryList ret;
		Directory const dir = f.GetDirectoryMembers(fullpath(), FileFinder_::DIRECTORIES);

		for(FileFinder_::string_map::const_iterator i = dir.members.begin(); i != dir.members.end(); ++i) {
			Directory const d = f.GetDirectoryMembers(
				f.MakePath(dir.base, i->second), FileFinder_::DIRECTORIES);
			if(d.members.empty()) { continue; }

			ret.push_back(EASYRPG_SHARED_PTR<Entry>(new Entry(
				*this,
				f.IsRPG2kProject(d.members)? i->second : i->second + "/",
				i->second)));
		}

		return ret;
	}

	Entry(Entry& p, std::string const& n, std::string const& pth)
			: parent(p), name(n), path(pth)
			, cursor(0), offset(0) {}
};

BitmapRef Scene_ProjectFinder::create_bitmap(EntryList const& list) {
	assert(not list.empty());

	size_t const
			font_size = Font::Default()->pixel_size(),
			width = font_size * COLUMN_MAX;
	BitmapRef const ret = Bitmap::Create(width, font_size * list.size());

	for(EntryList::const_iterator i = list.begin(); i < list.end(); ++i) {
		Font::default_color =
				FileFinder().IsRPG2kProject(
					FileFinder().GetDirectoryMembers((*i)->fullpath()).members)
				? Color(255, 0, 0, 255) : Color(0, 0, 0, 255);

		int const y = font_size * (i - list.begin());
		ret->draw_text(0, y, (*i)->name);

		// fill with .... if directory name is too long
		if(ret->text_size((*i)->name).width > int(width)) {
			ret->fill(Rect(width - font_size * 2, y, font_size * 2, font_size), Color(0, 0, 0, 0));
			ret->draw_text(width - font_size * 2, y, "....");
		}
	}

	return ret;
}

size_t Scene_ProjectFinder::current_children_count() const {
	return current_entry_? current_entry_->children().size() : root_.size();
}

unsigned& Scene_ProjectFinder::current_index() {
	return current_entry_? current_entry_->cursor : root_index_;
}

unsigned& Scene_ProjectFinder::current_offset() {
	return current_entry_? current_entry_->offset: root_offset_;
}

Sprite& Scene_ProjectFinder::current_sprite() {
	return current_entry_? current_entry_->sprite() : *root_sprite_;
}

void Scene_ProjectFinder::set_index(unsigned const idx) {
	assert(idx < current_children_count());

	unsigned& dst_idx = current_index();
	unsigned& offset = current_offset();

	dst_idx = idx;
	offset = (idx < offset)? idx:
			 (idx >= (offset + ROW_MAX))? std::max(0, int(idx) - int(ROW_MAX - 1)):
			 offset;

	size_t const font_size = Font::Default()->pixel_size();
	cursor_->SetY(font_size * (idx - offset + 1) - 1);
	current_sprite().SetSrcRect(Rect(
		0, font_size * offset, font_size * COLUMN_MAX, font_size * ROW_MAX));
}

void Scene_ProjectFinder::scroll_entry(bool forward) {
	set_index((int(current_index()) + (forward? 1 : -1) + current_children_count())
			  % current_children_count());
}

void Scene_ProjectFinder::select_entry() {
	assert(current_index() < current_children_count());

	current_sprite().visible = false;
	current_entry_ = *(current_entry_? current_entry_->children() : root_)[current_index()];

	if(FileFinder().IsRPG2kProject(
		   FileFinder().GetDirectoryMembers(current_entry_->fullpath()).members))
	{
		Main_Data::project_path = current_entry_->fullpath();
		Scene::Push(EASYRPG_MAKE_SHARED<Scene_Title>());
		current_entry_ = current_entry_->parent;
	} else if(current_entry_->children().empty()) {
		to_parent(); // return to parent
	} else {
		current_sprite().visible = true;
		set_index(current_index());
	}
}

void Scene_ProjectFinder::to_parent() {
	if(current_entry_) {
		current_entry_->sprite().visible = false;
		current_entry_ = current_entry_->parent;

		current_sprite().visible = true;
		set_index(current_index());
	} else {
		Player().exit_flag = true;
	}

}

Scene_ProjectFinder::Scene_ProjectFinder()
		: Scene("ProjectFinder")
		, root_index_(0), root_offset_(0)
		, root_sprite_(new Sprite())
		, background_(new Sprite())
		, cursor_(new Sprite())
{
	std::ostringstream current_path;
	current_path << ". (" << FileFinder().fullpath(".") << ")";
	root_.push_back(EASYRPG_MAKE_SHARED<Entry>(current_path.str(), "."));

	std::string const home = get_home_path();
	if(not home.empty()) {
		std::ostringstream oss;
		oss << "HOME (" << home << ")";
		root_.push_back(EASYRPG_MAKE_SHARED<Entry>(oss.str(), home));
	}

#ifdef _WIN32
	do {
		wchar_t drives[MAX_PATH + 1] = {0};
		if(GetLogicalDriveStringsW(MAX_PATH, drives) == 0) {
			Output::Warning("cannot get drives");
			break;
		}

		wchar_t const* ptr = drives;
		while(not std::wstring(ptr).empty()) {
			std::wstring const d = ptr;
			ptr += d.size() + 1;

			wchar_t buf[MAX_PATH + 1] = {0};
			GetVolumeInformationW(d.c_str(), buf, MAX_PATH, NULL, NULL, NULL, NULL, 0);

			std::string const drive = Utils::FromWideString(d);
			std::string const vol = Utils::FromWideString(buf);

			if(vol.empty()) {
				root_.push_back(EASYRPG_MAKE_SHARED<Entry>(drive, drive));
			} else {
				std::ostringstream oss;
				oss << drive << " (" << vol << ")";
				root_.push_back(EASYRPG_MAKE_SHARED<Entry>(drive, oss.str()));
			}
		}
	} while(false);
#else
	root_.push_back(EASYRPG_MAKE_SHARED<Entry>("root (/)", "/"));
#endif

	root_.resize(root_.end() - std::remove_if(root_.begin(), root_.end(), Entry::no_children));

	size_t const font_size = Font::Default()->pixel_size();

	background_->SetBitmap(Bitmap::Create(SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT, Color(255, 255, 255, 255)));
	background_->SetZ(-1000);

	root_sprite_->SetBitmap(create_bitmap(root_));
	root_sprite_->SetX(font_size);
	root_sprite_->SetY(font_size);
	root_sprite_->SetSrcRect(Rect(0, 0, font_size * COLUMN_MAX, font_size * ROW_MAX));

	BitmapRef const cursor_bmp = Bitmap::Create(font_size * COLUMN_MAX + 4, font_size + 2);
	Color const blue(0, 0, 255, 255);
	// top
	cursor_bmp->fill(Rect(0, 0, cursor_bmp->width(), 1), blue);
	// left
	cursor_bmp->fill(Rect(0, 0, 1, cursor_bmp->height()), blue);
	// right
	cursor_bmp->fill(Rect(cursor_bmp->width() - 1, 0, 1, cursor_bmp->height()), blue);
	// bottom
	cursor_bmp->fill(Rect(0, cursor_bmp->height() - 1, cursor_bmp->width(), 1), blue);

	cursor_->SetBitmap(cursor_bmp);
	cursor_->SetX(font_size - 2);
	cursor_->SetY(font_size - 1);
}

void Scene_ProjectFinder::Continue() {
	current_sprite().visible = true;
}

void Scene_ProjectFinder::Update() {
	if(Input().IsTriggered(Input_::DECISION) or
	   Input().IsTriggered(Input_::RIGHT)) { select_entry(); }
	else if(Input().IsRepeated(Input_::UP)) { scroll_entry(false); }
	else if(Input().IsRepeated(Input_::DOWN)) { scroll_entry(true); }
	else if(Input().IsTriggered(Input_::CANCEL) or
			Input().IsTriggered(Input_::LEFT)) { to_parent(); }
}

Scene_ProjectFinder::~Scene_ProjectFinder() {}
