#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use lib '../blib/lib';
use Text::Template;

BEGIN {
  eval "use Safe";
  if ($@) {
    print "1..0\n";
    exit 0;
  }
}

die "This is the test program for Text::Template version 1.20.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.20;

print "1..1\n";

$n=1;

# Test the OUT feature with safe compartments

$template = q{
This line should have a 3: {1+2}

This line should have several numbers:
{ $t = ''; foreach $n (1 .. 20) { $t .= $n . ' ' } $t }
};

$templateOUT = q{
This line should have a 3: { $OUT = 1+2 }

This line should have several numbers:
{ foreach $n (1 .. 20) { $OUT .= $n . ' ' } }
};

$c = new Safe;

# Build templates from string
$template = new Text::Template ('type' => 'STRING', 'source' => $template,
			       SAFE => $c)
  or die;
$templateOUT = new Text::Template ('type' => 'STRING', 'source' => $templateOUT,
				  SAFE => $c)
  or die;

# Fill in templates
$text = $template->fill_in()
  or die;
$textOUT = $templateOUT->fill_in()
  or die;

# (1) They should be the same
print +($text eq $textOUT ? '' : 'not '), "ok $n\n";
$n++;


exit;

