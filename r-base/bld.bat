set "PATH=%LIBRARY_PREFIX%\mingw-w64\bin;%LIBRARY_PREFIX%\usr\bin;%PATH%"
echo PATH is %PATH%

@rem See notes.md for more information about all of this.

@rem Compile the launcher

@rem XXX: Should we build Rgui with -DGUI=1 -mwindows?  The only difference is
@rem that that it doesn't block the terminal, but we also can't get the return
@rem value for the conda build tests.

gcc -DGUI=0 -O -s -m"%ARCH%" -o launcher.exe "%RECIPE_DIR%\launcher.c"
if errorlevel 1 exit 1

@rem Install the launcher

if not exist "%PREFIX%\Scripts" mkdir "%PREFIX%\Scripts"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\R.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\Rcmd.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\RSetReg.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\Rfe.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\Rgui.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\Rscript.exe"
if errorlevel 1 exit 1

copy launcher.exe "%PREFIX%\Scripts\Rterm.exe"
if errorlevel 1 exit 1

@rem XXX: Should we skip this one?
copy launcher.exe "%PREFIX%\Scripts\open.exe"
if errorlevel 1 exit 1

copy "%RECIPE_DIR%\build.sh" .
set PREFIX=%PREFIX:\=/%
set SRC_DIR=%SRC_DIR:\=/%
set "MSYSTEM=MINGW%ARCH%"
set "CHERE_INVOKING=1"
bash -lc "./build.sh"
exit 1

cd "%SRC_DIR%\src\gnuwin32"
make distribution
if errorlevel 1 exit 1

@rem And finally collect everything together.
cd installer
make imagedir
if errorlevel 1 exit 1

@rem And install it
xcopy /S /E R-3.2.2 "%PREFIX%\R\"
if errorlevel 1 exit 1
