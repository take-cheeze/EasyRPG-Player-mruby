#include "drawable.h"
#include "graphics.h"

Drawable::Drawable(Drawable::Type const t)
		: type(t), ID(Graphics().drawable_id++)
		, visible(true) {}
