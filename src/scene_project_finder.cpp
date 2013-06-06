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
			, cursor(0), offset(0)
	{
		assert(not is_project_);
		assert(not path.empty());
	}

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

	bool is_project() {
		FileFinder_& f = FileFinder();
		return *(is_project_ = is_project_? *is_project_ :
				 f.IsRPG2kProject(f.GetDirectoryMembers(
					 fullpath(), FileFinder_::DIRECTORIES).members));
	}

  private:
	EntryList children_;
	Sprite sprite_;
	boost::optional<bool> is_project_;

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
				*this, i->second,
				f.IsRPG2kProject(f.GetDirectoryMembers(
					f.MakePath(dir.base, i->second), FileFinder_::FILES).members))));
		}

		return ret;
	}

	Entry(Entry& p, std::string const& pth, bool const is_proj)
			: parent(p), name(pth + (is_proj? "" : "/")), path(pth)
			, cursor(0), offset(0), is_project_(is_proj)
	{
		assert(is_project_);
		assert(not path.empty());
	}
};

BitmapRef Scene_ProjectFinder::create_bitmap(EntryList const& list) {
	assert(not list.empty());

	size_t const
			font_size_ = Font::Shinonome()->pixel_size(),
			width = font_size_ * COLUMN_MAX;
	BitmapRef const ret = Bitmap::Create(width, font_size_ * list.size());
	ret->font = Font::Shinonome();

	for(EntryList::const_iterator i = list.begin(); i < list.end(); ++i) {
		Font::default_color =
				(*i)->is_project()? Color(255, 0, 0, 255) : Color(0, 0, 0, 255);

		int const y = font_size_ * (i - list.begin());
		ret->draw_text(0, y, (*i)->name);

		// fill with .... if directory name is too long
		if(ret->text_size((*i)->name).width > int(width)) {
			ret->fill(Rect(width - font_size_ * 2, y, font_size_ * 2, font_size_), Color(0, 0, 0, 0));
			ret->draw_text(width - font_size_ * 2, y, "....");
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

void Scene_ProjectFinder::set_index(int const idx) {
	unsigned& dst_idx = current_index();
	unsigned& offset = current_offset();

	dst_idx = (idx + current_children_count()) % current_children_count();
	offset = std::max(0, std::max<int>(
		int(dst_idx) - int(ROW_MAX - 1), std::min(offset, dst_idx)));

	assert(dst_idx < current_children_count());

	cursor_->SetY(font_size_ * (dst_idx - offset + 1) - 1);
	current_sprite().SetSrcRect(Rect(
		0, font_size_ * offset, font_size_ * COLUMN_MAX, font_size_ * ROW_MAX));
}

void Scene_ProjectFinder::select_entry() {
	assert(current_index() < current_children_count());

	current_sprite().visible = false;
	current_entry_ = *(current_entry_? current_entry_->children() : root_)[current_index()];

	if(current_entry_->is_project()) {
		Main_Data::project_path = current_entry_->fullpath();
		Scene::Push(EASYRPG_MAKE_SHARED<Scene_Title>());
		to_parent();
	} else if(current_entry_->children().empty()) {
		to_parent(); // return to parent
	} else {
		current_sprite().SetX(font_size_);
		current_sprite().SetY(font_size_);
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

void Scene_ProjectFinder::Start() {
	font_ = Font::Shinonome();
	font_size_ = font_->pixel_size();

	root_sprite_.reset(new Sprite());
	background_.reset(new Sprite());
	cursor_.reset(new Sprite());

	background_->SetBitmap(Bitmap::Create(SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT, Color(255, 255, 255, 255)));
	background_->SetZ(-1000);

	root_sprite_->SetBitmap(create_bitmap(root_));
	root_sprite_->SetX(font_size_);
	root_sprite_->SetY(font_size_);
	root_sprite_->SetSrcRect(Rect(0, 0, font_size_ * COLUMN_MAX, font_size_ * ROW_MAX));

	BitmapRef const cursor_bmp = Bitmap::Create(font_size_ * COLUMN_MAX + 4, font_size_ + 2);
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
	cursor_->SetX(font_size_ - 2);
	cursor_->SetY(font_size_ - 1);
}

Scene_ProjectFinder::Scene_ProjectFinder()
		: Scene("ProjectFinder")
		, root_index_(0), root_offset_(0)
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
}

void Scene_ProjectFinder::Update() {
	if(Input().IsTriggered(Input_::DECISION) or
	   Input().IsTriggered(Input_::RIGHT)) { select_entry(); }
	else if(Input().IsRepeated(Input_::UP)) { set_index(int(current_index()) - 1); }
	else if(Input().IsRepeated(Input_::DOWN)) { set_index(int(current_index()) + 1); }
	else if(Input().IsTriggered(Input_::CANCEL) or
			Input().IsTriggered(Input_::LEFT)) { to_parent(); }
}

Scene_ProjectFinder::~Scene_ProjectFinder() {}
