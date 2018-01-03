#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use strict;
use warnings;
use Test::More tests => 3;

use_ok 'Text::Template' or exit 1;

my $template = new Text::Template TYPE => 'STRING', SOURCE => q{My process ID is {$$}};

my $of = "t$$";
END { unlink $of }
open my $ofh, '>', $of or die "open($of): $!";

my $text = $template->fill_in(OUTPUT => $ofh);

# (1) No $text should have been constructed.  Return value should be true.
is $text, '1';

close $ofh or die "close(): $!";

open my $ifh, '<', $of or die "open($of): $!";

my $t;
{ local $/; $t = <$ifh> }
close $ifh;

# (2) The text should have been printed to the file
is $t, "My process ID is $$";
