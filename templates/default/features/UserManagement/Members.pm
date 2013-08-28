package [% appname %]::Controller::Members;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub m : Chained('/login/required') PathPart('members') CaptureArgs(0) {}

sub hello :Chained(m) {
  # An action for /members/hello
  # Only accessible for logged-in users
  my ( $self, $c ) = @_;
  $c->res->body('Welcome, member');
}

__PACKAGE__->meta->make_immutable;

1;
