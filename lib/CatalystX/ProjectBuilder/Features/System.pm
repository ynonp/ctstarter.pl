use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::System {
  use Moose;
  use File::Find;

  with 'CatalystX::ProjectBuilder::Feature';

  sub required_keys { }

  sub process {
    my ( $self ) = @_;
    my $commands_ref = $self->conf->{System};
    system( $_ ) for @$commands_ref;
  }

}

1;

