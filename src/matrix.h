/*
 * This file is part of EasyRPG Player.
 *
 * EasyRPG Player is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EasyRPG Player is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with EasyRPG Player. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _EASYRPG_MATRIX_H_
#define _EASYRPG_MATRIX_H_

#include <pixman.h>

#include <cmath>
#include <algorithm>

#include <boost/assert.hpp>
#include <boost/bind.hpp>
#include <boost/utility/enable_if.hpp>
#include <boost/type_traits/is_floating_point.hpp>
#include <boost/type_traits/is_integral.hpp>


struct Matrix {
  private:
	// uninitalized
	struct no_init {};
	Matrix(no_init const&) {}

  public:
	pixman_transform_t data;

	struct fixed {
		pixman_fixed_t data;

		template<class T>
		fixed(T const& v, typename boost::enable_if<boost::is_floating_point<T> >::type* = 0)
				: data(pixman_double_to_fixed(double(v))) {}
		template<class T>
		fixed(T const& v, typename boost::enable_if<boost::is_integral<T> >::type* = 0)
				: data(pixman_int_to_fixed(int(v))) {}
	};

	Matrix() {
		pixman_transform_init_identity(&data);
	}

	static Matrix rotate_(double const angle) {
		Matrix ret = no_init();
		pixman_transform_init_rotate(
			&ret.data,
			pixman_double_to_fixed(std::cos(angle)),
			pixman_double_to_fixed(std::sin(angle)));
		return ret;
	}
	static Matrix scale_(fixed const& x, fixed const& y) {
		Matrix ret = no_init();
		pixman_transform_init_scale(&ret.data, x.data, y.data);
		return ret;
	}
	static Matrix translate_(fixed const x, fixed const y) {
		Matrix ret = no_init();
		pixman_transform_init_translate(&ret.data, x.data, y.data);
		return ret;
	}

	Matrix invert() const {
		Matrix ret = no_init();
		BOOST_VERIFY(pixman_transform_invert(&ret.data, &data));
		return ret;
	}

	Matrix& rotate(double const angle, bool const forward = true) {
		pixman_transform_rotate(forward? &data : NULL, forward? NULL : &data,
								pixman_double_to_fixed(std::cos(angle)),
								pixman_double_to_fixed(std::sin(angle)));
		return *this;
	}
	Matrix& scale(fixed const& x, fixed const& y, bool const forward = true) {
		pixman_transform_scale(
			forward? &data : NULL, forward? NULL : &data, x.data, y.data);
		return *this;
	}
	Matrix& translate(fixed const& x, fixed const& y, bool const forward = true) {
		pixman_transform_translate(
			forward? &data : NULL, forward? NULL : &data, x.data, y.data);
		return *this;
	}

	void multiply(pixman_vector_t& v) const {
		BOOST_VERIFY(pixman_transform_point(&data, &v));
	}

	template<size_t index>
	static inline bool compare_vector(pixman_vector_t const& lhs,
											 pixman_vector_t const& rhs)
	{
		BOOST_STATIC_ASSERT(index < 3);
		return lhs.vector[index] < rhs.vector[index];
	}

	Rect transform(Rect const& rct) const {
		pixman_vector_t vecs[4] = {
			{ { fixed(rct.x).data, fixed(rct.y).data, fixed(1).data } },
			{ { fixed(rct.x + rct.width).data, fixed(rct.y).data, fixed(1).data } },
			{ { fixed(rct.x + rct.width).data, fixed(rct.y + rct.height).data, fixed(1).data } },
			{ { fixed(rct.x).data, fixed(rct.y + rct.height).data, fixed(1).data } } };

		std::for_each(vecs, vecs + 4, boost::bind(&Matrix::multiply, this, _1));

		int const
				x = pixman_fixed_to_int(pixman_fixed_floor(
					std::min_element(vecs, vecs + 4, &compare_vector<0>)->vector[0])),
				y = pixman_fixed_to_int(pixman_fixed_floor(
					std::min_element(vecs, vecs + 4, &compare_vector<1>)->vector[1]));

		return Rect(
			x, y,
			pixman_fixed_to_int(pixman_fixed_ceil(
				std::max_element(vecs, vecs + 4, &compare_vector<0>)->vector[0])) - x,
			pixman_fixed_to_int(pixman_fixed_ceil(
				std::max_element(vecs, vecs + 4, &compare_vector<1>)->vector[1])) - y);
	}

	Matrix operator*(Matrix const& rhs) const {
		Matrix ret = no_init();
		pixman_transform_multiply(&ret.data, &data, &rhs.data);
		return ret;
	}

	static Matrix const identity;
};

struct set_matrix {
	set_matrix(pixman_image_t* img, Matrix const& mat)
			: img_(img)
	{
		assert(img_);

		pixman_image_set_transform(img_, &mat.data);
	}

	~set_matrix() {
		pixman_image_set_transform(img_, &Matrix::identity.data);
	}

  private:
	pixman_image_t* const img_;
};

#define SET_MATRIX(bmp, m)						\
	set_matrix mat__ ## __LINE__(bmp, m);		\
	(void)mat__ ## __LINE__						\

#endif
