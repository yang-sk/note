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
include CMakeFiles/server_select.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/server_select.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/server_select.dir/flags.make

CMakeFiles/server_select.dir/server_select.o: CMakeFiles/server_select.dir/flags.make
CMakeFiles/server_select.dir/server_select.o: ../server_select.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/server_select.dir/server_select.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/server_select.dir/server_select.o   -c /home/tom/note_unix_network_program_1/C6_select_pull/code/server_select.c

CMakeFiles/server_select.dir/server_select.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/server_select.dir/server_select.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/C6_select_pull/code/server_select.c > CMakeFiles/server_select.dir/server_select.i

CMakeFiles/server_select.dir/server_select.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/server_select.dir/server_select.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/C6_select_pull/code/server_select.c -o CMakeFiles/server_select.dir/server_select.s

CMakeFiles/server_select.dir/server_select.o.requires:

.PHONY : CMakeFiles/server_select.dir/server_select.o.requires

CMakeFiles/server_select.dir/server_select.o.provides: CMakeFiles/server_select.dir/server_select.o.requires
	$(MAKE) -f CMakeFiles/server_select.dir/build.make CMakeFiles/server_select.dir/server_select.o.provides.build
.PHONY : CMakeFiles/server_select.dir/server_select.o.provides

CMakeFiles/server_select.dir/server_select.o.provides.build: CMakeFiles/server_select.dir/server_select.o


CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: CMakeFiles/server_select.dir/flags.make
CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: /home/tom/note_unix_network_program_1/Code/unp_base.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o   -c /home/tom/note_unix_network_program_1/Code/unp_base.c

CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/Code/unp_base.c > CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.i

CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/Code/unp_base.c -o CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.s

CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires:

.PHONY : CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides: CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires
	$(MAKE) -f CMakeFiles/server_select.dir/build.make CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build
.PHONY : CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides

CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build: CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o


# Object files for target server_select
server_select_OBJECTS = \
"CMakeFiles/server_select.dir/server_select.o" \
"CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"

# External object files for target server_select
server_select_EXTERNAL_OBJECTS =

server_select: CMakeFiles/server_select.dir/server_select.o
server_select: CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o
server_select: CMakeFiles/server_select.dir/build.make
server_select: CMakeFiles/server_select.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Linking C executable server_select"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/server_select.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/server_select.dir/build: server_select

.PHONY : CMakeFiles/server_select.dir/build

CMakeFiles/server_select.dir/requires: CMakeFiles/server_select.dir/server_select.o.requires
CMakeFiles/server_select.dir/requires: CMakeFiles/server_select.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

.PHONY : CMakeFiles/server_select.dir/requires

CMakeFiles/server_select.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/server_select.dir/cmake_clean.cmake
.PHONY : CMakeFiles/server_select.dir/clean

CMakeFiles/server_select.dir/depend:
	cd /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/tom/note_unix_network_program_1/C6_select_pull/code /home/tom/note_unix_network_program_1/C6_select_pull/code /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug /home/tom/note_unix_network_program_1/C6_select_pull/code/cmake-build-debug/CMakeFiles/server_select.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/server_select.dir/depend
