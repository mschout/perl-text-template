# Text::Template.pm
#
# Fill in `templates'
#
# Copyright 1995 M-J. Dominus.
# You may copy and distribute this program under the
# same terms as Perl iteself.  If in doubt, write to mjd@pobox.com
# for a license.
#
# Version 0.1 alpha $Revision: 1.2 $ $Date: 1995/12/27 18:43:47 $

=head1 Text::Template

This is a library for printing form letters!  This is a library for
playing Mad Libs!  

A `template' is a piece of text that has little Perl programs embedded
in it here and there.  When you `fill in' a template, you evaluate the
little programs and replace them with their values.

This is a good way to generate many kinds of output, such as error
messages and HTML pages.  Here is one way I use it: I am a freelance
computer consultant; I write world-wide web applications.  Usually I
work with an HTML designer who designs the pages for me.

Often these pages change a lot over the life of the project: The
client's legal department takes several tries to get the disclaimer
just right; the client changes the background GIF a few times; the
text moves around, and soforth.  These are all changes that are easy
to make.  Anyone proficient with the editor can go and make them.  But
if the page is embedded inside a Perl program, I don't want the
designer to change it because you never know what they might muck up.
I'd like to put the page in an external file instead.

The trouble with that is that parts of the page really are generated
by the program; it needs to fill in certani values in some places,
maybe conditionally include some text somewhere else.  The page can't
just be a simple static file that the program reads in and prints out.

A template has blanks, and when you print one out, the blanks are
filled in automatically, so this is no trouble.  And because the
blanks are small and easy to recognize, it's easy to tell the page
designer to stay away from them.

Here's a sample template:

	Dear {$title} {$lastname},

	It has come to our attention that you are delinquent in your
	{$last_paid_month} payment.  Please remit ${$amount} immediately,
	or your patellae may be needlessly endangered.

			Love,

			Mark "Vizopteryx" Dominus


Pretty simple, isn't it?  Items in curly braces C<{> C<}> get filled
in; everything else stays the same.  Anyone can understand that.  You
can totally believe that the art director isn't going to screw this up
while editing it.

You can put any perl code you want into the braces, so instead of
C<{$amount}>, you might want to use C<{sprintf("%.2f", $amount)}>, to
print the amount rounded off to the nearest cent.

This is good for generating form letters, HTML pages, error messages,
and probably a lot of other things.  

Detailed documentation follows:

=cut

package Text::Template;

use Exporter ;
@ISA = qw(Exporter);

=head1 Version
  Version Text::Template ();

Returns the current version of the C<Text::Template> package.  The
current version is C<'Text::Template 0.1 alpha $Revision: 1.2 $ $Date: 1995/12/27 18:43:47 $'>.

=cut

sub Version {
  'Text::Template 0.1 alpha $Revision: 1.2 $ $Date: 1995/12/27 18:43:47 $';
}

=head1 Constructor: C<new>

  new Text::Template ( attribute => value, ... );

This creates a new template object.  You specify the source of the
template with a set of attribute-value pairs in the arguments.

At present, there are only two attributes.  One is C<type>; the other
is C<source>.  C<type> can be C<FILEHANDLE>, C<FILE>, or C<ARRAY>.  
If C<type> is C<FILE>, then the C<source> is interpreted as the name
of a file that contains the template to fill out.  If C<type> is
C<FILEHANDLE>, then the C<source> is interpreted as the name of a
filehandle, which, when read, will deliver the template to fill out.
A C<type> of C<ARRAY> means that the C<source> is a reference to an
array of strings; the template is the concatentation of these strings.

Neither C<type> nor C<source> are optional yet.  

Here are some examples of how to call C<new>:

	$template = new Text::Template 
		('type' => 'ARRAY', 
		 'source' => [ "Dear {\$recipient}\n",
				"Up your {\$nose}.\n",
				"Love, {\$me}.\n" ]);


	$template = new Text::Template 
		('type' => 'FILE', 
		 'source' => '/home/mjd/src/game/youlose.tmpl');

C<new> returns a template object on success, and C<undef> on failure.  On
an error, it puts an error message in the variable
C<$Text::Template::ERROR>.

=cut

sub new {
  my $package = shift;
  my $parser = {};
  $parser->{'lookahead'} = undef; # Type of next token
  $parser->{'yylval'} = undef;	# Semantic value of next token
  $parser->{'nextplease'} = 1;
  $parser->{'state'} = 0 ;
  $parser->{'states'} = [] ;
  $parser->{'privpack'} = 'Text::Template::pack::' . &gensym;
  $parser->{'values'} = [];	# Value stack
  return undef unless $parser->{'lexer'} = new Text::Template::Lexer @_;
  return bless $parser, $package;
}

$sym = 'sym000';
sub gensym {
  return $sym++;
}


=head1 C<fill_in>

Fills in a template.  Returns the resulting text.

Like C<new>, C<fill_in> accepts a set of attribute-value pairs.  At
present, the only attributes are C<package> and C<broken>. 

Here's an example: Suppose that C<$template> contains a template
object that we created with this template:

	Dear {$name},
		You owe me ${sprintf("%.2f", $amount)}.
		Pay or I will break your {$part}.
				Love,
				Uncle Dominus.  

Here's how you might fill it in:

        $name = 'Donald';
	$amount = 141.61;
	$part = 'hyoid bone';

	$text = $template->fill_in();

Here's another example:

	Your Royal Highness,

		Enclosed please find a list of things I have gotten
		for you since 1907:

		{ $list = '';
		  foreach $item (@things) {
		    $list .= " o \u$item\n";
		  }
		  $list
		}

			Signed,
			Lord Chamberlain

We want to pass in an array which will be assigned to the array
C<@things>.  Here's how to do that:

	@the_things = ('ivory', 'apes', 'peacocks', );
	$template->fill_in();


This is not very safe.  The reason this isn't as safe is that if you
had any variables named C<$list> or $<$item> in scope in your program
at the point you called C<fill_in>, their values would be clobbered by
the act of filling out the template.  

The next section will show how to make this safer.

=head2 C<package>

The value of the C<package> attribute names a package which contains
the variables that should be used to fill in the template.  If you
omit the C<package> attribute, C<fill_in> uses the package that was
active when it was called.

Here's a safer version of the `Lord Chamberlain' example from the
previous section:

	@VARS::the_things = ('ivory', 'apes', 'peacocks', );
	$template->fill_in('package' => VARS);

This call to C<fill_in> clobbers C<$VARS::list> and C<$VARS::item>
instead of clobbering C<$list> and C<$item>.  If your program didn't
use anything in the C<VARS> package, you don't have to worry that
filling out the template is altering on your variables.
	
=head2 broken 

If you specify a value for the C<broken> attribute, it should be a
reference to a function that C<fill_in> can call if one of the little
programs fails to evaluate.

C<fill_in> will pass an associative array to the C<broken> function.
The associative array will have at least these two members:

	text => (The full text of the little program that failed)
	error => (The text of the error message (C<$@>) generated by eval)

If the C<broken> function returns a text string, C<fill_in> will
insert it into the template in place of the broken program, just as
though the broken program had evaluated successfully and yielded that
same string.  If the C<broken> function returns C<undef>, C<fill_in>
will stop filling in the template, and will immediately return undef
itself.

If you don't specify a C<broken> function, you get a default one that
inserts something like this:

	Warning

	This part of the template returned the following errors:

	syntax error at -e line 1, near "$amount;"
	Missing right bracket at -e line 1, at end of line
	Execution of -e aborted due to compilation errors.

		
=cut

sub fill_in {
  my $fi_self = shift;
  my %fi_args = @_;
  my $fi_pack = $fi_args{'package'};
  
  unless ($fi_pack) {
    ($fi_pack) = caller(1);
  }

  my $fi_eval_failed = $fi_args{'broken'} || \&default_broken;

  for (;;) {
    my ($fi_type, $fi_value) = $fi_self->{'lexer'}->get();
    return undef unless defined($fi_type);
    if ($fi_type eq EOF) {
      return $fi_output;
    } elsif ($fi_type eq 'PLAINTEXT') {
      $fi_output .= $fi_value;
    } elsif ($fi_type eq 'PROGTEXT') {
      my $fi_val = eval "package $fi_pack; $fi_value";
      if ($@) {
	$fi_val = &$fi_eval_failed($fi_value, $@);
	return undef unless defined($fi_val);
      } 
      $fi_output .= $fi_val;
    } else {
      $ERROR = "Unexpected error in Template module: Lexer returned bizarre token type=$fi_type.";
      return undef;
    }
  }
}

sub default_broken {
  my (%args) = @_;
  my ($prog_text, $error_text) = @args{'text', 'error'};

  return <<EOM;
Warning

This part of the template returned the following errors:

$err_text

EOM
}


=head1 C<fill_this_in>

Maybe it's not worth your trouble to put the template into a file;
maybe it's a small file, and you want to leave it inline in the code.
Maybe you don't want to have to worry about managing template objects.
In that case, use C<fill_this_in>.  You give it the entire template as
a string argument, follow with variable substitutions just like in
C<fill_in>, and it gives you back the filled-in text.

An example:

	$Q::name = 'Donald';
	$Q::amount = 141.61;
	$Q::part = 'hyoid bone';

	$text = fill_this_in Text::Template ( <<EOM, 'package' => Q);
	Dear {\$name},
	You owe me {sprintf('%.2f', \$amount)}.  
	Pay or I will break your {\$part}.
		Love,
		Grand Vizopteryx of Irkutsk.
	EOM


=cut

sub fill_this_in {
  my $package = shift;
  my $template = shift;
  my $tmpl = $package->new('type' => ARRAY, 'source' => [$template]);
  return undef unless $tmpl;
  my $result = $tmpl->fill_in(@_);
  return $result;
}

=head1 Template Format

Here's the deal with templates: Anything in braces is a little
program, which is evaluated, and replaced with its perl value.  A
backslashed character has no special meaning, so to include a literal
C<{> in your template, use C<\{>, and to include a literal C<\>, use
C<\\>.  

A little program starts at an open brace and ends at the matching
close brace.  This means that your little programs can include braces
and you don't need to worry about it.  See the example below for an
example of braces inside a little program.

If an expression at the beginning of the template has side effects,
the side effects carry over to the subsequent expressions.  For
example:

	{$x = @things; ''} The lord high Chamberlain has gotten {$x}
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

Notice that after we set $x in the first little program, its value
carries over to the second little program, and that we can set
C<$diff> and C<$more> on one place and use their values again later.

All variables are evaluated in the package you specify as an argument
to C<fill_in>.  This means that if your templates don't do anything
egregiously stupid, you don't have to worry that evaluation of the
little programs will creep out into the rest of your program and wreck
something.  On the other hand, there's really no way to protect
against a template that says

	{ $Important::Secret::Security::Enable = 0; 
	  # Disable security checks in this program 
	}

or even

	{ system("rm -rf /") }

so B<don't> go filling in templates unless you're sure you know what's in
them.  This package may eventually use Perl's C<Safe> extension to
fill in templates in a safe compartment.

=head1 Author

Mark-Jason Dominus, Plover Systems

C<mjd@pobox.com>

=head1 Support?

This software is version 0.1 alpha.  It probably has bugs.  It is
inadequately tested.  Suggestions and bug reports are always welcome.

=head1 Bugs

This package should fill in templates in a C<Safe> compartment.

The callback function that C<fill_in> calls when a template contains
an error should be eble to return an error message to the rest of the
program.

`my' variables in C<fill_in> are still susceptible to being clobbered
by template evaluation.  Perhaps it will be safer to make them `local'
variables.

Maybe there should be a utility method for emptying out a package?

=cut

package Text::Template::Lexer;

# lexer has the following elements:
# source, an input source (a filehandle or array of strings)
# type, an input type (FILE, FILEHANDLE, ARRAY)
# unbuf, an unget buffer (array of single-char strings)

$fh = 'Text_Template_Lexer_FH00';

%legal_type = ( 'FILE' => 1, 'FILEHANDLE' => 1, 'ARRAY' => 1 );	

sub new {
  my $package = shift;
  my $lexer = { @_ };
  unless ($lexer->{'type'}) {
    $Text::Template::ERROR = 
	"You must specify a `type'.";
    return undef;
  }
  unless ($legal_type{$lexer->{'type'}}) {
    my @types = keys %legal_type;
    $Text::Template::ERROR = 
	"{$lexer->{'type'} is not a legal source type.  Legal types are (@types)";
    return undef;
  }
  unless ($lexer->{'source'}) {
    $Text::Template::ERROR = 
	"You must specify a `source'.";
    return undef;
  }
  if ($lexer->{'type'} eq FILE) {
    my $filename = $lexer->{'source'};
    my $fh = &new_fh();
    unless (open($fh, "< $filename")) {
      $Text::Template::ERROR = 
	  "Couldn\'t open file $filename for reading: $!";
      return undef;
    }
    $lexer->{'source'} = $fh;
    $lexer->{'type'} = FILEHANDLE;
  }
  $lexer->{'unbuf'} = [ ];
  bless $lexer, $package;
}

# return token type , value pair for next token
# types are:
# PLAINTEXT  value is text
sub get {
  my $self = shift;
  my $bracecount = 0;
  my $string;
  my $c = '';

  while ($c ne EOF) {
    $c = $self->get_a_char();
    if ($c eq '{') {
      if ($string) {
	$self->unget_a_char($c);
	return (PLAINTEXT, $string);
      } else {
	# read up to matching close brace into $string
	$bracecount += 1;
	while ($bracecount) {
	  $c = $self->get_a_char();
	  $string .= $c;
	  if ($c eq '{') {
	    $bracecount += 1;
	  } elsif ($c eq '}') {
	    $bracecount -= 1;
	  } elsif ($c eq EOF) {
	    $Text::Template::ERROR = 
		"End of template inside a little program!";
	    return undef;
	  }
	}
	chop $string;		# Chop last close brace
	return (PROGTEXT, $string);
      }
    } elsif ($c eq '\\') {
      my $cc = $self->get_a_char();
      return undef unless defined($cc);
      if ($cc eq EOF) {
	$string .= '\\';
      } else {
	$string .= $cc;
      }
    } elsif ($c eq EOF) {
      if ($string eq '') {
	return EOF;
      } else {
	return (PLAINTEXT, $string);
      }
    } else {
      $string .= $c;
    }
  }
}

sub get_a_char { 
  my $self = shift;
  my $c;

  if (@{$self->{'unbuf'}}) {
    return shift @{$self->{'unbuf'}};
  } 

  if ($self->{'type'} eq FILEHANDLE) {
    $c = getc($self->{'source'});
    return EOF if $c eq '';
    return $c;
  } elsif ($self->{'type'} eq 'ARRAY') {
    my @nextchars;

    # Get the next string from the input arry and split it into an
    # array of characters.  If the string is empty, skip it and get
    # another.  If you run out of strings, return EOF.
    until (@nextchars = split(//, shift @{$self->{'source'}})) {
      return EOF unless @{$self->{'source'}};
    }

    $c = shift @nextchars;
    $self->{'unbuf'} = [ @nextchars ];
    return $c;
  } else {
    $Text::Template::ERROR = 
	"Unknown input source type: {$self->{'type'}}";
    return undef;
  }
}
sub unget_a_char {
  my $self = shift;
  my $c = shift;

  unshift(@{$self->{'unbuf'}}, $c);
  return;
}

  
sub new_fh {
  return $fh++;
}
