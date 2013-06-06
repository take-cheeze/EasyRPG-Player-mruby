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

BitmapRef Scene_LogViewer::create_line(Output_::Message const& msg) const {
	std::string const line = generate_line(msg);
	BitmapRef const bmp = Bitmap::Create(font_->GetSize(line).width, font_->pixel_size());
	Font::default_color = Output().TypeColor(msg.type);
	bmp->draw_text(0, 0, line);

	return bmp;
}

void Scene_LogViewer::Start() {
	line_repeat_.reset(new Sprite());
	line_repeat_->visible = false;

	screenshot_.reset(new Sprite());
	screenshot_->visible = false;
	screenshot_->SetZ(100); // give higher priority than log lines

	screenshot_time_.reset(new Sprite());
	screenshot_time_->visible = false;
	screenshot_time_->SetZ(200);

	font_ = Font::Shinonome();
	font_size_ = font_->pixel_size();

	row_max_ = SCREEN_TARGET_HEIGHT / font_size_ - 2,
	col_max_ = SCREEN_TARGET_WIDTH / font_size_ - 1;

	BitmapRef const cursor_bmp = Bitmap::Create(font_size_ * col_max_ + 4, font_size_ + 2);
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
	cursor_->SetX(font_size_ - 2);

	// white background
	background_.reset(new Sprite);
	background_->SetBitmap(Bitmap::Create(
		SCREEN_TARGET_WIDTH, SCREEN_TARGET_HEIGHT, Color(255, 255, 255, 255)));
	background_->SetZ(-100);
	background_->visible = true;

	Output_::buffer_type const& buf = Output().buffer();
	lines_.resize(buf.size());
	buffer_cache_.resize(buf.size());
	std::copy(buf.begin(), buf.end(), buffer_cache_.begin());

	set_cursor_index(lines_.size() - 1);
}

std::string Scene_LogViewer::time_string(Output_::Message const& msg) const {
	return use_local_time_
			? Output().local_time(msg.time, true)
			: Output().utc_time(msg.time, true);
}

std::string Scene_LogViewer::generate_line(Output_::Message const& msg) const {
	std::ostringstream oss;
	oss << Output().Type2String(msg.type)[0] << " "
		<< time_string(msg) << " " << msg.message;
	return oss.str();
}

static void hide_sprite(EASYRPG_SHARED_PTR<Sprite> const& s) {
	if(s) { s->visible = false; }
}

void Scene_LogViewer::hide_lines() {
	std::for_each(lines_.begin(), lines_.end(), hide_sprite);
}

void Scene_LogViewer::set_cursor_index(int const idx) {
	cursor_index_ = (idx + lines_.size()) % lines_.size();
	cursor_offset_ = std::max(0, std::max<int>(
		int(cursor_index_) - int(row_max_ - 1),
		std::min(cursor_offset_, cursor_index_)));

	hide_lines();

	// set cursor position
	cursor_->SetY(font_size_ * (cursor_index_ - cursor_offset_ + 1) - 1);

	// show and set position of active lines
	for(size_t i = 0; i < std::min<size_t>(row_max_, lines_.size() - cursor_offset_); ++i) {
		EASYRPG_SHARED_PTR<Sprite>& s = lines_[cursor_offset_ + i];
		Output_::Message const& buf = buffer_cache_[cursor_offset_ + i];
		if(not s) { (s = EASYRPG_MAKE_SHARED<Sprite>())->SetBitmap(create_line(buf)); }

		s->visible = true;
		s->SetX(font_size_);
		s->SetY(font_size_ * (i + 1));
		s->SetSrcRect(Rect(0, 0, font_size_ * col_max_, font_size_));

		if(cursor_offset_ + i == cursor_index_) {
			enable_line_scroll_ = font_->GetSize(generate_line(buf)).width > int(font_size_ * col_max_);
			line_scroll_counter_ = 0;
			line_repeat_->SetBitmap(s->GetBitmap());
		}
	}
}

void Scene_LogViewer::Update() {
	Output_::Message const& line = buffer_cache_[cursor_index_];

	if(screenshot_->visible and Input().IsTriggered(Input_::CANCEL)) {
		screenshot_->visible = false;
		screenshot_time_->visible = false;
		set_cursor_index(cursor_index_);
	} else if(Input().IsTriggered(Input_::DECISION) and
			  line.screenshot and FileFinder().Exists(*line.screenshot)) {
		hide_lines();

		screenshot_->visible = true;
		screenshot_->SetBitmap(ImageIO::ReadPNG(*FileFinder().openUTF8(
			*line.screenshot, std::ios::binary | std::ios::in), false));

		std::string const time_str = time_string(line);
		if(not screenshot_time_->GetBitmap()) {
			Rect const time_size = font_->GetSize(time_str);
			screenshot_time_->SetBitmap(
				Bitmap::Create(time_size.width + 1, time_size.height + 1));
		}
		Font::default_color = Color(0, 0, 0, 255);
		screenshot_time_->GetBitmap()->draw_text(1, 1, time_str);
		Font::default_color = Color(255, 255, 255, 255);
		screenshot_time_->GetBitmap()->draw_text(0, 0, time_str);
		screenshot_time_->visible = true;
	} else if(Input().IsTriggered(Input_::CANCEL)) { // exit log viewer
		Scene::Pop();
	} else if(Input().IsRepeated(Input_::DOWN)) {
		set_cursor_index(int(cursor_index_) + 1);
	} else if(Input().IsRepeated(Input_::UP)) {
		set_cursor_index(int(cursor_index_) - 1);
	} else if(enable_line_scroll_) {
		int const repeat_blank = font_size_ * 5;

		Sprite& s = *lines_[cursor_index_];
		Rect src_rect = s.GetSrcRect();
		line_scroll_counter_ %= (s.GetBitmap()->width() + repeat_blank);
		src_rect.x = line_scroll_counter_++;
		s.SetSrcRect(src_rect);

		int const repeat_x = std::max(
			0, std::min(int(s.GetBitmap()->width()) - src_rect.x + repeat_blank, int(font_size_ * col_max_)));

		line_repeat_->visible = true;
		line_repeat_->SetX(font_size_ + repeat_x);
		line_repeat_->SetY(s.GetY());
		line_repeat_->SetSrcRect(Rect(
			0, 0, std::max(0, int(font_size_ * col_max_) - repeat_x), font_size_));
	}
}
