
package Text::Template::Preprocess;
use Text::Template;
@ISA = qw(Text::Template);

sub fill_in {
  my $self = shift;
  my (%args) = @_;
  my $pp = $args{PREPROCESSOR} || $self->{PREPROCESSOR} ;
  if ($pp) {
    local $_ = $self->source();
    &$pp;
    $self->source($_);
  }
  $self->SUPER::fill_in(@_);
}

sub preprocessor {
  my ($self, $pp) = @_;
  my $old_pp = $self->{PREPROCESSOR};
  $self->{PREPROCESSOR} = $pp if @_ > 1;  # OK to pass $pp=undef
  $old_pp;
}

1;
