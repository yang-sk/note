# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.9

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /home/tom/Software/clion-2017.3.1/bin/cmake/bin/cmake

# The command to remove a file.
RM = /home/tom/Software/clion-2017.3.1/bin/cmake/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/tom/note_unix_network_program_1/C6_select_pull/code

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug

# Include any dependencies generated for this target.
include CMakeFiles/makeBigFile.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/makeBigFile.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/makeBigFile.dir/flags.make

CMakeFiles/makeBigFile.dir/makeBigFile.o: CMakeFiles/makeBigFile.dir/flags.make
CMakeFiles/makeBigFile.dir/makeBigFile.o: ../makeBigFile.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/makeBigFile.dir/makeBigFile.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/makeBigFile.dir/makeBigFile.o   -c /home/tom/note_unix_network_program_1/C6_select_pull/code/makeBigFile.c

CMakeFiles/makeBigFile.dir/makeBigFile.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/makeBigFile.dir/makeBigFile.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/C6_select_pull/code/makeBigFile.c > CMakeFiles/makeBigFile.dir/makeBigFile.i

CMakeFiles/makeBigFile.dir/makeBigFile.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/makeBigFile.dir/makeBigFile.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/C6_select_pull/code/makeBigFile.c -o CMakeFiles/makeBigFile.dir/makeBigFile.s

CMakeFiles/makeBigFile.dir/makeBigFile.o.requires:

.PHONY : CMakeFiles/makeBigFile.dir/makeBigFile.o.requires

CMakeFiles/makeBigFile.dir/makeBigFile.o.provides: CMakeFiles/makeBigFile.dir/makeBigFile.o.requires
	$(MAKE) -f CMakeFiles/makeBigFile.dir/build.make CMakeFiles/makeBigFile.dir/makeBigFile.o.provides.build
.PHONY : CMakeFiles/makeBigFile.dir/makeBigFile.o.provides

CMakeFiles/makeBigFile.dir/makeBigFile.o.provides.build: CMakeFiles/makeBigFile.dir/makeBigFile.o


# Object files for target makeBigFile
makeBigFile_OBJECTS = \
"CMakeFiles/makeBigFile.dir/makeBigFile.o"

# External object files for target makeBigFile
makeBigFile_EXTERNAL_OBJECTS =

makeBigFile: CMakeFiles/makeBigFile.dir/makeBigFile.o
makeBigFile: CMakeFiles/makeBigFile.dir/build.make
makeBigFile: CMakeFiles/makeBigFile.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C executable makeBigFile"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/makeBigFile.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/makeBigFile.dir/build: makeBigFile

.PHONY : CMakeFiles/makeBigFile.dir/build

CMakeFiles/makeBigFile.dir/requires: CMakeFiles/makeBigFile.dir/makeBigFile.o.requires

.PHONY : CMakeFiles/makeBigFile.dir/requires

CMakeFiles/makeBigFile.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/makeBigFile.dir/cmake_clean.cmake
.PHONY : CMakeFiles/makeBigFile.dir/clean

CMakeFiles/makeBigFile.dir/depend:
	cd /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/tom/note_unix_network_program_1/C6_select_pull/code /home/tom/note_unix_network_program_1/C6_select_pull/code /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles/makeBigFile.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/makeBigFile.dir/depend

