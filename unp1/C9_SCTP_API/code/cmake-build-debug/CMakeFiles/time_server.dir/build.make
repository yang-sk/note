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
CMAKE_SOURCE_DIR = /home/tom/note_unix_network_program_1/C9_SCTP_API/code

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug

# Include any dependencies generated for this target.
include CMakeFiles/time_server.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/time_server.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/time_server.dir/flags.make

CMakeFiles/time_server.dir/server.o: CMakeFiles/time_server.dir/flags.make
CMakeFiles/time_server.dir/server.o: ../server.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/time_server.dir/server.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/time_server.dir/server.o   -c /home/tom/note_unix_network_program_1/C9_SCTP_API/code/server.c

CMakeFiles/time_server.dir/server.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/time_server.dir/server.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/C9_SCTP_API/code/server.c > CMakeFiles/time_server.dir/server.i

CMakeFiles/time_server.dir/server.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/time_server.dir/server.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/C9_SCTP_API/code/server.c -o CMakeFiles/time_server.dir/server.s

CMakeFiles/time_server.dir/server.o.requires:

.PHONY : CMakeFiles/time_server.dir/server.o.requires

CMakeFiles/time_server.dir/server.o.provides: CMakeFiles/time_server.dir/server.o.requires
	$(MAKE) -f CMakeFiles/time_server.dir/build.make CMakeFiles/time_server.dir/server.o.provides.build
.PHONY : CMakeFiles/time_server.dir/server.o.provides

CMakeFiles/time_server.dir/server.o.provides.build: CMakeFiles/time_server.dir/server.o


CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: CMakeFiles/time_server.dir/flags.make
CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o: /home/tom/note_unix_network_program_1/Code/unp_base.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o   -c /home/tom/note_unix_network_program_1/Code/unp_base.c

CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tom/note_unix_network_program_1/Code/unp_base.c > CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.i

CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tom/note_unix_network_program_1/Code/unp_base.c -o CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.s

CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires:

.PHONY : CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides: CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires
	$(MAKE) -f CMakeFiles/time_server.dir/build.make CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build
.PHONY : CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides

CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.provides.build: CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o


# Object files for target time_server
time_server_OBJECTS = \
"CMakeFiles/time_server.dir/server.o" \
"CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o"

# External object files for target time_server
time_server_EXTERNAL_OBJECTS =

time_server: CMakeFiles/time_server.dir/server.o
time_server: CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o
time_server: CMakeFiles/time_server.dir/build.make
time_server: CMakeFiles/time_server.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Linking C executable time_server"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/time_server.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/time_server.dir/build: time_server

.PHONY : CMakeFiles/time_server.dir/build

CMakeFiles/time_server.dir/requires: CMakeFiles/time_server.dir/server.o.requires
CMakeFiles/time_server.dir/requires: CMakeFiles/time_server.dir/home/tom/note_unix_network_program_1/Code/unp_base.o.requires

.PHONY : CMakeFiles/time_server.dir/requires

CMakeFiles/time_server.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/time_server.dir/cmake_clean.cmake
.PHONY : CMakeFiles/time_server.dir/clean

CMakeFiles/time_server.dir/depend:
	cd /home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/tom/note_unix_network_program_1/C9_SCTP_API/code /home/tom/note_unix_network_program_1/C9_SCTP_API/code /home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug /home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug /home/tom/note_unix_network_program_1/C9_SCTP_API/code/cmake-build-debug/CMakeFiles/time_server.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/time_server.dir/depend

