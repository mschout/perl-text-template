#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use lib '../blib/lib';
use Text::Template;

die "This is the test program for Text::Template version 1.20.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.20;

print "1..3\n";
$n = 1;

# (1-2) Missing source
eval {
  Text::Template->new();
};
unless ($@ =~ /^\QUsage: Text::Template::new(TYPE => ..., SOURCE => ...)/) {
  print STDERR $@;
  print "not ";
}
print "ok $n\n";
$n++;

eval {
  Text::Template->new(TYPE => 'FILE');
};
unless ($@ =~ /^\QUsage: Text::Template::new(TYPE => ..., SOURCE => ...)/) {
  print STDERR $@;
  print "not ";
}
print "ok $n\n";
$n++;

# (3) Invalid type
eval {
  Text::Template->new(TYPE => 'wlunch', SOURCE => 'fish food');
};
unless ($@ =~ /^\QIllegal value \`WLUNCH\' for TYPE parameter/) {
  print STDERR $@;
  print "not ";
}
print "ok $n\n";
$n++;

exit;

