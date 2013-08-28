use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::AddPlugins {
  use Moose;
  use File::Find;

  with 'CatalystX::ProjectBuilder::Feature';

  sub required_keys { }

  sub process {
    my ( $self ) = @_;

    my $plugins_to_add_ref = $self->conf->{AddPlugins};
    if ( ref( $plugins_to_add_ref ) eq 'ARRAY' ) {
      $self->plugin_mgr->add_plugin( @$plugins_to_add_ref );
    }

  }
}

1;

