#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use lib '../blib/lib';
use Text::Template;

die "This is the test program for Text::Template version 1.11.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.11;


print "1..7\n";

$n=1;

$template = 'We will put value of $v (which is "good") here -> {$v}';

$v = 'oops (main)';
$Q::v = 'oops (Q)';

$vars = { 'v' => \'good' };

# (1) Build template from string
$template = new Text::Template ('type' => 'STRING', 'source' => $template);
print +($template ? '' : 'not '), "ok $n\n";
$n++;

# (2) Fill in template in anonymous package
$result2 = 'We will put value of $v (which is "good") here -> good';
$text = $template->fill_in(HASH => $vars);
print +($text eq $result2 ? '' : 'not '), "ok $n\n";
$n++;

# (3) Did we clobber the main variable?
print +($v eq 'oops (main)' ? '' : 'not '), "ok $n\n";
$n++;

# (4) Fill in same template again
$result4 = 'We will put value of $v (which is "good") here -> good';
$text = $template->fill_in(HASH => $vars);
print +($text eq $result4 ? '' : 'not '), "ok $n\n";
$n++;

# (5) Now with a package
$result5 = 'We will put value of $v (which is "good") here -> good';
$text = $template->fill_in(HASH => $vars, PACKAGE => 'Q');
print +($text eq $result5 ? '' : 'not '), "ok $n\n";
$n++;

# (6) We expect to have clobbered the Q variable.
print +($Q::v eq 'good' ? '' : 'not '), "ok $n\n";
$n++;

# (7) Now let's try it without a package
$result7 = 'We will put value of $v (which is "good") here -> good';
$text = $template->fill_in(HASH => $vars);
print +($text eq $result7 ? '' : 'not '), "ok $n\n";
$n++;

exit;

