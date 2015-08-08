Simple make wrapper script
==========================

The main purpose of this script is that you can build your project from any
directory inside the project without manually changing to the build folder,
entering 'make' and cd'ing back.
This script does this for you and you simply need to type 'mk'.

But the script also does a lot of more things:

* Smart detection of your build folder
 - finding the top level directory inside git respositories
   and search/create the build dir relative to this
 - using some default folder structures as fallback if you don't use git
 - manual configuration of the build directory by exporting MK_BLDDIR
* Creation of the build dir if it does not exist
* It executes CMake automatically when creating the build dir
* It creates a compile_commands.json file using CMake so the semantic completion
  inside Vim works automatically if you are using the YouCompleteMe plugin
* It also supports plain Makefike based projects. So 'mk' behaves like typing
  'make' if a Makefile exists in the current dir.

Installation
------------

Just copy/link the script into /usr/local/bin. Ensure that it is executable
and that /usr/local/bin is in your PATH variable.

