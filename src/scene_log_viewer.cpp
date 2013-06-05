#include <algorithm>
#include <fstream>
#include <sstream>

#include "scene_log_viewer.h"
#include "input.h"
#include "font.h"
#include "image_io.h"
#include "bitmap.h"
#include "filefinder.h"
#include "sprite.h"


Scene_LogViewer::Scene_LogViewer()
		: Scene("Log Viewer")
		, cursor_index_(0), cursor_offset_(0)
		, use_local_time_(true)
		, line_scroll_counter_(0)
{
	// reserve buffer size
	lines_.reserve(Output_::BUFFER_SIZE);
	buffer_cache_.reserve(Output_::BUFFER_SIZE);
}

void Scene_LogViewer::Start() {
	screenshot_.reset(new Sprite());
	screenshot_->visible = false;
	screenshot_->SetZ(100); // give higher priority than log lines

	size_t const font_size = Font::Default()->pixel_size();
	size_t const col_max = SCREEN_TARGET_WIDTH / font_size - 1;

	BitmapRef const cursor_bmp = Bitmap::Create(font_size * col_max + 4, font_size + 2);
	Color const blue(0, 0, 255, 255);
	// top
	cursor_bmp->fill(Rect(0, 0, cursor_bmp->width(), 1), blue);
	// left
	cursor_bmp->fill(Rect(0, 0, 1, cursor_bmp->height()), blue);
	// right
	cursor_bmp->fill(Rect(cursor_bmp->width() - 1, 0, 1, cursor_bmp->height()), blue);
	// bottom
	cursor_bmp->fill(Rect(0, cursor_bmp->height() - 1, cursor_bmp->width(), 1), blue);
	cursor_.reset(new Sprite());
	cursor_->SetBitmap(cursor_bmp);
	cursor_->SetX(font_size - 2);

	// white background
	background_.reset(new Sprite);
	background_->SetBitmap(Bitmap::Create(
		SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT, Color(255, 255, 255, 255)));
	background_->SetZ(-100);
	background_->visible = true;

	FontRef const font = Font::Default();

	Output_::buffer_type const& buf = Output().buffer();
	lines_.resize(buf.size());
	buffer_cache_.resize(buf.size());
	std::copy(buf.begin(), buf.end(), buffer_cache_.begin());

	for(buffer_cache_type::const_iterator i = buffer_cache_.begin(); i != buffer_cache_.end(); ++i) {
		std::string const line = generate_line(*i);
		BitmapRef const bmp = Bitmap::Create(font->GetSize(line).width, font->pixel_size());
		Font::default_color = Output().TypeColor(i->type);
		bmp->draw_text(0, 0, line);
		(lines_[i - buffer_cache_.begin()] = EASYRPG_MAKE_SHARED<Sprite>())->SetBitmap(bmp);
	}

	set_cursor_index(lines_.size() - 1);
}

std::string Scene_LogViewer::generate_line(Output_::Message const& msg) const {
	std::ostringstream oss;
	oss << Output().Type2String(msg.type)[0] << " "
		<< (use_local_time_
			? Output().local_time(msg.time, true) : Output().utc_time(msg.time, true))
		<< " " << msg.message;
	return oss.str();
}

static void hide_sprite(EASYRPG_SHARED_PTR<Sprite> const& s) { s->visible = false; }

void Scene_LogViewer::set_cursor_index(int const idx) {
	FontRef const font = Font::Default();
	size_t const font_size = font->pixel_size();

	size_t const row_max = SCREEN_TARGET_HEIGHT / font_size - 2,
				 col_max = SCREEN_TARGET_WIDTH / font_size - 1;

	cursor_index_ = (idx + lines_.size()) % lines_.size();
	cursor_offset_ = (cursor_index_ < cursor_offset_)? cursor_index_:
					 (cursor_index_ >= (cursor_offset_ + row_max))
					 ? std::max(0, int(cursor_index_) - int(row_max - 1)):
					 cursor_offset_;

	// hide all lines
	std::for_each(lines_.begin(), lines_.end(), hide_sprite);

	// set cursor position
	cursor_->SetY(font_size * (cursor_index_ - cursor_offset_ + 1) - 1);

	// show and set position of active lines
	for(size_t i = 0; i < std::min<size_t>(row_max, lines_.size() - cursor_offset_); ++i) {
		Sprite& s = *lines_[cursor_offset_ + i];
		s.visible = true;
		s.SetX(font_size);
		s.SetY(font_size * (i + 1));
		s.SetSrcRect(Rect(0, 0, font_size * col_max, font_size));
	}
}

void Scene_LogViewer::Update() {
	unsigned line_scroll_cache = 0;
	std::swap(line_scroll_cache, ++line_scroll_counter_);

	Output_::Message const& line = buffer_cache_[cursor_index_];

	if(screenshot_->visible and Input().IsTriggered(Input_::CANCEL)) {
		screenshot_->visible = false;
	} else if(Input().IsTriggered(Input_::DECISION) and
			  line.screenshot and FileFinder().Exists(*line.screenshot)) {
		screenshot_->visible = true;
		screenshot_->SetBitmap(ImageIO::ReadPNG(*FileFinder().openUTF8(
			*line.screenshot, std::ios::binary | std::ios::in), false));
	} else if(Input().IsTriggered(Input_::CANCEL)) { // exit log viewer
		Scene::Pop();
	} else if(Input().IsRepeated(Input_::DOWN)) {
		set_cursor_index(int(cursor_index_) + 1);
	} else if(Input().IsRepeated(Input_::UP)) {
		set_cursor_index(int(cursor_index_) - 1);
	} else {
		std::swap(line_scroll_cache, line_scroll_counter_);

		Sprite& s = *lines_[cursor_index_];
		Rect src_rect = s.GetSrcRect();
		line_scroll_counter_ %= s.GetBitmap()->width();
		src_rect.x = line_scroll_counter_;
		s.SetSrcRect(src_rect);
	}
}
