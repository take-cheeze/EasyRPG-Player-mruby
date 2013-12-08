EasyRPG Player
==============

EasyRPG Player is a game interpreter to play RPG Maker 2000, 2003 and EasyRPG
games. It uses EasyRPG Readers library to read RPG Maker game data.

EasyRPG Player is part of the EasyRPG Project. More information is available
at the project website:

  https://easy-rpg.org/


Documentation
-------------

Documentation is available at the documentation wiki:

  https://easy-rpg.org/wiki/


Source code generated documentation is available at:

  https://easy-rpg.org/docs/player/index.html


Requirements
------------

* Toola
  * pkg-config
    * used to find the following libraries
  * clang
    * or C++ compiler that can use full feature of c++11
  * ruby and following gems
    * rake
    * devil
    * libarchive
    * iconv
* Libraries
  * SDL2
  * SDL2_mixer
  * pixman
  * freetype2
  * libpng
  * zlib


Optional Requirements
---------------------

* wine
  * for finding RTP installed to wine
* Doxygen
  * for C++ API document generation


Daily builds
------------

Up to date binaries for assorted platforms are available at:

  https://easy-rpg.org/jenkins/view/Player/


Source code
-----------

EasyRPG Player development is hosted by GitHub.
Project files are available in Git repositories.

  https://github.com/EasyRPG/Player


Building
--------

Use *build.sh* like *rake*.
It will pipe options to mruby's *Rakefile* with EasyRPG configuration.
Basic target is *all*, *test*, *clean*.


License
-------

EasyRPG Player is free software. See the file COPYING for copying conditions.
