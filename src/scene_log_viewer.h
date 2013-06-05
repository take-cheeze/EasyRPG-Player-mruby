#ifndef _SCENE_LOG_VIEWER_H_
#define _SCENE_LOG_VIEWER_H_

#include "scene.h"
#include "output.h"

#include <vector>
#include <boost/scoped_ptr.hpp>

class Sprite;


class Scene_LogViewer : public Scene {
  public:
	Scene_LogViewer();

	/*
	 * generate bitmaps from Output buffer
	 */
	void Start();

	void Update();

	std::string generate_line(Output_::Message const& msg) const;
	void set_cursor_index(int idx);

  private:
	std::vector<EASYRPG_SHARED_PTR<Sprite> > lines_;
	boost::scoped_ptr<Sprite> screenshot_, background_, cursor_;

	typedef std::vector<Output_::Message> buffer_cache_type;
	buffer_cache_type buffer_cache_;

	unsigned cursor_index_, cursor_offset_;

	bool use_local_time_;
	unsigned line_scroll_counter_;
};

#endif
