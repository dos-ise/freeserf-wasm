# FindSDL2_mixer.cmake - Emscripten SDL2_mixer Support

if(EMSCRIPTEN)
    message(STATUS "Using Emscripten's built-in SDL2_mixer (via -sUSE_SDL_MIXER=2)")
    
    # Erstelle Interface-Target für SDL2_mixer
    if(NOT TARGET SDL2_mixer::SDL2_mixer)
        add_library(SDL2_mixer::SDL2_mixer INTERFACE IMPORTED GLOBAL)
    endif()
    
    # Setze Standard SDL2_mixer Variablen
    set(SDL2_mixer_FOUND TRUE)
    set(SDL2_mixer_DIR "emscripten-builtin")
    set(SDL2_mixer_INCLUDE_DIRS "")
    set(SDL2_mixer_LIBRARIES SDL2_mixer::SDL2_mixer)
    set(SDL2_mixer_VERSION "2.0.0")
    
    mark_as_advanced(SDL2_mixer_DIR SDL2_mixer_INCLUDE_DIRS SDL2_mixer_LIBRARIES)
    
    message(STATUS "SDL2_mixer_FOUND = ${SDL2_mixer_FOUND}")
else()
    # Für nicht-Emscripten Builds
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(SDL2_mixer QUIET SDL2_mixer)
    endif()
    
    if(NOT SDL2_mixer_FOUND)
        message(WARNING "SDL2_mixer not found. Audio support will be limited.")
    endif()
endif()
