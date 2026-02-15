# FindSDL2.cmake - Emscripten SDL2 Support
#
# Dieses Modul wird verwendet wenn mit Emscripten gebaut wird.
# Es erstellt Dummy-Targets für SDL2, da Emscripten SDL2 integriert hat.

if(EMSCRIPTEN)
    message(STATUS "Using Emscripten's built-in SDL2 (via -sUSE_SDL=2)")
    
    # Erstelle Interface-Targets für SDL2
    if(NOT TARGET SDL2::SDL2)
        add_library(SDL2::SDL2 INTERFACE IMPORTED GLOBAL)
        set_target_properties(SDL2::SDL2 PROPERTIES
            INTERFACE_COMPILE_OPTIONS ""
        )
    endif()
    
    if(NOT TARGET SDL2::SDL2main)
        add_library(SDL2::SDL2main INTERFACE IMPORTED GLOBAL)
    endif()
    
    # Setze Standard SDL2 Variablen die find_package erwartet
    set(SDL2_FOUND TRUE)
    set(SDL2_DIR "emscripten-builtin")
    set(SDL2_INCLUDE_DIRS "")
    set(SDL2_LIBRARIES SDL2::SDL2)
    set(SDL2_VERSION "2.0.0")
    
    mark_as_advanced(SDL2_DIR SDL2_INCLUDE_DIRS SDL2_LIBRARIES)
    
    message(STATUS "SDL2_FOUND = ${SDL2_FOUND}")
    message(STATUS "SDL2_DIR = ${SDL2_DIR}")
else()
    # Für nicht-Emscripten Builds: Nutze pkg-config oder standard find
    message(STATUS "Looking for system SDL2...")
    
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(SDL2 QUIET sdl2)
    endif()
    
    if(NOT SDL2_FOUND)
        message(FATAL_ERROR "SDL2 not found. Install SDL2 development package or use Emscripten.")
    endif()
endif()

