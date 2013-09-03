use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::DefaultGenerator {
  use Moose;
  use File::Find;
  use File::chdir;
  use Catalyst::Helper;

  with 'CatalystX::ProjectBuilder::Feature';

  sub required_keys { }

  sub process {
    my ( $self ) = @_;
    local $CWD = '..';
    # Using the defaults from catalyst.pl file
    my $helper = Catalyst::Helper->new(
      {
        '.newfiles' => 1,
        'makefile'  => 0,
        'scripts'   => 0,
        name => $self->conf->{appname},
      }
    );

    pod2usage(1) unless $helper->mk_app( $self->conf->{appname} );
  }

}

1;
