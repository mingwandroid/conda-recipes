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

    make -j${CPU_COUNT}
    make install
}

# This was an attempt to see how far we could get with using Autotools as things
# stand. On 3.2.4, the build system attempts to compile the Unix code which works
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
    ./configure --prefix=${PREFIX}              \
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

    make -j${CPU_COUNT}
    make install
}

# Use the hand-crafted makefiles.
Mingw_w64_makefiles() {
    # Instead of copying a MkRules.dist file to MkRules.local
    # just create one with the options we know our toolchains
    # support, and don't set any
    if [[ "${ARCH}" == "64" ]]; then
        CPU="x86-64"
    else
        CPU="i686"
    fi

    # I want to use /tmp and have that mounted to Windows %TEMP% in Conda's MSYS2
    # but there's a permissions issue preventing that from working at present.
    # DLCACHE=/tmp
    DLCACHE=/c/Users/${USER}/Downloads
    [[ -d $DLCACHE ]] || mkdir -p $DLCACHE

    echo "LEA_MALLOC = YES"                      > "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "BINPREF = "                           >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "BINPREF64 = "                         >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "USE_ATLAS = NO"                       >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "BUILD_HTML = YES"                     >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "WIN = ${ARCH}"                        >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "EOPTS = -march=${CPU} -mtune=generic" >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "OPENMP = -fopenmp"                    >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "PTHREAD = -pthread"                   >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "COPY_RUNTIME_DLLS = 1"                >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "TEXI2ANY = texi2any"                  >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "TCL_VERSION = 86"                     >> "${SRC_DIR}/src/gnuwin32/MkRules.local"
    echo "ISDIR = ${PWD}/isdir"                 >> "${SRC_DIR}/src/gnuwin32/MkRules.local"

    set -e
    # The build process copies this across if it finds it and rummaging about on
    # the website I found a file, so why not, eh?
    curl -c "${SRC_DIR}/etc/curl-ca-bundle.crt" -SLO http://www.stats.ox.ac.uk/pub/Rtools/goodies/multilib/curl-ca-bundle.crt

    # The hoops we must jump through to get innosetup installed in an unattended way.
    curl -c ${DLCACHE}/innoextract-1.6-windows.zip -SLO http://constexpr.org/innoextract/files/innoextract-1.6/innoextract-1.6-windows.zip
    unzip -o ${DLCACHE}/innoextract-1.6-windows.zip -d ${PWD}
    curl -c ${DLCACHE}/isetup-5.5.8-unicode.exe -SLO http://files.jrsoftware.org/is/5/isetup-5.5.8-unicode.exe
    ./innoextract.exe ${DLCACHE}/isetup-5.5.8-unicode.exe
    mv app isdir

    # I wanted to go for the following unusual approach here of using conda install (in copy mode)
    # and using MSYS2's mingw-w64 tcl/tk packages, but this is something for longer-term as there
    # is too much work to do around removing baked-in paths and logic around the ActiveState TCL.
    # For example expectations of Tcl/{bin,lib}64 folders in src/gnuwin32/installer/JRins.R and
    # other places I've not yet found.
    #
    # Plan was to install excluding the dependencies (so the necessary DLL dependencies will not
    # be present!). This should not matter since the DLL dependencies have already been installed
    # when r-base itself was installed and will be on the PATH already. The alternative to this
    # is to patch R so that it doesn't look for Tcl executables in in Tcl/bin or Tcl/bin64 and
    # instead looks in the same folder as the R executable which would be my prefered approach.
    # mkdir -p "${SRC_DIR}/Tcl"
    # conda install -c https://conda.anaconda.org/rdonnelly \
    #               --no-deps --yes --copy --prefix "${SRC_DIR}/Tcl" \
    #               m2-mingw-w64-{tcl,tk,bwidget,tktable}
    # mv "${SRC_DIR}"/Tcl/Library/mingw-w64/* "${SRC_DIR}"/Tcl/
    # rm -Rf "${SRC_DIR}"/Tcl/{Library,conda-meta,.BUILDINFO,.MTREE,.PKGINFO}
    # if [[ "${ARCH}" == "64" ]]; then
    #     mv "${SRC_DIR}/Tcl/bin" "${SRC_DIR}/Tcl/bin64"
    # fi
    #
    # .. instead, more innoextract for now.
    #
    curl -c ${DLCACHE}/Rtools33.exe -SLO http://cran.r-project.org/bin/windows/Rtools/Rtools33.exe
    ./innoextract.exe ${DLCACHE}/Rtools33.exe
    if [[ "${ARCH}" == "64" ]]; then
        mv "code\$rhome64/Tcl" "${SRC_DIR}"
    else
        mv "code\$rhome/Tcl" "${SRC_DIR}"
    fi
    exit 1
    # Horrible. We need MiKTeX or something like it (for pdflatex.exe. Building from source
    # may be posslbe but requires CLisp and I've not got time for that at present).  w32tex
    # looks a little less horrible than MiKTex (just read their build instructions and cry:
    # For  example:
    # Cygwin
    # Hint: install all packages, or be prepared to install missing packages later, when
    #       CMake fails to find them...
    # So, let's try with standard w32tex instead: http://w32tex.org/

    # W32TeX doesn't have inconsolata.sty which is
    # needed for R 3.2.4 (later Rs have switched to zi4
    # instead), I've switched to miktex instead.
    _use_w32tex=no
    if [[ "${_use_w32tex}" == "yes" ]]; then
      mkdir w32tex || true
        pushd w32tex
        curl -SLO http://ctan.ijs.si/mirror/w32tex/current/texinst2016.zip
        unzip -o texinst2016.zip
        mkdir archives || true
          pushd archives
            for _file in latex mftools platex pdftex-w32 ptex-w32 web2c-lib web2c-w32 \
                         datetime2 dvipdfm-w32 dvipsk-w32 jtex-w32 ltxpkgs luatexja \
                         luatex-w32 makeindex-w32 manual newtxpx-boondoxfonts pgfcontrib \
                         t1fonts tex-gyre timesnew ttf2pk-w32 txpx-pazofonts vf-a2bk \
                         xetex-w32 xindy-w32 xypic; do
              curl -c ${_file}.tar.xz -SLO http://ctan.ijs.si/mirror/w32tex/current/${_file}.tar.xz
            done
          popd
        ./texinst2016.exe ${PWD}/archives
        ls -l ./texinst2016.exe
        mount
        PATH=${PWD}/bin:${PATH}
      popd
    else
      mkdir miktex || true
      pushd miktex
        curl -c ${DLCACHE}/miktex-portable-2.9.5857.exe -SLO http://mirrors.ctan.org/systems/win32/miktex/setup/miktex-portable-2.9.5857.exe
        echo "Extracting miktex-portable-2.9.5857.exe, this will take some time ..."
        7za x -y ${DLCACHE}/miktex-portable-2.9.5857.exe > /dev/null
        # We also need the url, incolsolata and mptopdf packages and
        # do not want a GUI to prompt us about installing these.
        sed -i 's|AutoInstall=2|AutoInstall=1|g' miktex/config/miktex.ini
        PATH=${PWD}/miktex/bin:${PATH}
      popd
    fi

    cd "${SRC_DIR}/src/gnuwin32"
    make distribution -j${CPU_COUNT} > make_distribution.log 2>&1
    cd installer
    make imagedir
    cp -rf R-3.2.4 "${PREFIX}"/R
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

    make -j${CPU_COUNT}
    make install
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
