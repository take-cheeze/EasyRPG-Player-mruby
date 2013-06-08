#ifndef _SCENE_PROJECT_FINDER_H_
#define _SCENE_PROJECT_FINDER_H_

#include "scene.h"
#include "memory_management.h"

#include <vector>

#include <boost/optional.hpp>
#include <boost/scoped_ptr.hpp>


class Sprite;

struct Scene_ProjectFinder : public Scene {
	Scene_ProjectFinder();
	~Scene_ProjectFinder();

	void Start();
	void Update();

  private:
	struct Entry;
	typedef EASYRPG_SHARED_PTR<Entry> EntryRef;
	typedef std::vector<EntryRef> EntryList;
	EntryList root_;

	boost::optional<Entry&> current_entry_;
	unsigned root_index_, root_offset_;

	boost::scoped_ptr<Sprite> root_sprite_, background_, cursor_;

	size_t font_size_;
	FontRef font_;

	boost::optional<std::string> get_app_path(std::string const& exec) const;
	void register_project_base_path(
		std::string const& app_path, std::string const& ini, std::string const& section);

  private:
	void set_index(int idx);
	void select_entry();
	void to_parent();

	size_t current_children_count() const;
	unsigned& current_index();
	unsigned& current_offset();
	Sprite& current_sprite();

	static BitmapRef create_bitmap(EntryList const& list);
};

#endif
