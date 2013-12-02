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

#ifndef _FILEFINDER_H_
#define _FILEFINDER_H_

// Headers
#include <string>
#include <ios>
#include <vector>
#include <boost/container/flat_map.hpp>
#include <boost/noncopyable.hpp>
#include <boost/optional.hpp>

#include "memory_management.h"

/**
 * FileFinder contains helper methods for finding case
 * insensitive files paths.
 */
struct FileFinder_ : boost::noncopyable {
	/**
	 * Initializes FileFinder.
	 */
	FileFinder_();

	/**
	 * Finds an image file.
	 *
	 * @param dir directory to check.
	 * @param name image file name to check.
	 * @return path to file.
	 */
	std::string FindImage(const std::string& dir, const std::string& name);

	/**
	 * Reload RTP paths.
	 * This function is called in constructor too.
	 */
	void UpdateRtpPaths();

	/**
	 * Finds a file.
	 *
	 * @param dir directory to check.
	 * @param name file name to check.
	 * @return path to file.
	 */
	std::string FindDefault(const std::string& dir, const std::string& name);

	/**
	 * Finds a file.
	 *
	 * @param name the path and name.
	 * @return path to file.
	 */
	std::string FindDefault(const std::string& name);

	/**
	 * Finds a music file.
	 *
	 * @param name the music path and name.
	 * @return path to file.
	 */
	std::string FindMusic(const std::string& name);

	/**
	 * Finds a sound file.
	 * @param name the sound path and name.
	 * @return path to file.
	 */
	std::string FindSound(const std::string& name);

	/**
	 * Finds a movie file.
	 * @param name the movie path and name.
	 * @return path to file.
	 */
	std::string FindMovie(const std::string& name);

	/**
	 * Finds a font file.
	 *
	 * @param name the font name.
	 * @return path to file.
	 */
	std::string FindFont(const std::string& name);

	/**
	 * Opens a file specified by a UTF-8 string.
	 *
	 * @param name_utf8 filename in UTF-8.
	 * @param mode ("r", "w", etc).
	 * @return FILE*.
	 */
	FILE* fopenUTF8(const std::string& name_utf8, char const* mode);

	/**
	 * Creates stream from UTF-8 file name.
	 *
	 * @param name UTF-8 string file name.
	 * @param m stream mode.
	 * @return NULL if open failed.
	 */
	EASYRPG_SHARED_PTR<std::fstream> openUTF8(const std::string& name, std::ios::openmode m);

	/*
	 * { case lowered path, real path }
	 */
	typedef boost::container::flat_map<std::string, std::string> string_map;

	struct Directory {
		std::string base;
		string_map members;
	}; // struct Directory

	/**
	 * Checks whether passed file is directory.
	 *
	 * @param file file to check.
	 * @return true if file is directory, otherwise false.
	 */
	bool IsDirectory(std::string const& file);

	/**
	 * Checks whether passed file exists.
	 * This function maybe is case sensitve in some platform.
	 *
	 * @param file file to check
	 * @return true if file exists, otherwise false.
	 */
	bool Exists(std::string const& file);

	/**
	 * Checks whether file name exists in the directory.
	 * This function is case insensitive.
	 *
	 * @param dir directory to check.
	 * @param name file name to check. Don't pass full path.
	 * @return true if file exists, otherwise false.
	 */
	bool Exists(Directory const& dir, std::string const& name);

	/**
	 * Appends name to directory.
	 *
	 * @param dir base directory.
	 * @param name file name to be appended to dir.
	 * @return normalized path string.
	 */
	std::string MakePath(std::string const& dir, std::string const& name);

	/**
	 * GetDirectoryMembers memer listing mode.
	 */
	enum Mode {
		ALL, /**< list files and directory */
		FILES, /**< list only non-directory files */
		DIRECTORIES, /**< list only directories */
	};
	/**
	 * Lists directory members.
	 *
	 * @param dir directory to list members.
	 * @param m member listing mode.
	 * @return member list.
	 */
	Directory GetDirectoryMembers(std::string const& dir, Mode m = ALL);

	/*
	 * { case lowered directory name, non directory file list }
	 */
	typedef boost::container::flat_map<std::string, string_map> sub_members_type;

	struct ProjectTree {
		std::string project_path;
		string_map files, directories;
		sub_members_type sub_members;
	}; // struct ProjectTree

	ProjectTree const& GetProjectTree();
	EASYRPG_SHARED_PTR<ProjectTree> CreateProjectTree(std::string const& p);
	bool IsRPG2kProject(ProjectTree const& dir);
	bool IsRPG2kProject(string_map const& dir);

	/*
	 * extract relative path to absolute path
	 *
	 * @param f a path
	 * @return absolute path
	 */
	std::string fullpath(std::string const& f) const;

	std::string project_path;

  private:
	boost::optional<std::string> FindFile(ProjectTree const& tree,
										  std::string const& dir,
										  std::string const& name,
										  char const* exts[]);
	std::string FindFile(const std::string &dir, const std::string& name, const char* exts[]);

	std::string const& translate_rtp(std::string const& dir, std::string const& name);
	void add_rtp_path(std::string const& p);

	typedef std::vector<EASYRPG_SHARED_PTR<ProjectTree> > search_path_list;
	search_path_list search_paths;
	std::string fonts_path;

	ProjectTree tree_;
};

#include <mruby.h>

FileFinder_& FileFinder(mrb_state* M = NULL);

#endif
