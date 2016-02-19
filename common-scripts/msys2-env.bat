@echo off

REM TODO :: Move this to some README.md or some documentation place instead?
REM
REM To setup an MSYS2 environment for building Conda packages that can't be
REM built using MSVC, you should install the 64-bit MSYS2 installer or unpack
REM the portable tarball to C:\msys64
REM
REM Issue the following command to get the minimum set of necessary tools:
REM pacman -S msys2-devel mingw-w64-{i686,x86_64}-toolchain tar difftools patch make git dos2unix
REM
REM Issue this command to install tools I recommend to help out with things:
REM pacman -S pkgfile nano
REM
REM pkgfile: Use this to find out what package to install to get a file (full, exact
REM          filepaths, including extensions are required)
REM
REM nano: Side-step vi vs emacs and notepad vs notepad++ arguments.
REM
REM When it comes to using MSYS2 and pacman, I would caution against installing native
REM tools or libraries unless they are absolutely essential. This is because they will
REM get found by the build systems and will get pulled into Conda packages and this is
REM a recipe for disaster (or failure to find the DLLs on users' systems).

REM We can do better later.
if exist C:\msys64 (
  set MSYS2=C:\msys64
) else (
  set MSYS2=C:\msys32
)
if "%MSYS2%" == "" exit 1

REM The native tools always come before the msys2 tools.
set "PATH=%MSYS2%\mingw%ARCH%\bin;%MSYS2%\usr\bin;%PATH%"
set "MSYSTEM=MINGW%ARCH%"

FOR /F "delims=" %%i IN ('%MSYS2%\usr\bin\gcc.exe -dumpmachine') DO set "BUILDU=%%i"
FOR /F "delims=" %%i IN ('%MSYS2%\usr\bin\cygpath.exe -u %PREFIX%') DO set "PREFIXU=%%i"

if "%ARCH%" == "64" (
  set ARCHU=x86_64
) else (
  set ARCHU=i686
)

set "PKG_CONFIG_PATH=%PREFIXU%/lib/pkgconfig:%PREFIXU%/share/pkgconfig"
set "ACLOCAL_PATH=%PREFIXU%/share/aclocal:/usr/share/aclocal"
