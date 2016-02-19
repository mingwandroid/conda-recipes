set CMAKE_GENERATOR=NMake Makefiles JOM

mkdir build
cd build

REM Configure step
cmake -G "%CMAKE_GENERATOR%" ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -DCMAKE_INSTALL_PREFIX:PATH=%LIBRARY_PREFIX% ^
      %SRC_DIR%
if errorlevel 1 exit 1

REM Build step
cmake --build .
if errorlevel 1 exit 1

REM Install step
cmake --build . --target install
if errorlevel 1 exit 1

REM Some OSS libraries are happier if z.lib exists
REM even though it's not typical on Windows
copy %LIBRARY_LIB%\zlibstatic.lib %LIBRARY_LIB%\z.lib
