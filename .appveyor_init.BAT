:: configuration
@prompt $g$s &:: minimize output "noise"
@echo ON

:: add extra testing dependencies
:: * Test::More v0.94+ needed for `done_testing` + extra non-CORE modules
set "DIST_EXTRA_DEPS=Test::More~0.94 Test::More::UTF8 Test::Warnings"

@echo OFF
@echo.
