use strict;
use warnings;
use autodie;

package CatalystX::ProjectBuilder::Feature {
  use Moose::Role;
  use Path::Class::File;
  use Path::Class::Dir;
  use Template;

  use File::Slurp qw/read_file write_file/;
  use Hash::Merge;
  use Config::General;

  requires 'required_keys';

  has 'conf', isa => 'HashRef', is => 'ro', required => 1;
  has 'base_dir', isa => 'Str', is => 'ro', required => 1;
  has 'data_dir', isa => 'Str', is => 'ro', lazy_build => 1;

  has 'plugin_mgr' => (
    is => 'ro',
    does => 'CatalystX::ProjectBuilder::PluginManager',
    required => 1,
  );

  sub process {}
  sub post_process {}

  sub BUILD {
    my ( $self ) = @_;

    my @keys = $self->required_keys;
    foreach my $key ( @keys ) {
      die "Missing Key: $key" if ! exists $self->conf->{$key};
    }
  }

  sub _build_data_dir {
    my ( $self ) = @_;
    my $feature_name = ref($self) =~ s/^CatalystX::ProjectBuilder::Features:://r;

    my $rel_data_path = $feature_name =~ s/::/_/gr;

    my $dir = Path::Class::Dir->new( $self->base_dir, 'features', $rel_data_path );
    return $dir->stringify;
  }

  sub config_file_name {
    my ( $self ) = @_;

    die "Missing appname" if ! $self->conf->{appname};

    Path::Class::File->new(
      $self->base_dir,
      lc( $self->conf->{appname} ) =~ s/::/_/gr
    )->stringify . ".conf";
  }


  sub add_config_data {
    my ( $self, $new_data_ref ) = @_;

    my $m = Hash::Merge->new('RIGHT_PRECEDENT');
    my $cg = Config::General->new( -ConfigFile => $self->config_file_name,
                                   -ForceArray => 1 );
    my %config = $cg->getall;

    my $merged_data_ref = $m->merge( \%config, $new_data_ref );

    $cg->save_file( $self->config_file_name, $merged_data_ref );
  }

  around 'required_keys' => sub {
    my $orig = shift;
    my $self = shift;

    my @keys = $self->$orig;
    if ( @keys == 1 && ref($keys[0]) ) {
      @keys = @{ $keys[0] };
    }

    return ( 'appname', @keys );
  }

}

1;

