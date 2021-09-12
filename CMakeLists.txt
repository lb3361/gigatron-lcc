
cmake_minimum_required(VERSION 3.16)

project(glcc)
enable_language(C)


# --- Default to RelWithDebInfo

if (NOT "${CMAKE_BUILD_TYPE}")
  SET(CMAKE_BUILD_TYPE "RelWithDebInfo")
endif()


# --- Only support out-of-directory builds

if (${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_BINARY_DIR})
  message(FATAL_ERROR "\
Compilation in the source directory is not supported.\
Please create a 'build' directory and run 'cmake SRCDIR' from there.")
endif()


# --- Find Python

set(Python3_EXECUTABLE "" CACHE STRING "Python 3 executable path")
find_package(Python3 3.8 REQUIRED QUIET COMPONENTS Interpreter)
message(STATUS "Found python executable ${Python3_EXECUTABLE}")


# --- Compile lburg

add_executable(lburg lburg/lburg.c lburg/gram.c)

target_include_directories(lburg PUBLIC lburg)


# --- Run lburg

file(GLOB srcs_md CONFIGURE_DEPENDS
  RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.md" )

foreach(md ${srcs_md})
  set(output "${CMAKE_CURRENT_BINARY_DIR}/${md}.c")
  list(APPEND srcs_lburg "${output}")
  add_custom_command(OUTPUT "${output}"
    COMMAND lburg "${CMAKE_CURRENT_SOURCE_DIR}/src/${md}" "${output}"
    DEPENDS lburg VERBATIM)
endforeach()


# --- Bypass Debug/Release dirs for MSVC

string(TOUPPER "${CMAKE_BUILD_TYPE}" cmake_config)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
set("CMAKE_RUNTIME_OUTPUT_DIRECTORY_${cmake_config}" "${CMAKE_CURRENT_BINARY_DIR}")


# --- Compile cpp

add_executable(cpp
  cpp/cpp.c cpp/lex.c cpp/nlist.c cpp/tokens.c cpp/macro.c cpp/eval.c
  cpp/include.c cpp/hideset.c cpp/getopt.c cpp/unix.c )

target_include_directories(cpp PUBLIC cpp)


# --- Compile rcc

add_executable(rcc
  src/alloc.c src/bind.c src/dag.c src/decl.c src/enode.c src/error.c
  src/expr.c src/event.c src/init.c src/inits.c src/input.c src/lex.c
  src/list.c src/main.c src/output.c src/prof.c src/profio.c
  src/simp.c src/stmt.c src/string.c src/sym.c src/trace.c src/tree.c
  src/types.c src/null.c src/symbolic.c src/stab.c src/gen.c src/bytecode.c
  ${srcs_lburg} )

target_include_directories(rcc PUBLIC src)

if ("${CMAKE_C_COMPILER_ID}" MATCHES "GNU")
  target_compile_options(rcc PRIVATE "-Wno-psabi")
endif()


# --- Compile lcc

add_executable(lcc
  etc/lcc.c etc/gigatron-lcc.c )

target_compile_definitions(lcc PUBLIC
  "-DTARGET=gigatron")


# --- Compile gtsim

add_executable(gtsim
  gigatron/mapsim/gtsim.c )


# --- Stage binary directory to make glcc usable

set(gigatron_targets
  glcc glink glink.py
  interface.json roms.json)

foreach(fn ${gigatron_targets})
  set(output "${CMAKE_CURRENT_BINARY_DIR}/${fn}")
  add_custom_command(OUTPUT "${output}"
    COMMAND "${CMAKE_COMMAND}" "-E" "copy"
    "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${fn}"
    "${output}"
    VERBATIM)
endforeach()

if (WIN32)
  set(win32_target glcc-cmd)
  add_custom_target(glcc-cmd
    COMMAND "${CMAKE_COMMAND}" "-E" "echo"
    "@\"${Python3_EXECUTABLE}\" \"%~dp0\\%~n0\" %*" ">" "glcc.cmd"
    COMMAND "${CMAKE_COMMAND}" "-E" "echo"
    "@\"${Python3_EXECUTABLE}\" \"%~dp0\\%~n0\" %*" ">" "glink.cmd"
    VERBATIM)
endif()

add_custom_target(glcc-ready ALL
  COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/gigatron/"
  "${CMAKE_CURRENT_BINARY_DIR}/include"
  DEPENDS "cpp" "rcc" "lcc" ${gigatron_targets} ${win32_target}
  VERBATIM)


# --- Stage map directories

function(add_glcc_map mapname)
  set(map_targets "")
  file(GLOB mapfiles CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/"
    "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${mapname}/*.py")
  foreach(fn ${mapfiles})
    list(APPEND map_targets "${fn}")
    add_custom_command(OUTPUT ${fn}
      COMMAND "${CMAKE_COMMAND}" "-E"
      "copy" "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${fn}"
      "${CMAKE_CURRENT_BINARY_DIR}/${fn}"
      VERBATIM )
  endforeach()
  add_custom_target("${mapname}" ALL
    DEPENDS ${map_targets} VERBATIM)
endfunction()

file(GLOB gigatron_maps CONFIGURE_DEPENDS
  RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/"
  "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/map*" )
foreach(map ${gigatron_maps})
  add_glcc_map("${map}")
endforeach()

# ---- Compile gigatron libraries

function(add_glcc_library libname libfile)
  set(cpu "")
  set(cpulist 4 5 6)
  file(RELATIVE_PATH btos "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}")
  list(GET ARGN 0 car)
  if ("${car}" STREQUAL "CPU")
    list(POP_FRONT ARGN car cpulist)
  endif()
  set(objlist "")
  set(asmlist "")
  set(objdir "CMakeFiles/${libname}.glccdir")
  file(MAKE_DIRECTORY "${objdir}")
  foreach(fnp ${ARGN})
    file(GLOB fn_list CONFIGURE_DEPENDS
      RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}/${fnp}")
    foreach(fn ${fn_list})
      get_filename_component(fname "${fn}" NAME_WLE)
      get_filename_component(fnext "${fn}" LAST_EXT)
      if ("${fnext}" STREQUAL ".c")
	foreach(cpu ${cpulist})
	  set(obj "${objdir}/${fname}_${cpu}.o")
	  add_custom_command(OUTPUT "${obj}"
	    COMMAND "${CMAKE_CURRENT_BINARY_DIR}/glcc" "-c" "-cpu=${cpu}"
	    "-o" "${CMAKE_CURRENT_BINARY_DIR}/${obj}"
	    "${CMAKE_CURRENT_SOURCE_DIR}/${fn}"
	    DEPENDS glcc-ready)
	  list(APPEND objlist "${obj}")
	endforeach()
      elseif ("${fnext}" STREQUAL ".s")
	list(APPEND asmlist "${btos}/${fn}")
      else()
	message(FATAL_ERROR "Library file ${fname}${fext} has an unrecognized suffix")
      endif()
    endforeach()
  endforeach()
  set(script "
set(objs \"${objlist}\" \"${asmlist}\")
foreach(obj \${objs})
  file(READ \"\${CMAKE_CURRENT_BINARY_DIR}/\${obj}\" contents)
  file(APPEND \"${CMAKE_CURRENT_BINARY_DIR}/${libfile}\" \"\${contents}\")
endforeach()
")
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${objdir}/link.cmake" "${script}")
  add_custom_target(${libname} ALL
    COMMAND ${CMAKE_COMMAND} "-P" "${objdir}/link.cmake"
    DEPENDS ${objlist} VERBATIM)
endfunction()

add_glcc_library("libconx" "mapconx/libconx.a" "gigatron/mapconx/libconx/*.c")
add_glcc_library("libsim" "mapsim/libsim.a" "gigatron/mapsim/libsim/*.c"  "gigatron/mapsim/libsim/*.s")
add_glcc_library("libc4" "cpu4/libc.a" CPU 4 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc5" "cpu5/libc.a" CPU 5 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc6" "cpu6/libc.a" CPU 6 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s") 


# ---- Installation

set(glcc_install_libdir "lib/gigatron-lcc")
set(glcc_install_bindir "bin")
set(glcc_install_cmddir "cmd")

install(TARGETS cpp rcc lcc gtsim
  RUNTIME DESTINATION "${glcc_install_libdir}")

foreach(fn ${gigatron_targets})
  get_filename_component(ext "${fn}" EXT)
  if ("${ext}" STREQUAL ".json")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${fn}"
      DESTINATION "${glcc_install_libdir}")
  else()
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/${fn}"
      DESTINATION "${glcc_install_libdir}")
  endif()
endforeach()

foreach(dn include cpu4 cpu5 cpu6 ${gigatron_maps})
  install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${dn}"
    DESTINATION "${glcc_install_libdir}")
endforeach()

if (WIN32)
  file(RELATIVE_PATH bin_to_lib "/${glcc_install_bindir}" "/${glcc_install_libdir}")
  file(RELATIVE_PATH cmd_to_lib "/${glcc_install_cmddir}" "/${glcc_install_libdir}")
  string(REPLACE "/" "\\\\" cmd_to_lib "${cmd_to_lib}")
  install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
             \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_cmddir}\")")
  install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
             \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_bindir}\")")
  foreach(pgm glcc glink gtsim)
    if ("${pgm}" STREQUAL gtsim)
      set(py "")
    else()
      set(py "\\\"${Python3_EXECUTABLE}\\\" ")
    endif()
    set(output "\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_cmddir}/${pgm}.cmd")
    install(CODE "message(STATUS \"Installing: ${output}\")
                  execute_process(COMMAND ${CMAKE_COMMAND} -E echo
                                     \"@${py}\\\"%~dp0\\\\${cmd_to_lib}\\\\%~n0\\\" %*\"
                                  OUTPUT_FILE \"${output}\") ")
    set(output "\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_bindir}/${pgm}")
    install(CODE "message(STATUS \"Installing: ${output}\")
                  set(EXECCMD \"${py}\\\"\\\$progdir/${bin_to_lib}/${pgm}\\\"\")
                  configure_file(\"${CMAKE_CURRENT_SOURCE_DIR}/gigatron/exec-sh.in\"
                    \"${output}\" @ONLY)" )
  endforeach()
else()
  file(RELATIVE_PATH bin_to_lib "/${glcc_install_bindir}" "/${glcc_install_libdir}")
  install(CODE "execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory
            \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_bindir}\")")
  foreach(pgm glcc glink gtsim)
    set(output "\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_bindir}/${pgm}")
    install(CODE "message(STATUS \"Creating symlink: ${output}\")
                  execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
                     \"${bin_to_lib}/${pgm}\" \"${output}\" )")
  endforeach()
endif()
