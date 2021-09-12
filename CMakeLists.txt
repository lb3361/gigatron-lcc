
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


# --- Compute relative path from bindir to srcdir

file(RELATIVE_PATH srcrel "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/foo")
string(REGEX REPLACE "/*foo$" "" srcrel "${srcrel}")


# --- Find Python

find_package(Python3 3.8 REQUIRED QUIET COMPONENTS Interpreter)

file(TO_NATIVE_PATH "${Python3_EXECUTABLE}" python3path)

set(PYTHON3 "${python3path}" CACHE STRING "Python 3 executable path")

message(STATUS "Using python executable: ${PYTHON3}")


# --- Compile lburg

add_executable(lburg lburg/lburg.c lburg/gram.c)

target_include_directories(lburg PUBLIC lburg)


# --- Run lburg

file(GLOB srcs_md CONFIGURE_DEPENDS
  RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/src"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.md" )

foreach(md ${srcs_md})
  get_filename_component(mdn "${md}" NAME_WLE)
  set(output "${mdn}.c")
  list(APPEND srcs_lburg "${output}")
  add_custom_command(OUTPUT "${output}"
    COMMAND lburg "${srcrel}/src/${md}" "${output}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/src/${md}"
    DEPENDS lburg VERBATIM)
endforeach()


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
    COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${srcrel}/gigatron/${fn}" "${output}"
    MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${fn}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    VERBATIM)
endforeach()

if (WIN32)
  foreach(fn glcc.cmd glink.cmd)
    list(APPEND gigatron_targets "${fn}")
    add_custom_command(OUTPUT "${fn}"
      COMMAND "${CMAKE_COMMAND}" "-E" "echo" "@\"${PYTHON3}\" \"%~dp0\\%~n0\" %*" ">" "${fn}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      VERBATIM)
  endforeach()
endif()

add_custom_target(glcc-ready ALL
  COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory" "${srcrel}/include/gigatron/" "include"
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
  DEPENDS "cpp" "rcc" "lcc" ${gigatron_targets}
  VERBATIM)

function(copy_target_to_bindir target)
  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:${target}>" "$<TARGET_FILE_NAME:${target}>"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    VERBATIM)
endfunction()

copy_target_to_bindir(cpp)
copy_target_to_bindir(rcc)
copy_target_to_bindir(lcc)
copy_target_to_bindir(gtsim)


# --- Stage map directories

function(add_glcc_map mapname)
  set(map_targets "")
  file(GLOB mapfiles CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/"
    "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${mapname}/*.py")
  foreach(fn ${mapfiles})
    list(APPEND map_targets "${fn}")
    add_custom_command(OUTPUT ${fn}
      COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${srcrel}/gigatron/${fn}" "${fn}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
      MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${fn}"
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
  list(GET ARGN 0 car)
  if ("${car}" STREQUAL "CPU")
    list(POP_FRONT ARGN car cpulist)
  endif()
  set(objlist "")
  set(asmlist "")
  set(objdir "CMakeFiles/${libname}.glccdir")
  file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${objdir}")
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
	    COMMAND "./glcc" "-c" "-cpu=${cpu}" "-o" "${obj}" "${srcrel}/${fn}"
	    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
	    MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/${fn}"
	    DEPENDS glcc-ready)
	  list(APPEND objlist "${obj}")
	endforeach()
      elseif ("${fnext}" STREQUAL ".s")
	list(APPEND asmlist "${srcrel}/${fn}")
      else()
	message(FATAL_ERROR "Library file ${fname}${fext} has an unrecognized suffix")
      endif()
    endforeach()
  endforeach()
  set(script "
set(objs \"${objlist}\" \"${asmlist}\")
foreach(obj \${objs})
  file(READ \"\${obj}\" contents)
  file(APPEND \"${libfile}\" \"\${contents}\")
endforeach()
")
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${objdir}/link.cmake" "${script}")
  add_custom_target(${libname} ALL
    COMMAND ${CMAKE_COMMAND} "-P" "${objdir}/link.cmake"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    DEPENDS ${objlist} VERBATIM)
endfunction()

add_glcc_library("libconx" "mapconx/libconx.a" "gigatron/mapconx/libconx/*.c")
add_glcc_library("libsim" "mapsim/libsim.a" "gigatron/mapsim/libsim/*.c"  "gigatron/mapsim/libsim/*.s")
add_glcc_library("libc-cpu4" "cpu4/libc.a" CPU 4 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc-cpu5" "cpu5/libc.a" CPU 5 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc-cpu6" "cpu6/libc.a" CPU 6 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s") 


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
    set(pysh "")
    set(pycmd "")
    if (NOT "${pgm}" STREQUAL gtsim)
      set(pysh "\\\"${Python3_EXECUTABLE}\\\" ")
      set(pycmd "\\\"${PYTHON3}\\\" ")
    endif()
    set(output "\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_cmddir}/${pgm}.cmd")
    install(CODE "message(STATUS \"Installing: ${output}\")
                  execute_process(COMMAND ${CMAKE_COMMAND} -E echo
                                     \"@${pycmd}\\\"%~dp0\\\\${cmd_to_lib}\\\\%~n0\\\" %*\"
                                  OUTPUT_FILE \"${output}\") ")
    set(output "\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${glcc_install_bindir}/${pgm}")
    install(CODE "message(STATUS \"Installing: ${output}\")
                  set(EXECCMD \"${pysh}\\\"\\\$progdir/${bin_to_lib}/${pgm}\\\"\")
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
