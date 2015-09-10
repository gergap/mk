#!/bin/bash
# (C) 2013 Gerhard Gappmeier
# Description: Changes to your blddir, executes make and changes back to your
# previous dir. This is very useful for out-of-source builds, when you opened
# the sources from the source dir and and you want to rebuild your changes,
# or when you are in the bin dir testing your changes. By default the script
# searches for your bldir dir in ../bld, or relative to the top level git dir,
# but you can configure an absolute path using the env variable MK_BLDDIR.
# All arguments to 'mk' are passed to the 'make' command.

# default install prefix. As a developer normally I install into my project 
# directory, not into the system /usr/local, which is CMake's default.
# Change this to your needs.
INSTALL_PREFIX="\$TOPLEVEL_GIT_DIR"

# Add option to only run cmake and don't build. This maybe useful for testing
# CMake projects or reconfiguring your project.
# Just run 'mk cmake <more options>'.
if [ "$1" = "cmake" ]; then
    shift # eat first option
    ONLY_CMAKE=1
else
    ONLY_CMAKE=0
fi

# Sometimes you simply have Makefile based projects and don't use CMake,
# we make this also working by simply executing 'make' if a Makefile exists
# in the current folder. I use this e.g. for some AVR projects.
# check if we can simply use make inside the current folder
if [ -f Makefile ]; then
    make $*
    exit 0
fi

# check if build folder exists
if [ -d "$MK_BLDDIR" ]; then
    # use env variable
    BLD_DIR="$MK_BLDDIR"
elif [ -d "$PWD/../bld" ]; then
    # try to find it automatically relative to the current source dir
    # assumption: we are in /path/to/src on our build dir is /path/to/bld
    BLD_DIR="$PWD/../bld"
else
    # use git to find our build directory
    # normally I use a folder 'bld' inside the toplevel dir
    TOPLEVEL_GIT_DIR=`git rev-parse --show-toplevel`
    if [ "$INSTALL_PREFIX" == "\$TOPLEVEL_GIT_DIR" ]; then
        INSTALL_PREFIX=$TOPLEVEL_GIT_DIR
    fi
    #echo "TOPLEVEL_GIT_DIR=$TOPLEVEL_GIT_DIR"
    # it's possible that we are in a submodule and not in the top-level git
    # directory. So we go up one directory and check if we are still in a git
    # working tree. If so we retrieve this top-level dir.
    # (We assume that we don't have a submodule within a submodule)
    cd $TOPLEVEL_GIT_DIR/..
    IS_SUBMODULE=`git rev-parse --is-inside-work-tree 2>/dev/null`
    if [ "$IS_SUBMODULE" == "true" ]; then
        TOPLEVEL_GIT_DIR=`git rev-parse --show-toplevel`
        echo "TOPLEVEL_GIT_DIR=$TOPLEVEL_GIT_DIR"
    fi
    cd - > /dev/null

    # compute build directory name
    BLD_DIR="$TOPLEVEL_GIT_DIR/bld"
    if [ ! -d "$BLD_DIR" ]; then
        # if no build folder exists, but we are inside a git repo
        # we try to find the top level cmake file and create a build folder
        if [ -f "${TOPLEVEL_GIT_DIR}/CMakeLists.txt" ]; then
            SRC_DIR="${TOPLEVEL_GIT_DIR}"
        elif [ -f "${TOPLEVEL_GIT_DIR}/src/CMakeLists.txt" ]; then
            SRC_DIR="${TOPLEVEL_GIT_DIR}/src"
        else
            SRC_DIR=""
        fi

        if [ -n "$SRC_DIR" ]; then
            # create build directory
            mkdir "$BLD_DIR"
            cd "$BLD_DIR"

            # detect ninja and use it preferable
            if [ -x /usr/bin/ninja ]; then
                # Create ninja rules using CMake
                cmake -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX "$SRC_DIR" || exit 1
            else
                # create Makefile using CMake
                # by turning on CMAKE_EXPORT_COMPILE_COMMANDS we create a compile_commands.jso file
                # which can be used for semantic completion inside vim and YouCompleteMe
                cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX "$SRC_DIR" || exit 1
            fi
            cd -
        fi
    fi
fi

# turn on CMAKE_EXPORT_COMPILE_COMMANDS of compile_commands.json does not exist,
# but the Makefile exists already
if [ -f "$BLD_DIR/Makefile" ] && [ ! -f "$BLD_DIR/compile_commands.json" ]; then
    cd $BLD_DIR
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .
    cd -
fi
if [ ${ONLY_CMAKE} -eq 1 ]; then
    # stop here
    exit 0
fi

# execute make from the build dir
echo "cd into build dir '$BLD_DIR'..."
cd $BLD_DIR
if [ -e Makefile ]; then
    NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
    echo "executing make -j $NUM_CPUS ..."
    make -j$NUM_CPUS $*
else
    echo "executing ninja..."
    ninja $*
fi
echo "cd back"
cd -

