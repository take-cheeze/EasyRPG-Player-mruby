#ifndef _SCENE_BITMAP_TEST_H_
#define _SCENE_BITMAP_TEST_H_

#include "scene.h"
#include <boost/scoped_ptr.hpp>

class Sprite;

struct Scene_BitmapTest : public Scene {
	Scene_BitmapTest();

	void Update();

  private:
	boost::scoped_ptr<Sprite> const rgba_, text_;
};

#endif
