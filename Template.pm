# -*- perl -*-
# Text::Template.pm
#
# Fill in `templates'
#
# Copyright 1996, 1997, 1999 M-J. Dominus.
# You may copy and distribute this program under the
# same terms as Perl iteself.  
# If in doubt, write to mjd-perl-template@pobox.com for a license.
#
# Version 1.03

package Text::Template;
use Exporter;
@EXPORT_OK = qw(fill_in_file fill_in_string TTerror);
use vars '$ERROR';
use strict;

$Text::Template::VERSION = '1.03';

sub Version {
  $Text::Template::VERSION;
}

sub _param {
  my $kk;
  my ($k, %h) = @_;
  for $kk ($k, "\u$k", "\U$k", "-$k", "-\u$k", "-\U$k") {
    return $h{$kk} if exists $h{$kk};
  }
  return undef;
}

sub new {
  my $pack = shift;
  my %a = @_;
  my $stype = _param('type', %a) || 'FILE';
  my $source = _param('source', %a);
  unless (defined $source) {
    require Carp;
    Carp::croak("Usage: $ {pack}::new(TYPE => ..., SOURCE => ...)");
  }
  my $self = {TYPE => $stype,
	      SOURCE => $source,
	     };

  bless $self => $pack;
#  $self->compile;

  $self;
}

sub compile {
  my $self = shift;

  return 1 if $self->{TYPE} eq 'PREPARSED';

  if ($self->{TYPE} eq 'FILE') {
    my $text = _load_text($self->{SOURCE});
    unless (defined $text) {
      # _load_text already set $ERROR
      return undef;
    }
    $self->{TYPE} = 'STRING';
    $self->{SOURCE} = $text;
  } elsif ($self->{TYPE} eq 'ARRAY') {
    $self->{TYPE} = 'STRING';
    $self->{SOURCE} = join '', @{$self->{SOURCE}};
  } elsif ($self->{TYPE} eq 'FILEHANDLE') {
    $self->{TYPE} = 'STRING';
    local $/;
    local *FH = $self->{SOURCE};
    $self->{SOURCE} = <FH>;
  }

  unless ($self->{TYPE} eq 'STRING') {
    my $pack = ref $self;
    die "Can only compile $pack objects of subtype STRING, but this is $self->{TYPE}; aborting";
  }

  my @tokens = split /([{}\n]|\\.)/, $self->{SOURCE};
  my $state = 'TEXT';
  my $depth = 0;
  my $lineno = 1;
  my @content;
  my $cur_item = '';
  my $prog_start;
  while (@tokens) {
    my $t = shift @tokens;
    next if $t eq '';
    if ($t eq '{') {
      if ($depth == 0) {
	push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
	$cur_item = '';
	$state = 'PROG';
	$prog_start = $lineno;
      } else {
	$cur_item .= $t;
      }
      $depth++;
    } elsif ($t eq '}') {
      $depth--;
      if ($depth < 0) {
	$ERROR = "Unmatched close brace at line $lineno";
	return undef;
      } elsif ($depth == 0) {
	push @content, [$state, $cur_item, $prog_start] if $cur_item ne '';
	$state = 'TEXT';
	$cur_item = '';
      } else {
	$cur_item .= $t;
      }
    } elsif ($t =~ /^\\(.)/) {
      $cur_item .= $1;
    } elsif ($t eq "\n") {
      $lineno++;
      $cur_item .= $t;
    } else {
      $cur_item .= $t;
    }
  }

  if ($state eq 'PROG') {
    $ERROR = "End of data inside program text that began at line $prog_start";
    return undef;
  } elsif ($state eq 'TEXT') {
    push @content, [$state, $cur_item, $lineno] if $cur_item ne '';
  } else {
    die "Can't happen error #1";
  }
  
  $self->{TYPE} = 'PREPARSED';
  $self->{SOURCE} = \@content;
  1;
}

sub fill_in {
  my $fi_self = shift;

  unless ($fi_self->{TYPE} eq 'PREPARSED') {
    $fi_self->compile 
      or return undef;
  }

  my %fi_a = @_;
  my $fi_varhash = _param('hash', %fi_a);
  my $fi_package = _param('package', %fi_a) ;
  my $fi_broken  = _param('broken', %fi_a)  || \&_default_broken;
  my $fi_broken_arg = _param('broken_arg', %fi_a) || [];
  my $fi_safe = _param('safe', %fi_a);

  if ($fi_varhash) {
    unless (defined $fi_package) {
      $fi_package = _gensym();
    }
    if (ref $fi_varhash eq 'HASH') {
      $fi_varhash = [$fi_varhash];
    }
    my $varhash;
    foreach $varhash (@$fi_varhash) {
      my $name;
      foreach $name (keys %$varhash) {
	my $val = $varhash->{$name};
	no strict 'refs';
	local *SYM = *{"$ {fi_package}::$name"};
	if (! defined $val) {
	  *SYM = undef;
	} elsif (ref $val) {
	  *SYM = $val;
	} else {
	  *SYM = \$val;
	}
      }
    }
  } else {
    $fi_package = caller unless defined $fi_package;
  }

  my $fi_r = '';
  my $fi_item;
  foreach $fi_item (@{$fi_self->{SOURCE}}) {
    my ($fi_type, $fi_text, $fi_lineno) = @$fi_item;
    if ($fi_type eq 'TEXT') {
      $fi_r .= $fi_text;
    } elsif ($fi_type eq 'PROG') {
      no strict;
      my $fi_progtext = "package $fi_package; $fi_text";
      my $fi_res;
      if ($fi_safe) {
	$fi_res = $fi_safe->reval($fi_progtext);
      } else {
	$fi_res = eval $fi_progtext;
      }
      if ($@) {
	$fi_res = $fi_broken->(text => $fi_text,
			       error => $@,
			       lineno => $fi_lineno,
			       arg => $fi_broken_arg,
			       );
	if (defined $fi_res) {
	  $fi_r .= $fi_res;
	} else {
	  return $fi_res;		# Undefined means abort processing
	}
      } else {
	$fi_r .= $fi_res;
      }
    } else {
      die "Can't happen error #2";
    }
  }
  $fi_r;
}

sub fill_this_in {
  my $pack = shift;
  my $text = shift;
  my $templ = $pack->new(TYPE => 'STRING', SOURCE => $text)
    or return undef;
  $templ->compile or return undef;
  my $result = $templ->fill_in(@_);
  $result;
}

sub fill_in_string {
  Text::Template->fill_this_in(@_);
}

sub fill_in_file {
  my $fn = shift;
  my $templ = Text::Template->new(TYPE => 'FILE', SOURCE => $fn)
    or return undef;
  $templ->compile or return undef;
  my $text = $templ->fill_in(@_);
  $text;
}

sub _default_broken {
  my %a = @_;
  my $prog_text = $a{text};
  my $err = $a{error};
  my $lineno = $a{lineno};
  $err =~ s/\s+at .*//s;
  "Program fragment at line $lineno delivered error ``$err''";
}

sub _load_text {
  my $fn = shift;
  local *F;
  unless (open F, $fn) {
    $ERROR = "Couldn't open file $fn: $!";
    return undef;
  }
  local $/;
  <F>;
}

{
  my $seqno = 0;
  sub _gensym {
    __PACKAGE__ . '::GEN' . $seqno++;
  }
}
  
sub TTerror { $ERROR }

1;


=head1 NAME 

Text::Template - Expand template text with embedded Perl

=head1 SYNOPSIS

 use Text::Template;

 $template = new Text::Template (TYPE => FILE,  SOURCE => 'filename.tmpl');
 $template = new Text::Template (TYPE => ARRAY, SOURCE => [ ... ] );
 $template = new Text::Template (TYPE => FILEHANDLE, SOURCE => $fh );
 $template = new Text::Template (TYPE => STRING, SOURCE => '...' );

 $recipient = 'King';
 $text = $template->fill_in();  # Replaces `{$recipient}' with `King'
 print $text;

 $T::recipient = 'Josh';
 $text = $template->fill_in(PACKAGE => T);
 print $text;

 $text = $template->fill_in(BROKEN => \&callback, BROKEN_ARG => [...]);
 $text = $template->fill_in(SAFE => $compartment, ...);

 use Text::Template 'fill_in_string';
 $text = fill_in_string( <<EOM, 'package' => T);
 Dear {$recipient},
 Pay me at once.
        Love, 
         G.V.
 EOM

 use Text::Template ''fill_in_file';
 $text = fill_in_file($filename, ...);

=head1 DESCRIPTION

This is a library for generating form letters, building HTML pages, or
filling in templates generally.  A `template' is a piece of text that
has little Perl programs embedded in it here and there.  When you
`fill in' a template, you evaluate the little programs and replace
them with their values.  

Here's an example of a template:

	Dear {$title} {$lastname},

	It has come to our attention that you are delinquent in your
	{$monthname[$last_paid_month]} payment.  Please remit
	${sprintf("%.2f", $amount)} immediately, or your patellae may
	be needlessly endangered.

			Love,

			Mark "Vizopteryx" Dominus


The result of filling in this template is a string, which might look
something like this:

	Dear Mr. Gates,

	It has come to our attention that you are delinquent in your
	February payment.  Please remit
	$392.12 immediately, or your patellae may
	be needlessly endangered.


			Love,

			Mark "Vizopteryx" Dominus

You can store a template in a file outside your program.  People can
modify the template without modifying the program.  You can separate
the formatting details from the main code, and put the formatting
parts of the program into the template.  That prevents code bloat and
encourages functional separation.

=head1 Template Syntax

When people make a template module like this one, they almost always
start by inventing a special syntax for substitutions.  For example,
they build it so that a string like C<%%VAR%%> is replaced with the
value of C<$VAR>.  Then they realize the need extra formatting, so
they put in some special syntax for formatting.  Then they need a
loop, so they invent a loop syntax.  Pretty soon they have a new
little template language.

This approach has two problems: First, their little language is
crippled. If you need to do something the author hasn't thought of,
you lose.  Second: Who wants to learn another language?  You already
know Perl, so why not use it?

C<Text::Template> templates are programmed in I<Perl>.  You embed Perl
code in your template, with C<{> at the beginning and C<}> at the end.
If you want a variable interpolated, you write it the way you would in
Perl.  If you need to make a loop, you can use any of the Perl loop
constructions.  All the Perl built-in functions are available.

=head1 Details

=head2 Template Parsing

The C<Text::Template> module scans the template source.  An open brace
C<{> begins a program fragment, which continues until the matching
close brace C<}>.  When the template is filled in, the program
fragments are evaluated, and each one is replaced with the resulting
value to yield the text that is returned.

A backslash C<\> in front of a brace (or another backslash) escapes
its special meaning.    The result of filling out this template:

	\{ The sum of 1 and 2 is {1+2}  \}

is

	{ The sum of 1 and 2 is 3  }

If you have an unmatched brace, C<Text::Template> will return a
failure code and a warning about where the problem is.

Each program fragment should be a sequence of Perl statements, which
are evaluated the usual way.  The result of the last statement
executed will be evaluted in scalar context; the result of this
statement is a string, which is interpolated into the template in
place of the program fragment itself.

The fragments are evaluated in order, and side effects from earlier
fragments will persist into later fragments:

	{$x = @things; ''} The Lord High Chamberlain has gotten {$x}
	things for me this year.  
	{ $diff = $x - 17; 
	  $more = 'more'
	  if ($diff == 0) {
	    $diff = 'no';
	  } elsif ($diff < 0) {
	    $more = 'fewer';
	  } 
	} 
	That is {$diff} {$more} than he gave me last year.

The value of C<$x> set in the first line will persist into the next
fragment that begins on the third line, and the values of C<$diff> and
C<$more> set in the second fragment will persist and be interpolated
into the last line.  The output will look something like this:

	 The Lord High Chamberlain has gotten 42
	things for me this year.  

	That is 35 more than he gave me last year.

That is all the syntax there is.  

=head2 General Remarks

All C<Text::Template> functions return C<undef> on failure, and set the
variable C<$Text::Template::ERROR> to contain an explanation of what
went wrong.  For example, if you try to create a template from a file
that does not exist, C<$Text::Template::ERROR> will contain something like:

	Couldn't open file xyz.tmpl: No such file or directory

=head2 C<new>

	$template = new Text::Template ( attribute => value, ... );

This creates and returns a new template object.  You specify the
source of the template with a set of attribute-value pairs in the
arguments.  It returns C<undef> and sets C<$Text::Template::ERROR> if
it can't create the template object.

The C<TYPE> attribute says what kind of thing the source is.  Most common is 
a filename:

	new Text::Template ( TYPE => 'FILE', SOURCE => $filename );

This reads the template from the specified file.  The filename is
opened with the Perl C<open> command, so it can be a pipe or anything
else that makes sense with C<open>.

The C<TYPE> can also be C<STRING>, in which case the C<SOURCE> should
be a string:

	new Text::Template ( TYPE => 'STRING', 
                             SOURCE => "This is the actual template!" );

The C<TYPE> can be C<ARRAY>, in which case the source should be a
reference to an array of strings.  The concatenation of these strings
is the template:

	new Text::Template ( TYPE => 'ARRAY', 
                             SOURCE => [ "This is ", "the actual", 
                                         " template!",
                                       ]
                           );

The C<TYPE> can be FILEHANDLE, in which case the source should be an
open filehandle (such as you got from the C<FileHandle> or C<IO::*>
packages, or a glob, or a reference to a glob).  In this case
C<Text::Template> will read the text from the filehandle up to
end-of-file, and that text is the template.

If you omit the C<TYPE> attribute, it's taken to be C<FILE>.
C<SOURCE> is required.  If you omit it, the program will abort.

The words C<TYPE> and C<SOURCE> can be spelled any of the following ways:

	TYPE	SOURCE
	Type	Source
	type	source
	-TYPE	-SOURCE
	-Type	-Source
	-type	-source

Pick a style you like and stick with it.

=head2 C<compile>

	$template->compile()

Loads all the template text from the template's source, parses and
compiles it.  If successful, returns true; otherwise returns false and
sets C<$Text::Template::ERROR>.  If the template is already compiled,
it returns true and does nothing.

You don't usually need to invoke this function, because C<fill_in>
(see below) compiles the template if it isn't compiled already.

=head2 C<fill_in>

	$template->fill_in(OPTIONS);

Fills in a template.  Returns the resulting text if successful.
Otherwise, returns C<undef>  and sets C<$Text::Template::ERROR>.

The I<OPTIONS> are a hash, or a list of key-value pairs.  You can
write the key names in any of the six usual styles as above; this
means that where this manual says C<PACKAGE> you can actually use any
of 

	PACKAGE Package package -PACKAGE -Package -package

Pick a style you like and stick with it.  The all-lowercase versions
may yield spurious warnings about

	Ambiguous use of package => resolved to "package"

so you might like to avoid them and use the capitalized versions.

At present, there are four legal options:  C<PACKAGE>, C<BROKEN>,
C<BROKEN_ARG>, and C<SAFE>.

=over 4

=item C<PACKAGE>

C<PACKAGE> specifies the name of a package in which the program
fragments should be evaluated.  The default is to use the package from
which C<fill_in> was called.  For example, consider this template:

	The value of the variable x is {$x}.

If you use C<$template-E<gt>fill_in(PACKAGE =E<gt> 'R')> , then the C<$x> in
the template is actually replaced with the value of C<$R::x>.  If you
omit the C<PACKAGE> option, C<$x> will be replaced with the value of
the C<$x> variable in the package that actually called C<fill_in>.

You should almost always use C<PACKAGE>.  If you don't, and your
template makes changes to variables, those changes will be propagated
back into the main program.  Evaluating the template in a private
package helps prevent this.  The template can still modify variables
in your program if it wants to, but it will have to do so explicitly.
See the section at the end on `Security'.

Here's an example of using C<PACKAGE>:

	Your Royal Highness,

	Enclosed please find a list of things I have gotten
	for you since 1907:

	{ $list = '';
	  foreach $item (@items) {
	    $list .= " o \u$item\n";
	  }
	  $list;
	}

	Signed,
	Lord High Chamberlain

We want to pass in an array which will be assigned to the array
C<@items>.  Here's how to do that:


	@items = ('ivory', 'apes', 'peacocks', );
	$template->fill_in();

This is not very safe.  The reason this isn't as safe is that if you
had any variables named C<$list> or C<$item> in scope in your program
at the point you called C<fill_in>, their values would be clobbered by
the act of filling out the template.  The problem is the same as if
you had written a subroutine that used those variables in the same
waythat the template does.

One solution to this is to make the C<$item> and C<$list> variables
private to the template by declaring them with C<my>.  If the template
does this, you are safe.  

But if you use the C<PACKAGE> option, you will probably be safe even
if the template does I<not> declare its variables with C<my>:

	@Q::items = ('ivory', 'apes', 'peacocks', );
	$template->fill_in(PACKAGE => 'Q');

In this case the template will clobber the variables C<$Q::item> and
C<$Q::list>, which are not related to the ones your program was using.

Templates cannot affect variables in the main program that are
declared with C<my>, unless you give the template references to those
variables.

=item C<HASH>

You may not want to put the template variables into a package.
Packages can be hard to manage:  You can't copy them, for example.
C<HASH> provides an alternative.  

The value for C<HASH> should be a reference to a hash that maps
variable names to values.  For example, 

	$template->fill_in(HASH => { recipient => "The King",
				     items => ['gold', 'frankincense', 'myrrh']
				   });

will fill out the template and use C<"The King"> as the value of
C<$recipient> and the list of items as the value of C<@items>.

The full details of how it works are a little involved, so you might
want to skip to the next section.

Suppose the key in the hash is I<key> and the value is I<value>.  

=over 4

=item 

If the I<value> is C<undef>, then any variables named C<$key>,
C<@key>, C<%KEY>, etc., are undefined.  

=item

If the I<value> is a string or a number, then C<$key> is set to that
value in the template.

=item 

If the I<value> is a reference to an array, then C<@key> is set to
that array.  If the I<value> is a reference to a hash, then C<%key> is
set to that hash.  Similarly if I<value> is any other kind of
reference.  This means that

	var => "foo"

and

	var => \"foo"

have almost exactly the same effect.  (The difference is that in the
former case, the value is copied, and in the latter case it is
aliased.)  

=back

Normally, the way this works is by allocating a private package,
loading all the variables into the package, and then filling out the
template as if you had specified that package.  A new package is
allocated each time.  However, if you I<also> use the C<PACKAGE>
option, C<Text::Template> loads the variables into the package you
specified, and they stay there after the call returns.  Subsequent
calls to C<fill_in> that use the same package will pick up the values
you loaded in.

If the argument of C<HASH> is a reference to an array instead of a
reference to a hash, then the array should contain a list of hashes
whose contents are loaded into the template package one after the
other.  You can use this feature if you want to combine several sets
of variables.  For example, one set of variables might be the defaults
for a fill-in form, and the second set might be the user inputs, which
override the defaults when they are present:

	$template->fill_in(HASH => [\%defaults, \%user_input]);

You can also use this to set two variables with the same name:

	$template->fill_in(HASH => [{ v => "The King" },
                                    { v => [1,2,3] },
	                           ]
                          );

This sets C<$v> to C<"The King"> and C<@v> to C<(1,2,3)>.	

=item C<BROKEN>

If any of the program fragments fails to compile or aborts for any
reason, C<Text::Template> will call the C<BROKEN> function that you
supply with the C<BROKEN> attribute.  The function will tell
C<Text::Template> what to do next.  The value for this attribute is a
reference to your C<BROKEN> function.  

If the C<BROKEN> function returns C<undef>, C<Text::Template> will
immediately abort processing the template and return the text that it
has accumulated so far.  If your function does this, it should set a
flag that you can examine after C<fill_in> returns so that you can
tell whether there was a premature return or not.

If the C<BROKEN> function returns any other value, that value will be
interpolated into the template as if that value had been the return
value of the program fragment to begin with.

If you don't specify a C<BROKEN> function, C<Text::Template> supplies
a default one that returns something like

	Program fragment at line 17 delivered error ``Illegal
	division by 0''

Since this is interpolated into the template at the place the error
occurred, a template like this one:

	(3+4)*5 = { 3+4)*5 }

yields this result:

	(3+4)*5 = Program fragment at line 1 delivered error
	``syntax error''

If you specify a value for the C<BROKEN> attribute, it should be a
reference to a function that C<fill_in> can call instead of the
default function.

C<fill_in> will pass an associative array to the C<broken> function.
The associative array will have at least these four members:

=over 4

=item C<text>

The source code of the program fragment that failed

=item C<error>

The text of the error message (C<$@>) generated by eval

=item C<lineno>

The line number of the template data at which the  program fragment
began

=back

There may also be an C<arg> member.  See C<BROKEN_ARG>, below

=item C<BROKEN_ARG>

If you supply the C<BROKEN_ARG> option to C<fill_in>, the value of the
option is passed to the C<BROKEN> function whenever it is called.  The
default C<BROKEN> function ignores the C<BROKEN_ARG>, but you can
write a custom C<BROKEN> function that uses the C<BROKEN_ARG> to get
more information about what went wrong. 

The C<BROKEN> function could also use the C<BROKEN_ARG> as a reference
to store an error message or some other information that it wants to
communicate back to the caller.  For example:

	$error = '';

	sub my_broken {	
	   my %args = @_;
	   my $err_ref = $args{arg};
	   ...
	   $$err_ref = "Some error message";
	   return undef;
	}

	$template->fill_in(BROKEN => \&my_broken,
			   BROKEN_ARG => \$error,
			  );

	if ($error) {
	  die "It didn't work: $error";
	}

If one of the program fragments in the template fails, it will call
the C<BROKEN> function, C<my_broken>, and pass it the C<BROKEN_ARG>,
which is a reference to C<$error>.  C<my_broken> can store an error
message into C<$error> this way.  Then the function that called
C<fill_in> can see if C<my_broken> has left an error message for ity
to find, and proceed accordingly.

=item C<SAFE>

If you give C<fill_in> a C<SAFE> option, its value should be a safe
compartment object from the C<Safe> package.  All evaluation of
program fragments will be performed in this compartment.  See L<Safe>
for full details.

=back

=head1 Convenience Functions

=head2 C<fill_this_in>

The basic way to fill in a template is to create a template object and
then call C<fill_in> on it.   This is useful if you want to fill in
the same template more than once.

In some programs, this can be cumbersome.  C<fill_this_in> accepts a
string, which contains the template, and a list of options, which are
passed to C<fill_in> as above.  It constructs the template object for
you, fills it in as specified, and returns the results.  It returns
C<undef> and sets C<$Text::Template::ERROR> if it couldn't generate
any results.

An example:

	$Q::name = 'Donald';
	$Q::amount = 141.61;
	$Q::part = 'hyoid bone';

	$text = Text::Template->fill_this_in( <<EOM, PACKAGE => Q);
	Dear {\$name},
	You owe me {sprintf('%.2f', \$amount)}.  
	Pay or I will break your {\$part}.
		Love,
		Grand Vizopteryx of Irkutsk.
	EOM

Notice how we included the template in-line in the program by using a
`here document' with the C<E<lt>E<lt>> notation.

C<fill_this_in> is probably obsolete.  It is only here for backwards
compatibility.  You should use C<fill_in_string> instead.  It is
described in the next section.

=head2 C<fill_in_string>

It is stupid that C<fill_this_in> is a class method.  It should have
been just an imported function, so that you could omit the
C<Text::Template-E<gt>> in the example above.  But I made the mistake
four years ago and it is too late to change it.

C<fill_in_string> is exactly like C<fill_this_in> except that it is
not a method and you can omit the C<Text::Template-E<gt>> and just say

	print fill_in_string(<<EOM, ...);
	Dear {$name},
	  ...
	EOM

To us C<fill_in_string>, you need to say

	use Text::Template 'fill_in_string';

at the top of your program.   You should probably use
C<fill_in_string> instead of C<fill_this_in>.

=head2 C<fill_in_file>

If you import C<fill_in_file>, you can say

	$text = fill_in_file(filename, ...);

The C<...> are passed to C<fill_in> as above.  The filename is the
name of the file that contains the template you want to fill in.  It
returns the result text. or C<undef>, as usual.

If you are going to fill in the same file more than once in the same
program you should use the longer C<new> / C<fill_in> sequence instead.
It will be a lot faster because it only has to read and parse the file
once.

=head2 Including files into templates

People always ask for this.  ``Why don't you have an include
function?'' they want to know.  The short answer is this is Perl, and
Perl already has an include function.  If you want it, you can just put

	{qx{cat filename}}

into your template.  Voila.

If you don't want to use C<cat>, you can write a little four-line
function that opens a file and dumps out its contents, and call it
from the template.  I wrote one for you.  In the template, you can say

	{Text::Template::_load_text(filename)}

If that is too verbose, here is a trick.  Suppose the template package
that you are going to be mentioning in the C<fill_in> call is package
C<Q>.  Then in the main program, write

	*Q::include = \&Text::Template::_load_text;

This imports the C<_load_text> function into package C<Q> with the
name C<include>.  From then on, any template that you fill in with
package C<Q> can say

	{include(filename)}

to insert the text from the named file at that point.

Suppose you don't want to insert a plain text file, but rather you
want to include one template within another?  Just use C<fill_in_file>
in the template itself:

	{Text::Template::fill_in_file(filename)}

You can do the same importing trick if this is too much to type.

=head1 Miscellaneous

=head2 C<my> variables

People are frequently surprised when this doesn't work:

	my $recipient = 'The King';
	my $text = fill_in_file('formletter.tmpl');

The text C<The King> doesn't get into the form letter.  Why not?
Because C<$recipient> is a C<my> variable, and the whole point of
C<my> variables is that they're private and inaccessible except in the
scope in which they're declared.  The template is not part of that
scope, so the template can't see them.  

If that's not what you want, don't use C<my>.  Put the variables into
package variables in some other package, and use the C<PACKAGE> option
to C<fill_in>, or pass the names and values in a hash with the C<HASH>
option.

=head2 Security Matters

All variables are evaluated in the package you specify with the
C<PACKAGE> option of C<fill_in>.  if you use this option, and if your
templates don't do anything egregiously stupid, you won't have to
worry that evaluation of the little programs will creep out into the
rest of your program and wreck something.

Nevertheless, there's really no way (except with C<Safe>) to protect
against a template that says

	{ $Important::Secret::Security::Enable = 0; 
	  # Disable security checks in this program 
	}

or

	{ $/ = "hoho";   # Sabotage future uses of <FH>.
	  # $/ is always a global variable
	}

or even

	{ system("rm -rf /") }

so B<don't> go filling in templates unless you're sure you know what's in
them.  If you're worried, use the C<SAFE> option.

As a final warning, program fragments run a small risk of accidentally
clobbering local variables in the C<fill_in> function itself.  These
variables all have names that begin with C<$fi_>, so if you stay away
from those names you'll be safe.  (Of course, if you're a real wizard
you can tamper with them deliberately for exciting effects.)

=head2 JavaScript

Jennifer D. St Clair asks:

	> Most of my pages contain JavaScript and Stylesheets.
        > How do I change the template identifier?  

Jennifer is worried about the braces in the JavaScript being taken as
the delimiters of the Perl program fragments.  Of course, disaster
will ensure when perl tries to evaluate these as if they were Perl
programs.

I didn't provide a facility for changing the braces to something else,
because it complicates the parsing, and in my experience it isn't
necessary.  There are two easy solutions:

1. You can put C<\> in front of C<{>, C<}>, or C<\> to remove its
special meaning.  So, for example, instead of

	    if (br== "n3") { 
		// etc.
	    }

you can put

	    if (br== "n3") \{ 
		// etc.
	    \}

and it'll come out of the template engine the way you want.

But here is another method that is probably better.  To see how it
works, first consider what happens if you put this into a template:

	    { 'foo' }

Since it's in braces, it gets evaluated, and obviously, this is going
to turn into

	    foo

So now here's the trick: In Perl, C<q{...}> is the same as C<'...'>.
So if we wrote

	    {q{foo}}

it would turn into 

	    foo

So for your JavaScdript, just write

	    {q{
	      if (br== "n3") { 
	  	  // etc.
	      }
	    }

and it'll come out as

	      if (br== "n3") { 
	  	  // etc.
	      }

which is what you want.

This trick is so easy that I thought didn't need to put in the feature
that lets you change the bracket characters to something else.

=head2 Compatibility

Every effort has been made to make this module compatible with older
versions.  The single exception is the output format of the default
C<BROKEN> subroutine; I decided that the olkd format was too verbose.
If this bothers you, it's easy to supply a custom subroutine that
yields the old behavior.

This version passes the test suite from the old version.  The old test
suite is too small, but it's a little reassuring.

=head2 A short note about C<$Text::Template::ERROR>

In the past some people have fretted about `violating the package
boundary' by examining a variable inside the C<Text::Template>
package.  Don't feel this way.  C<$Text::Template::ERROR> is part of
the published, official interface to this package.  It is perfectly OK
to inspect this variable.  The interface is not going to change.

If it really, really bothers you, you can import a function called
C<TTerror> that returns the current value of the C<$ERROR> variable.
So you can say:

	use Text::Template 'TTerror';

	my $template = new Text::Template (SOURCE => $filename);
	unless ($template) {
	  my $err = TTerror;
	  die "Couldn't make template: $err; aborting";
	}

I don't see what benefit this has over just doing this:

	use Text::Template;

	my $template = new Text::Template (SOURCE => $filename)
	  or die "Couldn't make template: $Text::Template::ERROR; aborting";

But if it makes you happy to do it that way, go ahead.

=head2 Sticky Widgets in Template Files

The C<CGI> module provides functions for `sticky widgets', which are
form input controls that retain their values from one page to the
next.   Sometimes people want to know how to include these widgets
into their template output.

It's totally straightforward.  Just call the C<CGI> functions from
inside the template:

	{ $q->checkbox_group(NAME => 'toppings',
		  	     LINEBREAK => true,
			     COLUMNS => 3,
			     VALUES => \@toppings],
			    );
	}


=head2 Author

Mark-Jason Dominus, Plover Systems

C<mjd-perl-template@pobox.com>

You can join a very low-volume (E<lt>10 messages per year) mailing
list for announcements about this package.  Send an empty note to
C<mjd-perl-template-request@plover.com> to join.

For updates, visit C<http://www.plover.com/~mjd/perl/Template/>.

=head2 Support?

This software is version 1.0.  It is a complete rewrite of an older
package, and may have bugs.  It is inadequately tested.  Suggestions
and bug reports are always welcome.  Send them to
C<mjd-perl-template@plover.com>.

=head2 Thanks

Many thanks to the following people for offering support,
encouragement, advice, and all the other good stuff.  Especially to
Jonathan Roy for telling me how to do the C<Safe> support (I spent two
years worrying about it, and then Jonathan pointed out that it was
trivial.)

Klaus Arnhold /
Mike Brodhead /
Tom Brown /
Tim Bunce /
Juan E. Camacho /
Joseph Cheek /
San Deng /
Bob Dougherty /
Dan Franklin /
Todd A. Green /
Michelangelo Grigni /
Tom Henry /
Matt X. Hunter /
Robert M. Ioffe /
Daniel LaLiberte /
Reuven M. Lerner /
Joel Meulenberg /
Jason Moore /
Bek Oberin /
Ron Pero /
Hans Persson /
Jonathan Roy /
Jennifer D. St Clair /
Uwe Schneider /
Randal L. Schwartz /
Michael G Schwern /
Brian C. Shensky /
Niklas Skoglund /
Tom Snee /
Hans Stoop /
Michael J. Suzio /
Dennis Taylor /
James H. Thompson /
Shad Todd /
Andy Wardley /
Matt Womer /
Andrew G Wood /
Michaely Yeung

=head2 Bugs and Caveats

C<my> variables in C<fill_in> are still susceptible to being clobbered
by template evaluation.  They all begin with C<fi_>, so avoid those
names in your templates.

Maybe there should be a utility method for emptying out a package?Or
for pre-loading a package from a hash?

Maybe there should be a control item for doing C<#if>.  Perl's `if' is
sufficient, but a little cumbersome to handle the quoting.  Ranjit and
I brainstormed a wonderful general solution to this which may be
forthcoming.

The line number information will be wrong if the template's lines are
not terminated by C<"\n">.  Someone should let me know if this is a
problem.

There are not enough tests in the test suite.

=cut

