#!perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Text::Template;

my $template = <<'EOT';
{{
if ($good =~ /good/) {
    'This template should not produce warnings.'.$bad;
}
}}
EOT

$template = Text::Template->new(type => 'STRING', source => $template);
isa_ok $template, 'Text::Template';

my $result = $template->fill_in(HASH => { good => 'good' });

$result =~ s/(?:^\s+)|(?:\s+$)//gs;
is $result, 'This template should not produce warnings.';

# see https://github.com/mschout/perl-text-template/issues/10
$template = Text::Template->new(type => 'STRING', package => 'MY', source => '');
$template->fill_in(package => 'MY', hash => { include => sub { 'XX' } });

$template = Text::Template->new(type => 'STRING', package => 'MY', source => '');
$template->fill_in(package => 'MY', hash => { include => sub { 'XX' } });

done_testing;
