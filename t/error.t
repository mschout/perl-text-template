#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use strict;
use warnings;
use Test::More tests => 6;

use_ok 'Text::Template' or exit 1;

# (1-2) Missing source
eval {
    Text::Template->new();
    pass;
};
unless ($@ =~ /^\QUsage: Text::Template::new(TYPE => ..., SOURCE => ...)/) {
    diag $@;
    fail;
}
else {
    pass;
}

eval { Text::Template->new(TYPE => 'FILE'); };
if ($@ =~ /^\QUsage: Text::Template::new(TYPE => ..., SOURCE => ...)/) {
    pass;
}
else {
    diag $@;
    fail;
}

# (3) Invalid type
eval { Text::Template->new(TYPE => 'wlunch', SOURCE => 'fish food'); };
if ($@ =~ /^\QIllegal value `WLUNCH' for TYPE parameter/) {
    pass;
}
else {
    diag $@;
    fail;
}

# (4-5) File does not exist
my $o = Text::Template->new(
    TYPE   => 'file',
    SOURCE => 'this file does not exist');
ok !defined $o;

ok defined($Text::Template::ERROR)
    && $Text::Template::ERROR =~ /^Couldn't open file/;
