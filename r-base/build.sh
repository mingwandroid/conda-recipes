#!/bin/bash

# Without setting these, R goes off and tries to find things on its own, which
# we don't want (we only want it to find stuff in the build environment).

export CFLAGS="-I$PREFIX/include"
export CPPFLAGS="-I$PREFIX/include"
export FFLAGS="-I$PREFIX/include -L$PREFIX/lib"
export FCFLAGS="-I$PREFIX/include -L$PREFIX/lib"
export OBJCFLAGS="-I$PREFIX/include"
export CXXFLAGS="-I$PREFIX/include"
export LDFLAGS="$LDFLAGS -L$PREFIX/lib -lgfortran"
export LAPACK_LDFLAGS="-L$PREFIX/lib -lgfortran"
export PKG_CPPFLAGS="-I$PREFIX/include"
export PKG_LDFLAGS="-L$PREFIX/lib -lgfortran"
export TCL_CONFIG=$PREFIX/lib/tclConfig.sh
export TK_CONFIG=$PREFIX/lib/tkConfig.sh
export TCL_LIBRARY=$PREFIX/lib/tcl8.5
export TK_LIBRARY=$PREFIX/lib/tk8.5

Linux() {
    # There's probably a much better way to do this.
    . ${RECIPE_DIR}/java.rc
    if [ -n "$JDK_HOME" -a -n "$JAVA_HOME" ]; then
        export JAVA_CPPFLAGS="-I$JDK_HOME/include -I$JDK_HOME/include/linux"
        export JAVA_LD_LIBRARY_PATH=${JAVA_HOME}/lib/amd64/server
    else
        echo warning: JDK_HOME and JAVA_HOME not set
    fi

    mkdir -p $PREFIX/lib

    ./configure --prefix=$PREFIX                \
                --enable-shared                 \
                --enable-R-shlib                \
                --enable-BLAS-shlib             \
                --disable-R-profiling           \
                --disable-prebuilt-html         \
                --disable-memory-profiling      \
                --with-tk-config=$TK_CONFIG     \
                --with-tcl-config=$TCL_CONFIG   \
                --with-x                        \
                --with-pic                      \
                --with-cairo                    \
                LIBnn=lib
}

# This was an attempt to see how far we could get with using Autotools as things
# stand. On 3.2.2, the build system attempts to compile the Uix code which works
# to an extent, finally falling over due to fd_set references in sys-std.c when
# it should be compiling sys-win32.c instead. Eventually it would be nice to fix
# the Autotools build framework so that can be used for Windows builds too.
Mingw_w64_autotools() {
    . ${RECIPE_DIR}/java.rc
    if [ -n "$JDK_HOME" -a -n "$JAVA_HOME" ]; then
        export JAVA_CPPFLAGS="-I$JDK_HOME/include -I$JDK_HOME/include/linux"
        export JAVA_LD_LIBRARY_PATH=${JAVA_HOME}/lib/amd64/server
    else
        echo warning: JDK_HOME and JAVA_HOME not set
    fi

    mkdir -p $PREFIX/lib
    export TCL_CONFIG=$PREFIX/Library/mingw-w64/lib/tclConfig.sh
    export TK_CONFIG=$PREFIX/Library/mingw-w64/lib/tkConfig.sh
    export TCL_LIBRARY=$PREFIX/Library/mingw-w64/lib/tcl8.6
    export TK_LIBRARY=$PREFIX/Library/mingw-w64/lib/tk8.6
    export CPPFLAGS="$CPPFLAGS -I${SRC_DIR}/src/gnuwin32/fixed/h"
    if [[ "${ARCH}" == "64" ]]; then
        export CPPFLAGS="$CPPFLAGS -DWIN=64 -DMULTI=64"
    fi
    ./configure --prefix=$PREFIX                \
                --enable-shared                 \
                --enable-R-shlib                \
                --enable-BLAS-shlib             \
                --disable-R-profiling           \
                --disable-prebuilt-html         \
                --disable-memory-profiling      \
                --with-tk-config=$TK_CONFIG     \
                --with-tcl-config=$TCL_CONFIG   \
                --with-x=no                     \
                --with-readline=no              \
                LIBnn=lib
}

# Use the hand-crafted makefiles.
Mingw_w64_makefiles() {
    if [[ "${ARCH}" == "64" ]]; then
        export CPPFLAGS="$CPPFLAGS -DWIN=64 -DMULTI=64"
    fi
    cd "${SRC_DIR}/src/gnuwin32"
    make distribution
    cd installer
    make imagedir
    cp -rf R-3.2.2 "${PREFIX}"/R
}

Darwin() {
    # Without this, it will not find libgfortran. We do not use
    # DYLD_LIBRARY_PATH because that screws up some of the system libraries
    # that have older versions of libjpeg than the one we are using
    # here. DYLD_FALLBACK_LIBRARY_PATH will only come into play if it cannot
    # find the library via normal means. The default comes from 'man dyld'.
    export DYLD_FALLBACK_LIBRARY_PATH=$PREFIX/lib:$(HOME)/lib:/usr/local/lib:/lib:/usr/lib

    # Prevent configure from finding Fink or Homebrew.

    export PATH=$PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin

    cat >> config.site <<EOF
CC=clang
CXX=clang++
F77=gfortran
OBJC=clang
EOF

    ./configure --prefix=$PREFIX                    \
                --with-blas="-framework Accelerate" \
                --with-lapack                       \
                --enable-R-shlib                    \
                --without-x                         \
                --enable-R-framework=no
}

case `uname` in
    Darwin)
        Darwin
        ;;
    Linux)
        Linux
        ;;
    MINGW*)
        # Mingw_w64_autotools
        Mingw_w64_makefiles
        ;;
esac

make -j4
make install
