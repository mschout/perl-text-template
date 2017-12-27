#!perl
#
# Test for RT Bug 29928 fix
# https://rt.cpan.org/Public/Bug/Display.html?id=29928

use Text::Template::Preprocess;

print "1..1\n";
my $n = 1;

my $tin = q{The value of $foo is: {$foo}.};

sub tester {
  1; #dummy preprocessor to cause the bug described.
}

$tmpl1 = Text::Template::Preprocess->new(TYPE => 'STRING',
  SOURCE => $tin,
);
$tmpl1->compile;
$t1 = $tmpl1->fill_in(
  HASH => {foo => 'things'},
  PREPROCESSOR => \&tester,
);

($t1 eq 'The value of $foo is: things.') or print "not ";
print "ok $n\n"; $n++;

