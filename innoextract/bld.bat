set CMAKE_GENERATOR=NMake Makefiles JOM

mkdir build
cd build

cmake -G "%CMAKE_GENERATOR%" ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      -DBoost_USE_STATIC_LIBS=No ^
      %SRC_DIR%
if errorlevel 1 exit 1

cmake --build .
if errorlevel 1 exit 1

cmake --build . install
if errorlevel 1 exit 1
