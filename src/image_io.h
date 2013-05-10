#ifndef _EASYRPG_IMAGE_IO_H_
#define _EASYRPG_IMAGE_IO_H_

#include <iosfwd>
#include <string>
#include "memory_management.h"

namespace ImageIO {
/**
 * Load image from stream
 *
 * @param is source stream
 * @param transparent whether image is index 0 transparent palette
 */
BitmapRef ReadBMP(std::istream& is, bool transparent);
BitmapRef ReadXYZ(std::istream& is, bool transparent);
BitmapRef ReadPNG(std::istream& is, bool transparent);

BitmapRef ReadImage(std::string const& file, bool transparent);

/**
 * Writes PNG converted bitmap to output stream.
 *
 * @param bmp source bitmap
 * @param os output stream that PNG will be output.
 * @return true if success, otherwise false.
 */
bool WritePNG(BitmapRef const& bmp, std::ostream& os);
}

#endif
