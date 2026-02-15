# FindSDL2_image.cmake - Emscripten SDL2_image Support

if(EMSCRIPTEN)
    message(STATUS "Using Emscripten's built-in SDL2_image (via -sUSE_SDL_IMAGE=2)")
    
    # Erstelle Interface-Target für SDL2_image
    if(NOT TARGET SDL2_image::SDL2_image)
        add_library(SDL2_image::SDL2_image INTERFACE IMPORTED GLOBAL)
    endif()
    
    # Setze Standard SDL2_image Variablen
    set(SDL2_image_FOUND TRUE)
    set(SDL2_image_DIR "emscripten-builtin")
    set(SDL2_image_INCLUDE_DIRS "")
    set(SDL2_image_LIBRARIES SDL2_image::SDL2_image)
    set(SDL2_image_VERSION "2.0.0")
    
    mark_as_advanced(SDL2_image_DIR SDL2_image_INCLUDE_DIRS SDL2_image_LIBRARIES)
    
    message(STATUS "SDL2_image_FOUND = ${SDL2_image_FOUND}")
else()
    # Für nicht-Emscripten Builds
    find_package(PkgConfig QUIET)
    if(PKG_CONFIG_FOUND)
        pkg_check_modules(SDL2_image QUIET SDL2_image)
    endif()
    
    if(NOT SDL2_image_FOUND)
        message(WARNING "SDL2_image not found. Image loading support will be limited.")
    endif()
endif()
