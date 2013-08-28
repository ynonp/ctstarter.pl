use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::UserManagement {
  use Moose;

  with 'CatalystX::ProjectBuilder::Feature';
  with 'CatalystX::ProjectBuilder::GenFiles';

  sub required_keys { }

  sub post_process {
    my ( $self, $c ) = @_;
    my $user = $c->model('DB::User');
    $user->create({
      username => 'admin',
      active => 'Y',
      name => 'Administrator',
      email_address => 'admin@myapp.com',
      password => 'ninja',
    });

    my $admin_role = $c->model('DB::Role')->create({
      name => 'admin',
    });

    $c->model('DB::Role')->create({
      name => 'user',
    });

    $user->find({ username => 'admin'})->add_to_roles( $admin_role );
  }


  sub process {
    my ( $self ) = @_;
    $self->add_config_data({
        Plugin => {
          Authentication => {
            realms => {
              default => {
                credential => {
                  class => 'Password',
                  password_field => 'password',
                  password_type => 'self_check',
                },
                store => {
                  class => 'DBIx::Class',
                  user_model => 'DB::User',
                  role_relation => 'roles',
                  role_field => 'name',
                }
              }
            }
          }
        },

        Controller => {
          Login => {
            traits => [qw/-RenderAsTTTemplate/],
            login_form_args => {
              authenticate_args => {
                active => 'Y',
              }
            }
          }
        }
      });

    my @rs_path = qw/lib db Schema Result/;
    my @app_path = split /::/, $self->conf->{appname};

    $self->gen_file('UserRole.pm', { to => [@rs_path, 'UserRole.pm']});
    $self->gen_file('Role.pm', { to => [@rs_path, 'Role.pm']});
    $self->gen_file('User.pm', { to => [@rs_path, 'User.pm']});

    $self->t_gen_file('reset_admin_password.pl', { to => ['script', 'reset_admin_password.pl'] });
    $self->t_gen_file('Members.pm', { to => ['lib', @app_path , 'Controller', 'Members.pm']});

    $self->plugin_mgr->add_plugin(qw/
      Authentication
      Session
      Session::Store::FastMmap
      Session::State::Cookie
      Static::Simple

      +CatalystX::SimpleLogin
      Authorization::Roles
    /);
  }
}

1;



