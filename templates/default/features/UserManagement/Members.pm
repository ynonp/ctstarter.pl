package [% appname %]::Controller::Members;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
  action => {
    '*' => { Chained => 'base' },
    base => { Chained => '/login/required', PathPart => 'members', CaptureArgs => 0 },
  },
);

sub base {}

# All actions in this controller are automatically chained
# on /login/required
# Note: don't use Local or Path when defining new actions,
# this will break the chain. Simply use GET, POST, etc.

sub hello :GET {
  # An action for /members/hello
  # Only accessible for logged-in users
  my ( $self, $c ) = @_;
  $c->res->body('Welcome, member');
}

__PACKAGE__->meta->make_immutable;

1;
