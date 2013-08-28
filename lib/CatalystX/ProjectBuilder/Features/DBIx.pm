use strict;
use warnings;
use v5.16;

package CatalystX::ProjectBuilder::Features::DBIx {
  use Moose;
  use Path::Class::Dir;

  with 'CatalystX::ProjectBuilder::Feature';
  with 'CatalystX::ProjectBuilder::GenFiles';

  sub required_keys { qw/dsn/ }

  sub process {
    my ( $self ) = @_;
    $self->add_config_data({
        Model => {
          DB => {
            schema_class => 'db::Schema',
            traits => 'Caching',
            connect_info => {
              dsn => $self->conf->{dsn},
            }
          }
        }
      });

    my @path = split /::/, $self->conf->{appname};

    $self->t_gen_file('DB.pm',   { to => ['lib', @path, 'Model', 'DB.pm'] });
    $self->t_gen_file('upgrade_db.pl', { to => ['script', 'upgrade_db.pl'] });

    $self->gen_file('Schema.pm', { to => [qw/lib db Schema.pm/]});

    Path::Class::Dir->new( $self->base_dir, 'share' )->mkpath;
  }

  sub post_process {
    my ( $self ) = @_;
    $self->deploy_initial_db;
  }


  sub deploy_initial_db {
    my ( $self ) = @_;
    my $dsn = $self->conf->{dsn};
    mkdir('share');

    my @opts = (
      '--lib'          => 'lib',
      '--schema_class' => 'db::Schema',
      '--dsn'          => $dsn,
    );

    system('dbic-migration', 'prepare', @opts );
    system('dbic-migration', 'install', @opts );
  }

}

1;


