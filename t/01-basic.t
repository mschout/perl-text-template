#!perl
#
# test apparatus for Text::Template module
# still incomplete.

use lib '../blib/lib', './blib/lib';
use Text::Template;
$X::v = $Y::v = 0;		# Suppress `var used only once'

print "1..29\n";

$n=1;

die "This is the test program for Text::Template version 1.20.
You are using version $Text::Template::VERSION instead.
That does not make sense.\n
Aborting"
  unless $Text::Template::VERSION == 1.20;

$template_1 = <<EOM;
We will put value of \$v (which is "abc") here -> {\$v}
We will evaluate 1+1 here -> {1 + 1}
EOM

# (1) Construct temporary template file for testing
# file operations
$TEMPFILE = "/tmp/template$$";
open(TMP, "> $TEMPFILE") or print "not ok $n\n" && &abort("Couldn\'t write tempfile $TEMPFILE: $!");
print TMP $template_1;
close TMP;
print "ok $n\n"; $n++;

# (2) Build template from file
$template = new Text::Template ('type' => 'FILE', 'source' => $TEMPFILE);
if (defined($template)) {
  print "ok $n\n";
} else {
  print "not ok $n $Text::Template::ERROR\n";
}
$n++;

# (3) Fill in template from file
$X::v = "abc";	
$resultX = <<EOM;
We will put value of \$v (which is "abc") here -> abc
We will evaluate 1+1 here -> 2
EOM
$Y::v = "ABC";	
$resultY = <<EOM;
We will put value of \$v (which is "abc") here -> ABC
We will evaluate 1+1 here -> 2
EOM

$text = $template->fill_in('package' => X);
if ($text eq $resultX) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
}
$n++;

# (4) Fill in same template again
$text = $template->fill_in('package' => Y);
if ($text eq $resultY) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
}
$n++;



# (5) Simple test of `fill_this_in'
$text = Text::Template->fill_this_in( $template_1, 'package' => X);
if ($text eq $resultX) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
}
$n++;

# (6) test creation of template from filehandle
if (open (TMPL, "< $TEMPFILE")) {
  $template = new Text::Template ('type' => 'FILEHANDLE', 
				  'source' => *TMPL);
  if (defined($template)) {
    print "ok $n\n";
  } else {
    print "not ok $n $Text::Template::ERROR\n";
  }
  $n++;

# (7) test filling in of template from filehandle
  $text = $template->fill_in('package' => X);
  if ($text eq $resultX) {
    print "ok $n\n";
  } else {
    print "not ok $n\n";
  }
  $n++;

# (8) test second fill_in on same template object
  $text = $template->fill_in('package' => Y);
  if ($text eq $resultY) {
    print "ok $n\n";
  } else {
    print "not ok $n\n";
  }
  $n++;
  close TMPL;
} else {
  print "not ok $n\n";  $n++;
  print "not ok $n\n";  $n++;
  print "not ok $n\n";  $n++;
}


# (9) test creation of template from array
$template = new Text::Template 
    ('type' => 'ARRAY', 
     'source' => [ 
		  'We will put value of $v (which is "abc") here -> {$v}',
		  "\n",
		  'We will evaluate 1+1 here -> {1+1}',
		  "\n",
		  ]);
if (defined($template)) {
  print "ok $n\n";
} else {
  print "not ok $n $Text::Template::ERROR\n";
}
$n++;

# (10) test filling in of template from array
$text = $template->fill_in('package' => X);
if ($text eq $resultX) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
}
$n++;

# (11) test second fill_in on same array template object
$text = $template->fill_in('package' => Y);
if ($text eq $resultY) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
  print STDERR "$resultX\n---\n$text";
  unless (!defined($text)) { print STDERR "ERROR: $Text::Template::ERROR\n"};
}
$n++;

# (12) test default error handler
$template_2 = <<EOM;
This line will generate an error:
{1/0}
EOM

$result = <<'EOM';
This line will generate an error:
Program fragment at line 2 delivered error ``Illegal division by zero''
EOM


$text = Text::Template->fill_this_in($template_2);
if ($text =~ /$result/s) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
  print STDERR "---\n$text\n---\n";
}
$n++;

# (13) test user-defined error handler
$result = <<'EOM';
This line will generate an error:
1/0---Illegal division by zero.
EOM

sub template_error {
  my (%args) = @_;
  my($progtext, $errmsg) = @args{'text', 'error'};
  $errmsg =~ s/.at.*/\./;
  return "$progtext---$errmsg\n";
}

$text = Text::Template->fill_this_in($template_2, 
				     'broken' => \&template_error);
if ($text =~ /$result/s) {
  print "ok $n\n";
} else {
  print "not ok $n\n";
  print STDERR "---\n$text\n---\n";
}
$n++;


# (14) Make sure \ is working properly
# Test added for version 1.11
my $tmpl = Text::Template->new(TYPE => 'STRING',
			       SOURCE => 'B{"\\}"}C{"\\{"}D',
			       );
# This should fail if the \ are not interpreted properly.
my $text = $tmpl->fill_in();
print +($text eq "B}C{D" ? '' : 'not '), "ok $n\n";
$n++;

# (15) Make sure \ is working properly
# Test added for version 1.11
$tmpl = Text::Template->new(TYPE => 'STRING',
			    SOURCE => qq{A{"\t"}B},
			   );
# Symptom of old problem:  ALL \ were special in templates, so
# The lexer would return (A, PROGTEXT("t"), B), and the
# result text would be AtB instead of A(tab)B.
$text = $tmpl->fill_in();

print +($text eq "A\tB" ? '' : 'not '), "ok $n\n";
$n++;

# (16-29) Make sure \ is working properly
# Test added for version 1.11
# This is a sort of general test.
my @tests = ('{""}' => '',	# (16)
	     '{"}"}' => undef,
	     '{"\\}"}' => '}',	# One backslash
	     '{"\\\\}"}' => undef, # Two backslashes
	     '{"\\\\\\}"}' => '}', # Three backslashes (20)
	     '{"\\\\\\\\}"}' => undef, # Four backslashes
	     '{"\\\\\\\\\\}"}' => '\}', # Five backslashes
	     '{"x20"}' => 'x20',
	     '{"\\x20"}' => ' ',	# One backslash
	     '{"\\\\x20"}' => '\\x20', # Two backslashes (25)
	     '{"\\\\\\x20"}' => '\\ ', # Three backslashes
	     '{"\\\\\\\\x20"}' => '\\\\x20', # Four backslashes
	     '{"\\\\\\\\\\x20"}' => '\\\\ ', # Five backslashes
	     '{"\\x20\\}"}' => ' }', # (29)
	    );

my $i;
for ($i=0; $i<@tests; $i+=2) {
  my $tmpl = Text::Template->new(TYPE => 'STRING',
				 SOURCE => $tests[$i],
				);
  my $text = $tmpl->fill_in;
  my $result = $tests[$i+1];
  my $ok = (! defined $text && ! defined $result
	    || $text eq $result);
  unless ($ok) {
    print STDERR "($n) expected .$result., got .$text.\n";
  }
  print +($ok ? '' : 'not '), "ok $n\n";
  $n++;
}



unlink $TEMPFILE;

exit;




sub abort {
  unlink $TEMPFILE;
  die $_[0];
}
