#!perl
#
# Test for breakage of Dist::Milla in v1.46
#

use strict;
use warnings;
use Text::Template;

# Minimum Test::More version; 0.94+ is required for `done_testing`
BEGIN { if (! eval { require Test::More; "$Test::More::VERSION" >= 0.94; } ) { use Test::More; plan skip_all => '[ Test::More v0.94+ ] is required for testing' } };

my $tmpl = Text::Template->new(
    TYPE       => 'STRING',
    SOURCE     => q| {{ '{{$NEXT}}' }} |,
    DELIMITERS => [ '{{', '}}' ]);

is $tmpl->fill_in, ' {{$NEXT}} ';

done_testing;
