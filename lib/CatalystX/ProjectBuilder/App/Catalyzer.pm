use strict;
use warnings;

package CatalystX::ProjectBuilder::App::Catalyzer;
use Moose;
use Config::Any;

with 'MooseX::Getopt::Dashes';

has 'template', is => 'ro', isa => 'Str', required => 1;

has 'define', is => 'ro', isa => 'HashRef';
has 'config_file', is => 'ro', isa => 'Str';

has 'dsn', is => 'ro', isa => 'Str';
has 'appname', is => 'ro', isa => 'Str';

has 'conf', is => 'ro', isa => 'HashRef', lazy_build => 1;

sub _build_conf {
  my ( $self ) = @_;
  my $result = {};

  if ( $self->config_file ) {
    my $cfg = Config::Any->load_files({ files => [ $self->config_file ] });
    use Data::Dumper;

    ( $result ) = values %{ $cfg->[0] };
    print Dumper( $result );
  }

  $result->{appname} = $self->appname if $self->appname;
  $result->{dsn}     = $self->dsn     if $self->dsn;

  return $result;
}

sub run {
  my ( $self ) = @_;

  my $template = $self->template;
  my $conf = $self->conf;
  my $appname = $self->conf->{appname} or die 'appname must be specified';

  my $builder = CatalystX::ProjectBuilder->new( conf => $conf );
  $builder->gen_from_template( $template, $appname );
  $builder->apply_features;
  $builder->post_process;
}



1;

