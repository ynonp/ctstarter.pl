use strict;
use warnings;

package CatalystX::ProjectBuilder {
  use Moose;
  use File::Path qw/make_path/;
  use YAML::Tiny;
  use Path::Class::Dir;
  use File::chdir;

  use CatalystX::ProjectBuilder::Feature;

  has 'base_dir', is => 'rw', isa => 'Str';
  has 'conf', is => 'rw', required => 1;
  has 'features' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
  );

  with 'CatalystX::ProjectBuilder::PluginManager';

  sub _extract_feature_item {
    my ( $self, $item ) = @_;
    my $hm = Hash::Merge->new('LEFT_PRECEDENT');

    my $conf = $self->conf;
    my $name = $item;

    if ( ref($item) eq 'HASH' ) {
      # feature_item is a hash ref, so it includes a name
      # AND additional config options
      ( $name ) = keys %$item;

      if ( ref($item->{$name}) eq 'ARRAY' ) {
        $conf->{$name} = $item->{$name};
      } elsif ( ref($item->{$name}) eq 'HASH' ) {
        $conf = $hm->merge( $self->conf, $item->{$name} );
      } else {
        die "Invalid defaults for feature $name. Array or Hash expected";
      }
    }

    return ( $name, $conf );
  }

  sub _build_features {
    my ( $self ) = @_;
    my $features_path = $self->base_dir . '/features.yaml';

    my $yml = YAML::Tiny->read( $features_path ) or die "Error reading features.yaml. Reason ", YAML::Tiny->errstr;
    my $features_ref = $yml->[0];

    die 'No features found' if ref($features_ref) ne 'ARRAY';

    my @result;

    foreach my $item ( @$features_ref ) {
      my ( $name, $conf ) = $self->_extract_feature_item( $item );

      my $feature_name = "CatalystX::ProjectBuilder::Features::" . $name;
      eval "require $feature_name";
      die $@ if $@;

      my $feature = $feature_name->new(
        base_dir => $self->base_dir, conf => $conf, plugin_mgr => $self );
      push @result, $feature;
    }
    return \@result;
  }

  sub gen_from_template {
    my ( $self, $template, $into ) = @_;
    $into =~ s/::/-/g;

    my $base_dir = Path::Class::Dir->new( $into );
    $self->base_dir( $base_dir->absolute->stringify );

    my $cloner = CatalystX::ProjectBuilder::Cloner->from( $template );
    $cloner->to( $into );

    if ( -d "${into}/features" ) {
      require $_ for glob("${into}/features/*.pm");
    }
  }


  sub apply_features {
    my ( $self ) = @_;
    local $CWD = $self->base_dir;

    $_->process for @{ $self->features };
  }

  sub post_process {
    my ( $self ) = @_;
    $self->write_plugins;

    my $appname = $self->conf->{appname};
    my $lib_path = Path::Class::Dir->new( $self->base_dir, 'lib' );

    unshift @INC, $lib_path->stringify;
    eval "require $appname";

    my $app = $appname->new;

    local $CWD = $self->base_dir;
    $_->post_process($app) for @{ $self->features };
  }

}

package CatalystX::ProjectBuilder::Cloner {

  my $GIT_URL = qr{
    https://github.com .* [.]git$
  }x;

  sub from {
    my $self = shift;
    my $src = shift;

    if ( -d $src ) {
      return CatalystX::ProjectBuilder::Cloner::FromLocalPath->new( src => $src, @_ );
    } elsif ( $src =~ /$GIT_URL/ ) {
      return CatalystX::ProjectBuilder::Cloner::FromGit->new( src => $src, @_ );
    } else {
      die "Unknown Template: $src";
    }
  }
}

package CatalystX::ProjectBuilder::Cloner::Base {
  use Moose;

  has 'src', is => 'ro', required => 1, isa => 'Str';
}


package CatalystX::ProjectBuilder::Cloner::FromLocalPath {
  use Moose;
  use File::Copy::Recursive qw/dircopy/;
  extends 'CatalystX::ProjectBuilder::Cloner::Base';

  sub to {
    my ( $self, $dest ) = @_;
    dircopy( $self->src, $dest );
  }
}

package CatalystX::ProjectBuilder::Cloner::FromGit {
  use Moose;
  extends 'CatalystX::ProjectBuilder::Cloner::Base';

  sub to {
    my ( $self, $dest ) = @_;
    system('git', 'clone', $self->src, $dest);
  }
}


1;

