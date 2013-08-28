use strict;
use warnings;

package CatalystX::ProjectBuilder::GenFiles;
use Moose::Role;
use Template;
use Path::Class::File;
use Path::Class::Dir;
use File::Copy::Recursive qw/fcopy dircopy/;

requires 'data_dir';
requires 'base_dir';
requires 'conf';

sub _prepare_genfile_args {
  my ( $self, $from, $opts ) = @_;

  if ( ref($from) && ! defined( $opts ) ) {
    # Got only one parameter, which is a hash ref
    # So try to extract "from" from it
    $opts = $from;
    $from = $opts->{from} or die 'Missing argument: "from"';
  }

  my $to   = $opts->{to}   or die 'Missing argument: "to"';

  my $src_f = Path::Class::File->new( $self->data_dir, ref($from) ? @$from : $from );
  my $dst_f = Path::Class::File->new( $self->base_dir, ref($to) ? @$to : $to );

  die "Missing File: $src_f" if ! -f "$src_f";

  return ( $src_f, $dst_f );
}


sub gen_dir {
  my ( $self, $from, $opts ) = @_;

  if ( ref($from) && ! defined( $opts ) ) {
    # Got only one parameter, which is a hash ref
    # So try to extract "from" from it
    $opts = $from;
    $from = $opts->{from} or die 'Missing argument: "from"';
  }

  my $to   = $opts->{to}   or die 'Missing argument: "to"';

  my $src_d = Path::Class::Dir->new( $self->data_dir, ref($from) ? @$from : $from );
  my $dst_d = Path::Class::Dir->new( $self->base_dir, ref($to) ? @$to : $to );

  dircopy( "$src_d", "$dst_d" );
}


sub gen_file {
  my $self = shift;
  my ( $src_f, $dst_f ) = $self->_prepare_genfile_args(@_);

  die "Missing File: $src_f" if ! -f "$src_f";

  fcopy( "$src_f", "$dst_f" );
}

sub t_gen_file {
  my $self = shift;
  my ( $src_f, $dst_f ) = $self->_prepare_genfile_args(@_);

  $dst_f->dir->mkpath;

  my $tt = Template->new({ ABSOLUTE => 1 });

  $tt->process( "$src_f", $self->conf, "$dst_f" ) or die $tt->error;
}



1;
