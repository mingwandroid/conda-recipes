copy %RECIPE_DIR%\..\common-scripts\msys2-env.bat .
call msys2-env.bat

REM Disable the tools as they require gettext (and iconv)
REM Disable threads as that pulls in winpthreads.
bash configure --prefix=%PREFIXU% ^
               --build=%BUILDU% ^
               --host=%ARCHU%-w64-mingw32 ^
               --disable-xz ^
               --disable-xzdec ^
               --disable-lzmadec ^
               --disable-lzmainfo ^
               --disable-lzma-links ^
               --disable-scripts ^
               --disable-doc ^
               --disable-threads
if errorlevel 1 exit 1

make
if errorlevel 1 exit 1

make install
if errorlevel 1 exit 1
