#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use lib '../blib/lib';
use Text::Template 'fill_in_file', 'fill_in_string';

die "This is the test program for Text::Template version 1.20.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.20;

print "1..2\n";

$n=1;
$Q::n = $Q::n = 119; 

# (1) Test fill_in_string
$out = fill_in_string('The value of $n is {$n}.', PACKAGE => 'Q' );
print +($out eq 'The value of $n is 119.' ? '' : 'not '), "ok $n\n";
$n++;

# (2) Test fill_in_file
$TEMPFILE = "/tmp/text-template-test.$$";
open F, "> $TEMPFILE" or die "Couldn't open test file: $!; aborting";
print F 'The value of $n is {$n}.', "\n";
close F or die "Couldn't write test file: $!; aborting";
$R::n = $R::n = 8128; 

$out = fill_in_file($TEMPFILE, PACKAGE => 'R');
print +($out eq "The value of \$n is 8128.\n" ? '' : 'not '), "ok $n\n";
$n++;

END { $TEMPFILE && unlink $TEMPFILE }

exit;

