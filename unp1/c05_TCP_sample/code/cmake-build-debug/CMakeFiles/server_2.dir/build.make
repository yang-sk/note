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
CMAKE_SOURCE_DIR = /home/tom/note_unix_network_program_1/C5_TCP_sample/code

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug

# Include any dependencies generated for this target.
include CMakeFiles/server_2.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/server_2.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/server_2.dir/flags.make

CMakeFiles/server_2.dir/server_2.o: CMakeFiles/server_2.dir/flags.make
CMakeFiles/server_2.dir/server_2.o: ../server_2.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/server_2.dir/server_2.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/server_2.dir/server_2.o   -c /home/tom/note_unix_network_program_1/C5_TCP_sample/code/server_2.c

CMakeFiles/server_2.dir/server_2.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/server_2.dir/server_2.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/C5_TCP_sample/code/server_2.c > CMakeFiles/server_2.dir/server_2.i

CMakeFiles/server_2.dir/server_2.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/server_2.dir/server_2.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/C5_TCP_sample/code/server_2.c -o CMakeFiles/server_2.dir/server_2.s

CMakeFiles/server_2.dir/server_2.o.requires:

.PHONY : CMakeFiles/server_2.dir/server_2.o.requires

CMakeFiles/server_2.dir/server_2.o.provides: CMakeFiles/server_2.dir/server_2.o.requires
	$(MAKE) -f CMakeFiles/server_2.dir/build.make CMakeFiles/server_2.dir/server_2.o.provides.build
.PHONY : CMakeFiles/server_2.dir/server_2.o.provides

CMakeFiles/server_2.dir/server_2.o.provides.build: CMakeFiles/server_2.dir/server_2.o


CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: CMakeFiles/server_2.dir/flags.make
CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: /home/tom/note_unix_network_program_1/Code/unp_base.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o   -c /home/tom/note_unix_network_program_1/Code/unp_base.c

CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/Code/unp_base.c > CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.i

CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/Code/unp_base.c -o CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.s

CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires:

.PHONY : CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides: CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires
	$(MAKE) -f CMakeFiles/server_2.dir/build.make CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build
.PHONY : CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides

CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build: CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o


# Object files for target server_2
server_2_OBJECTS = \
"CMakeFiles/server_2.dir/server_2.o" \
"CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"

# External object files for target server_2
server_2_EXTERNAL_OBJECTS =

server_2: CMakeFiles/server_2.dir/server_2.o
server_2: CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o
server_2: CMakeFiles/server_2.dir/build.make
server_2: CMakeFiles/server_2.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Linking C executable server_2"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/server_2.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/server_2.dir/build: server_2

.PHONY : CMakeFiles/server_2.dir/build

CMakeFiles/server_2.dir/requires: CMakeFiles/server_2.dir/server_2.o.requires
CMakeFiles/server_2.dir/requires: CMakeFiles/server_2.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

.PHONY : CMakeFiles/server_2.dir/requires

CMakeFiles/server_2.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/server_2.dir/cmake_clean.cmake
.PHONY : CMakeFiles/server_2.dir/clean

CMakeFiles/server_2.dir/depend:
	cd /home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/tom/note_unix_network_program_1/C5_TCP_sample/code /home/tom/note_unix_network_program_1/C5_TCP_sample/code /home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug /home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug /home/tom/note_unix_network_program_1/C5_TCP_sample/code/cmake-build-debug/CMakeFiles/server_2.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/server_2.dir/depend
