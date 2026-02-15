FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    ninja-build \
    python3 \
    wget \
    xz-utils \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash freeserf
USER freeserf
WORKDIR /home/freeserf

# Install Emscripten SDK
RUN git clone https://github.com/emscripten-core/emsdk.git /home/freeserf/emsdk
WORKDIR /home/freeserf/emsdk

RUN ./emsdk install latest
RUN ./emsdk activate latest
RUN echo 'source /home/freeserf/emsdk/emsdk_env.sh' >> /home/freeserf/.bashrc

# Copy Freeserf source code
WORKDIR /home/freeserf
COPY --chown=freeserf . ./freeserf

WORKDIR /home/freeserf/freeserf
RUN git submodule update --init --recursive || true

# Copy CMake modules for Emscripten SDL2 support
# Diese werden benötigt, damit find_package(SDL2) bei Emscripten funktioniert
RUN mkdir -p cmake && \
    if [ -f cmake-FindSDL2.cmake ]; then \
        cp cmake-FindSDL2.cmake cmake/FindSDL2.cmake && \
        echo "✓ Installed FindSDL2.cmake"; \
    fi && \
    if [ -f cmake-FindSDL2_mixer.cmake ]; then \
        cp cmake-FindSDL2_mixer.cmake cmake/FindSDL2_mixer.cmake && \
        echo "✓ Installed FindSDL2_mixer.cmake"; \
    fi && \
    if [ -f cmake-FindSDL2_image.cmake ]; then \
        cp cmake-FindSDL2_image.cmake cmake/FindSDL2_image.cmake && \
        echo "✓ Installed FindSDL2_image.cmake"; \
    fi

# ============================================================================
# BUILD CONFIGURATION
# ============================================================================

# Emscripten flags optimized for Freeserf
ENV EMSCRIPTEN_FLAGS="\
-s WASM=1 \
-s USE_SDL=2 \
-s USE_SDL_MIXER=2 \
-s ALLOW_MEMORY_GROWTH=1 \
-s INITIAL_MEMORY=67108864 \
-s MAXIMUM_MEMORY=536870912 \
-s STACK_SIZE=5242880 \
-s EXPORTED_FUNCTIONS=['_main'] \
-s EXPORTED_RUNTIME_METHODS=['ccall','cwrap','FS'] \
-s MODULARIZE=1 \
-s EXPORT_NAME='FreeSerf' \
-s ENVIRONMENT='web' \
-s FILESYSTEM=1 \
-s FORCE_FILESYSTEM=1 \
-s EXIT_RUNTIME=0 \
-s ASSERTIONS=0 \
-s DISABLE_EXCEPTION_CATCHING=0 \
-lidbfs.js"

# Compiler optimization flags
ENV CFLAGS="-O3 -flto"
ENV CXXFLAGS="-O3 -flto -std=c++11"
ENV LDFLAGS="$EMSCRIPTEN_FLAGS -O3 -flto"

# Configure with CMake
RUN bash -lc "source /home/freeserf/emsdk/emsdk_env.sh && \
    emcmake cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/home/freeserf/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake \
        -DENABLE_TESTS=OFF \
        -DENABLE_SDL2_IMAGE=OFF \
        -DCMAKE_C_FLAGS=\"\$CFLAGS\" \
        -DCMAKE_CXX_FLAGS=\"\$CXXFLAGS\" \
        -DCMAKE_EXE_LINKER_FLAGS=\"\$LDFLAGS\" \
        -G Ninja \
        -S . \
        -B build"

# Build
RUN bash -lc "source /home/freeserf/emsdk/emsdk_env.sh && \
    emmake ninja -C build"

# ============================================================================
# OUTPUT PREPARATION
# ============================================================================

# Create output directory
RUN mkdir -p /home/freeserf/output

# Copy compiled WASM files
RUN find build -name "*.wasm" -exec cp {} /home/freeserf/output/ \;
RUN find build -name "*.js" -not -path "*/CMakeFiles/*" -exec cp {} /home/freeserf/output/ \;

# Copy our custom index.html
RUN if [ -f "index.html" ]; then \
        cp index.html /home/freeserf/output/; \
        echo "✓ Copied index.html from repository"; \
    fi

# Copy data files as separate assets (NICHT einbetten!)
# Diese werden zur Laufzeit mit FS_createPreloadedFile geladen
RUN if [ -d "data" ]; then \
        mkdir -p /home/freeserf/output/data; \
        cp -r data/* /home/freeserf/output/data/; \
        echo "✓ Copied game data files (will be loaded at runtime)"; \
    fi

# Copy index.html from repository if it exists
RUN if [ -f "index.html" ]; then \
        cp index.html /home/freeserf/output/; \
        echo "✓ Using index.html from repository"; \
    elif [ -f "web/index.html" ]; then \
        cp web/index.html /home/freeserf/output/; \
        echo "✓ Using index.html from web/ directory"; \
    else \
        echo "⚠ WARNING: No index.html found in repository!"; \
        echo "⚠ Please add index.html to project root or web/ directory"; \
    fi

# Copy additional web assets if they exist
RUN if [ -d "web" ]; then \
        cp -r web/* /home/freeserf/output/ 2>/dev/null || true; \
        echo "✓ Copied web assets from web/ directory"; \
    fi

# List all output files
RUN echo "=== Build Output ===" && ls -lh /home/freeserf/output/

# ============================================================================
# FINAL MINIMAL IMAGE
# ============================================================================

FROM ubuntu:22.04
LABEL maintainer="freeserf-wasm"
LABEL description="Freeserf WebAssembly Build"

RUN apt-get update && apt-get install -y \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash freeserf
USER freeserf
WORKDIR /home/freeserf

# Copy only the compiled output
COPY --from=builder --chown=freeserf /home/freeserf/output ./freeserf-wasm

# Create a simple web server script
RUN echo '#!/bin/bash\n\
cd /home/freeserf/freeserf-wasm\n\
echo "Starting web server on http://0.0.0.0:8080"\n\
echo "Open browser at http://localhost:8080"\n\
python3 -m http.server 8080\n\
' > /home/freeserf/serve.sh && chmod +x /home/freeserf/serve.sh

EXPOSE 8080

CMD ["/bin/bash"]
