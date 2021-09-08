
cmake_minimum_required(VERSION 3.10)

project(glcc)
enable_language(C)

if (NOT "${CMAKE_BUILD_TYPE}")
  SET(CMAKE_BUILD_TYPE "Release")
endif()

# --- only support out-of-directory builds

if (${PROJECT_SOURCE_DIR} STREQUAL ${PROJECT_BINARY_DIR})
  message(FATAL_ERROR "\
Compilation in the source directory is not supported.\
Please create a 'build' directory and run 'cmake SRCDIR' from there.")
endif()

# --- CPP

add_executable(cpp
  cpp/cpp.c cpp/lex.c cpp/nlist.c cpp/tokens.c cpp/macro.c cpp/eval.c 
  cpp/include.c cpp/hideset.c cpp/getopt.c cpp/unix.c )

target_include_directories(cpp PUBLIC cpp)


# --- LBURG

add_executable(lburg lburg/lburg.c lburg/gram.c)

target_include_directories(lburg PUBLIC lburg)

set(srcs_md_c "")

file(GLOB srcs_md  CONFIGURE_DEPENDS "src/*.md")
foreach(md ${srcs_md})
  get_filename_component(output "${md}" NAME_WLE)
  set(output "${CMAKE_CURRENT_BINARY_DIR}/${output}.c")
  list(APPEND srcs_lburg "${output}")
  add_custom_command(OUTPUT "${output}"
    COMMAND lburg "${md}" "${output}"
    DEPENDS lburg VERBATIM)
endforeach()

# --- RCC

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

# --- LCC

add_executable(lcc
  etc/lcc.c etc/gigatron-lcc.c )

target_compile_definitions(lcc PUBLIC
  "-DTARGET=gigatron")


# --- GTSIM

add_executable(gtsim
  gigatron/mapsim/gtsim.c )


# --- STAGE DIRECTORY

set(gigatron_targets
  glcc glink glink.py
  interface.json roms.json)

foreach(fn ${gigatron_targets})
  get_filename_component(output "${fn}" NAME)
  set(output "${CMAKE_CURRENT_BINARY_DIR}/${output}")
  add_custom_command(OUTPUT "${output}"
    COMMAND "${CMAKE_COMMAND}" "-E" "copy"
    "${CMAKE_CURRENT_SOURCE_DIR}/gigatron/${fn}"
    "${output}"
    VERBATIM)
endforeach()

if (WIN32)
  list(APPEND gigatron_targets glcc-cmd)
  add_custom_target(glcc-cmd
    COMMAND "${CMAKE_COMMAND}" "-E" "echo"
    "@py -3 \"%~dp0\\%~n0\" %*" ">" "glcc.cmd"
    COMMAND "${CMAKE_COMMAND}" "-E" "echo"
    "@py -3 \"%~dp0\\%~n0\" %*" ">" "glink.cmd"
    VERBATIM)
endif()

add_custom_target(glcc-ready ALL
  COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/gigatron/"
  "${CMAKE_CURRENT_BINARY_DIR}/include"
  DEPENDS "cpp" "rcc" "lcc" ${gigatron_targets}
  VERBATIM)

# --- MAPS

function(add_glcc_map mapname)
  set(map_targets "")
  file(GLOB mapfiles  CONFIGURE_DEPENDS "gigatron/${mapname}/*.py")
  foreach(fn ${mapfiles})
    get_filename_component(output "${fn}" NAME)
    set(output "${CMAKE_CURRENT_BINARY_DIR}/${mapname}/${output}")
    list(APPEND map_targets "${output}")
    add_custom_command(OUTPUT ${output}
      COMMAND "${CMAKE_COMMAND}" "-E" "copy" "${fn}" "${output}"
      VERBATIM)
  endforeach()
  add_custom_target("${mapname}" ALL
    DEPENDS ${map_targets} VERBATIM)
endfunction()

file(GLOB gigatron_maps  CONFIGURE_DEPENDS "gigatron/map*")
foreach(map ${gigatron_maps})
  get_filename_component(mapname "${map}" NAME)
  add_glcc_map("${mapname}")
endforeach()

# ---- LIBRARIES

function(add_glcc_library libname libfile)
  set(cpu "")
  set(cpulist 4 5 6)
  set(objdirsuffix "")
  list(GET ARGN 0 car)
  if ("${car}" STREQUAL "CPU")
    list(POP_FRONT ARGN car cpulist)
  endif()
  set(objlist "")
  set(objdir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${libname}.glccdir")
  file(MAKE_DIRECTORY "${objdir}")
  foreach(fnp ${ARGN})
    file(GLOB fn_list CONFIGURE_DEPENDS "${fnp}")
    foreach(fn ${fn_list})
      get_filename_component(fname "${fn}" NAME_WLE)
      get_filename_component(fnext "${fn}" LAST_EXT)
      if ("${fnext}" STREQUAL ".c")
	foreach(cpu ${cpulist})
	  set(obj "${objdir}/${fname}_${cpu}.o")
	  add_custom_command(OUTPUT "${obj}"
	    COMMAND "${CMAKE_CURRENT_BINARY_DIR}/glcc" "-c" "-cpu=${cpu}" "-o" "${obj}" "${fn}"
	    DEPENDS glcc-ready)
	  list(APPEND objlist "${obj}")
	endforeach()
      elseif ("${fnext}" STREQUAL ".s")
	list(APPEND objlist "${fn}")
      else()
	message(FATAL_ERROR "Library file ${fname}${fext} has an unrecognized suffix")
      endif()
    endforeach()
  endforeach()
  set(script "
set(objlist \"${objlist}\")
foreach(obj \${objlist})
  file(READ \"\${obj}\" contents)
  file(APPEND \"${CMAKE_CURRENT_BINARY_DIR}/${libfile}\" \"\${contents}\")
endforeach()
")
  file(WRITE "${objdir}/link.cmake" "${script}")
  add_custom_target(${libname} ALL
    COMMAND ${CMAKE_COMMAND} "-P" "${objdir}/link.cmake"
    DEPENDS ${objlist} VERBATIM)
endfunction()

add_glcc_library("libconx" "mapconx/libconx.a" "gigatron/mapconx/libconx/*.c")
add_glcc_library("libsim" "mapsim/libsim.a" "gigatron/mapsim/libsim/*.c"  "gigatron/mapsim/libsim/*.s")
add_glcc_library("libc4" "cpu4/libc.a" CPU 4 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc5" "cpu5/libc.a" CPU 5 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s")
add_glcc_library("libc6" "cpu6/libc.a" CPU 6 "gigatron/libc/*.c" "gigatron/libc/*.s" "gigatron/runtime/*.s") 


# ---- INSTALL

set(glcc_install_libdir "${CMAKE_INSTALL_PREFIX}/lib/gigatron-lcc")
set(glcc_install_bindir "${CMAKE_INSTALL_PREFIX}/bin")
set(glcc_install_cmddir "${CMAKE_INSTALL_PREFIX}/cmd")

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


foreach(fdn include cpu4 cpu5 cpu6 ${gigatron_maps})
  get_filename_component(dn "${fdn}" NAME)
  install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${dn}"
    DESTINATION "${glcc_install_libdir}")
endforeach()


if (WIN32)
  file(RELATIVE_PATH bin_to_lib "${glcc_install_bindir}" "${glcc_install_libdir}")
  file(RELATIVE_PATH cmd_to_lib "${glcc_install_cmddir}" "${glcc_install_libdir}")
  string(REPLACE "/" "\\\\" cmd_to_lib "${cmd_to_lib}")
  install(CODE "execute_process( \
     COMMAND ${CMAKE_COMMAND} -E make_directory \"\$ENV{DESTDIR}${glcc_install_cmddir}\")")
  install(CODE "execute_process( \
     COMMAND ${CMAKE_COMMAND} -E make_directory \"\$ENV{DESTDIR}${glcc_install_bindir}\")")
  foreach(pgm glcc glink gtsim)
    if ("${pgm}" STREQUAL gtsim)
      set(py "")
    else()
      set(py "py -3 ")
    endif()
    install(CODE "execute_process( \
     COMMAND ${CMAKE_COMMAND} -E echo \"${py}\\\"%~dp0\\\\${cmd_to_lib}\\\\%~n0\\\" %*\"
             OUTPUT_FILE \"\$ENV{DESTDIR}${glcc_install_cmddir}/${pgm}\") ")
    install(CODE "set(BINTOLIB \"${bin_to_lib}\")
                  configure_file(\"${CMAKE_CURRENT_SOURCE_DIR}/gigatron/exec-sh.in\"
                                 \"\$ENV{DESTDIR}${glcc_install_bindir}/${pgm}\" @ONLY)" )
  endforeach()
else()
  file(RELATIVE_PATH bin_to_lib "${glcc_install_bindir}" "${glcc_install_libdir}")
  install(CODE "execute_process( \
     COMMAND ${CMAKE_COMMAND} -E make_directory
         \"\$ENV{DESTDIR}${glcc_install_bindir}\")")
  foreach(pgm glcc glink gtsim)
    install(CODE "execute_process( \
     COMMAND ${CMAKE_COMMAND} -E create_symlink
         \"${bin_to_lib}/${pgm}\"
         \"\$ENV{DESTDIR}${glcc_install_bindir}/${pgm}\"  )")
  endforeach()
endif()
