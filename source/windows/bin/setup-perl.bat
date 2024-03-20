@echo off

setlocal EnableDelayedExpansion

call "%~dp0env.bat"

set _cd=%CD%

:: Install dependencies but skip tests
call cpanm --notest YAML Test::Output CPAN::DistnameInfo

:: Perl development dependencies
call cpanm --notest Perl::Critic

call cpanm --notest ExtUtils::MakeMaker common::sense

git clone -b main https://github.com/joelvaneenwyk/IO-AIO.git "%USERPROFILE%\.tmp\IO-AIO"
cd /d "%USERPROFILE%\.tmp\IO-AIO"
perl Makefile.PL
gmake
gmake install
gmake test

call cpanm --notest Moose AnyEvent AnyEvent::AIO Coro JSON Data::Dump PadWalker Scalar::Util Class::Refresh Compiler::Lexer
git clone -b master https://github.com/richterger/Perl-LanguageServer.git "%USERPROFILE%\.tmp\Perl-LanguageServer"
cd /d "%USERPROFILE%\.tmp\Perl-LanguageServer"
perl Makefile.PL
gmake
gmake install
gmake test

cd /d "%_cd%"
endlocal & exit /b
