use strict;
use warnings;

package CatalystX::ProjectBuilder::PluginManager;
use Moose::Role;
use File::Slurp qw/read_file write_file/;
use Path::Class::File;
use Path::Class::Dir;
use List::MoreUtils qw/uniq/;

requires 'base_dir';
requires 'conf';

has 'plugins' => (
  isa => 'ArrayRef[Str]',
  is => 'rw',
  default => sub { [] },
  traits => [qw/Array/],
  handles => {
    add_plugin => 'push'
  }
);

sub write_plugins {
  my ( $self ) = @_;
  $self->plugins( [ uniq @{ $self->plugins } ] );

  $self->_add_plugins_to_appfile;
  $self->_add_plugins_to_makefile;
}

sub _add_plugins_to_makefile {
  my ( $self ) = @_;
  my $makefile_name = Path::Class::File->new($self->base_dir, 'Makefile.PL')->stringify;

  my $content = read_file( $makefile_name );
  my $MARKER = qr {test_requires 'Test::More' => '[\d.]+';};
  my @plugins = @{ $self->plugins };

  my $plugins = join("\n", map {
    !/^\+/ ? "requires \'Catalyst::Plugin::$_\';" :
    "requires \'" . substr($_, 1) . "\';"
    } @plugins);

  $content =~ s/($MARKER)/${plugins}\n\n${1}/;
  write_file( $makefile_name, $content );
}

sub _add_plugins_to_appfile {
  my ( $self, $appfile_name ) = @_;

  if ( ! $appfile_name ) {
    # appfile_name not provided, try to figure it out using conf
    $appfile_name = $self->_appfile_from_conf;
  }

  my $appfile_content = read_file( $appfile_name );
  my $plugins_line = join("\n    ", @{ $self->plugins });

  $appfile_content =~ s{
    ^ \s* use \s* Catalyst \s* qw/ (.*?) /
  }{
    use Catalyst qw/
    $1
    $plugins_line
    /}xms;

  write_file( $appfile_name, $appfile_content );
}

sub _appfile_from_conf {
  my ( $self ) = @_;

  die "Missing appname" if ! $self->conf->{appname};

  my $appname = $self->conf->{appname};
  my @app_path = split /::/, $appname;
  $app_path[-1] .= ".pm";

  Path::Class::File->new( $self->base_dir,
    'lib',
    @app_path )->stringify;
}

1;
