#include "scene_bitmap_test.h"

#include "input.h"
#include "sprite.h"
#include "bitmap.h"
#include "player.h"
#include "output.h"
#include "font.h"
#include "graphics.h"

#include <boost/assert.hpp>


Scene_BitmapTest::Scene_BitmapTest()
		: Scene("Bitmap Test")
		, rgba_(new Sprite())
		, text_(new Sprite())
{
	rgba_->SetBitmap(Bitmap::Create(40, 10));
	rgba_->SetY(0);

	assert(rgba_->GetBitmap()->get_pixel(0, 0) == Color(0, 0, 0, 0));

	rgba_->GetBitmap()->fill(Rect( 0, 0, 10, 10), Color(255, 0, 0, 255));
	rgba_->GetBitmap()->fill(Rect(10, 0, 10, 10), Color(0, 255, 0, 255));
	rgba_->GetBitmap()->fill(Rect(20, 0, 10, 10), Color(0, 0, 255, 255));
	rgba_->GetBitmap()->fill(Rect(30, 0, 10, 10), Color(255, 255, 255, 0));

	assert(rgba_->GetBitmap()->get_pixel( 0, 0) == Color(255, 0, 0, 255));
	assert(rgba_->GetBitmap()->get_pixel(10, 0) == Color(0, 255, 0, 255));
	assert(rgba_->GetBitmap()->get_pixel(20, 0) == Color(0, 0, 255, 255));
	assert(rgba_->GetBitmap()->get_pixel(30, 0) == Color(255, 255, 255, 0));

	Font::default_color = Color(255, 255, 255, 255);
	text_->SetY(10);
	text_->SetBitmap(Bitmap::Create(100, 12));
	text_->GetBitmap()->fill(Rect(0, 0, 100, 12), Color(0, 0, 255, 255));
	text_->GetBitmap()->draw_text(0, 0, "Hello World!");
}

void Scene_BitmapTest::Update() {
	if(Input().IsAnyPressed()) {
		BOOST_VERIFY(Output().TakeScreenshot());
		Player().exit_flag = true;
	}
}
