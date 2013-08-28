use strict;
use warnings;

package CatalystX::ProjectBuilder::Features::TwitterBootstrapView;
use Moose;
with 'CatalystX::ProjectBuilder::Feature';
with 'CatalystX::ProjectBuilder::GenFiles';

sub required_keys {}


sub process {
  my ( $self ) = @_;

  $self->gen_dir({ from => ['css'], to => ['root', 'static', 'css'] });
  $self->gen_dir({ from => ['js'], to => ['root', 'static', 'js'] });
  $self->gen_dir({ from => ['fonts'], to => ['root', 'static', 'fonts'] });

  $self->gen_dir({ from => ['include'], to => ['root']});

  my @app_path = split /::/, $self->conf->{appname};
  $self->t_gen_file('HTML.pm', { to => ['lib', @app_path, 'View', 'HTML.pm']});
}




1;
