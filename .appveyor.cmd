@echo off
call :%*
goto :eof

:perl_setup
if not exist "c:\tmp" mkdir c:\tmp
if not defined perl_type set perl_type=system
if "%perl_type%" == "cygwin" (
  start /wait c:\cygwin\setup-x86.exe -q -P perl -P make -P gcc -P gcc-g++ -P libcrypt-devel -P openssl-devel
  set "PATH=C:\cygwin\usr\local\bin;C:\cygwin\bin;%PATH%"
  set "PERL_MM_OPT=CCFLAGS='-fno-stack-protector -I.' CXXFLAGS='-fno-stack-protector -I.'"
  set "PERL_MB_OPT=--config ccflags='-fno-stack-protector -I.' --config cppflags='-fno-stack-protector -I.'"
) else if "%perl_type%" == "strawberry" (
  if not defined perl_version (
    cinst -y StrawberryPerl
  ) else (
    cinst -y StrawberryPerl --version %perl_version%
  )
  set "PATH=C:\Strawberry\perl\bin;C:\Strawberry\perl\site\bin;C:\Strawberry\c\bin;%PATH%"
) else if "%perl_type%" == "system" (
  mkdir c:\dmake
  cinst -y curl
  curl http://www.cpan.org/authors/id/S/SH/SHAY/dmake-4.12.2.2.zip -o c:\dmake\dmake.zip
  7z x c:\dmake\dmake.zip -oc:\ >NUL
  set "PATH=c:\dmake;C:\MinGW\bin;%PATH%"
) else (
  echo.Unknown perl type "%perl_type%"! 1>&2
  exit /b 1
)
for /f "usebackq delims=" %%d in (`perl -MConfig -e"print $Config{make}"`) do set make=%%d
set "perl=perl"
set "cpanm=call .appveyor.cmd cpanm"
set "cpan=%perl% -S cpan"
set "dzil=%perl% -S dzil"
set TAR_OPTIONS=--warning=no-unknown-keyword
set PERL_MM_USE_DEFAULT=1
set PERL_USE_UNSAFE_INC=1
set TZ=UTC
goto :eof

:cpanm
%perl% -S cpanm >NUL 2>&1
if ERRORLEVEL 1 (
  curl -V >NUL 2>&1
  if ERRORLEVEL 1 cinst -y curl
  curl -k -L https://cpanmin.us/ -o "%TEMP%\cpanm"
  %perl% "%TEMP%\cpanm" App::cpanminus
)
set "cpanm=%perl% -S cpanm"
%cpanm% %*
goto :eof

:eof
