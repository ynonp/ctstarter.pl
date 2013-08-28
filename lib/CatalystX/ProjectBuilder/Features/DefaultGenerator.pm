use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::DefaultGenerator {
  use Moose;
  use File::Find;
  use File::chdir;

  with 'CatalystX::ProjectBuilder::Feature';

  sub required_keys { }

  sub process {
    my ( $self ) = @_;
    local $CWD = '..';
    system('catalyst.pl', $self->conf->{appname});
  }

}

1;
