#!perl -T
# Tests for taint-mode features

use Text::Template;

die "This is the test program for Text::Template version 1.41.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.41;

my $file = "tt$$";

sub taint {
  for (@_) {
    $_ .= substr($0,0,0);       # LOD
  }
}

print "1..15\n";

my $n =1;
print "ok ", $n++, "\n";

my $template = 'The value of $n is {$n}.';

open T, "> $file" or die "Couldn't write temporary file $file: $!";
print T $template, "\n";
close T or die "Couldn't finish temporary file $file: $!";

sub should_fail {
  my $obj = Text::Template->new(@_);
  eval {$obj->fill_in()};
  if ($@) {
    print "ok $n # $@\n";
  } else {
    print "not ok $n # (didn't fail)\n";
  }
  $n++;
}

sub should_work {
  my $obj = Text::Template->new(@_);
  eval {$obj->fill_in()};
  if ($@) {
    print "not ok $n # $@\n";
  } else {
    print "ok $n\n";
  }
  $n++;
}

# Tainted filename should die with and without UNTAINT option
# untainted filename should die without UNTAINT option
# filehandle should die without UNTAINT option
# string and array with tainted data should die either way

# 2-5
taint(my $tfile = $file);
should_fail TYPE => 'file', SOURCE => $tfile;
should_fail TYPE => 'file', SOURCE => $tfile, UNTAINT => 1;
should_fail TYPE => 'file', SOURCE => $file;
should_work TYPE => 'file', SOURCE => $file, UNTAINT => 1;

# 6-7
open H, "< $file" or die "Couldn't open $file for reading: $!; aborting";
should_fail TYPE => 'filehandle', SOURCE => \*H;
close H;
open H, "< $file" or die "Couldn't open $file for reading: $!; aborting";
should_work TYPE => 'filehandle', SOURCE => \*H, UNTAINT => 1;
close H;

# 8-11
taint(my $ttemplate = $template);
should_fail TYPE => 'string', SOURCE => $ttemplate;
should_fail TYPE => 'string', SOURCE => $ttemplate, UNTAINT => 1;
should_work TYPE => 'string', SOURCE => $template;
should_work TYPE => 'string', SOURCE => $template, UNTAINT => 1;

# 12-15
my $array = [ $template ];
my $tarray = [ $ttemplate ];
should_fail TYPE => 'array', SOURCE => $tarray;
should_fail TYPE => 'array', SOURCE => $tarray, UNTAINT => 1;
should_work TYPE => 'array', SOURCE => $array;
should_work TYPE => 'array', SOURCE => $array, UNTAINT => 1;

END { unlink $file }

