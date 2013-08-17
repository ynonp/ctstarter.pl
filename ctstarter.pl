#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use lib 'lib';
use Template;
use File::Temp;
use Data::Dumper;
use FindBin;

BEGIN { $ENV{CATALYST_DEBUG} = 0 }


#####
# 1. Add controller "members", with:
# sub base : Chained('/login/required') PathPart('/members') CaptureArgs(0) {}
#
# 2. Add model DB 
#
# --- 4. ADd plugins:
#    Authentication
#    Session
#    Session::Store::FastMmap
#    Session::State::Cookie
#   +CatalystX::SimpleLogin
#    Authorization::Roles
#    StackTrace
#
# --- 5. Add DBIx::Class Schema ready to deploy
#
# --- 5.1. Deploy and create a simple SQLite DB
# --- 5.2. Create script: upgrade_db.pl
#
# --- 6. Add ResultSets: User, Role, UserRole
#
# --- 7. Add script: reset_admin_password.pl
#
# --- 8. Create view Bootstrap (and maybe upgrade JS/CSS libs)
#
#############################################
#############################################
#############################################

package Settings {
  use Moose;
  use Config::General;
  use List::MoreUtils qw/any/;

  with 'MooseX::Getopt';

  has 'app_root', is => 'ro', isa => 'Str', default => '.';
  has 'tasks', is => 'ro', isa => 'ArrayRef[Str]', default => sub {
    [qw/scripts plugins view db users/];
  };

  has 'dsn', is => 'ro', isa => 'Str', default => 'dbi:SQLite:dbname=share/db-schema.db';
  has 'plugins', is => 'ro', isa => 'ArrayRef', default => sub {
    [qw/

    -Debug
    ConfigLoader
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Static::Simple

    +CatalystX::SimpleLogin
    Authorization::Roles

    StackTrace

    /]};

  has 'overwrite', is => 'ro', isa => 'Bool', default => 0;  

  has 'data_files', is => 'ro', isa => 'HashRef', lazy_build => 1;
  has 'appname', is => 'ro', isa => 'Str', lazy_build => 1;
  has 'conf_filename', is => 'ro', isa => 'Str', lazy_build => 1;

  sub BUILD {
    my ( $self ) = @_;    
    chdir( $self->app_root );
  }

  sub _build_appname {
    my ( $self ) = @_;

    my $cg = Config::General->new( $self->conf_filename );
    my %cg = $cg->getall;

    return $cg{name}
  }

  sub _build_conf_filename {
    my ( $self ) = @_;
    my @conf = glob("*.conf");

    die "Too many .conf files found. Please specify your app config file"
      if @conf > 1;

    die "No .conf files found. Please specify your app config file"
      if @conf == 0;

    return shift @conf;
  }

  sub appname_lc {
    my ( $self ) = @_;
    my $result = lc( $self->appname );
    $result =~ s/::/_/;
    return $result;
  }

  sub scripts_prefix {
    my ( $self ) = @_;

    return $self->appname_lc . "_";
  }

  sub app_filename {
    my ( $self ) = @_;
    my $app = $self->appname;
    my $rel_path = $self->appname =~ s/::/\//gr . ".pm";

    return $app->path_to( 'lib', $rel_path );
  }

  sub component_filename {
    my ( $self, $type, $name ) = @_;

    my $app = $self->appname;
    my $rel_path = $self->appname =~ s/::/\//gr;
    return $app->path_to( 'lib', $rel_path, $type, "${name}.pm");
  }

  sub model_filename {
    my ( $self, $model ) = @_;
    return $self->component_filename('Model', $model);
  }

  sub controller_filename {
    my ( $self, $controller ) = @_;
    return $self->component_filename('Controller', $controller );  
  }

  sub task {
    my ( $self, $task_name ) = @_;
    return any { $_ eq $task_name } @{ $self->tasks };
  }

  sub writer_opts {
    my ( $self ) = @_;

    return {
      no_clobber => ! $self->overwrite, 
      err_mode   => 'carp'
    }
  }

  sub _build_data_files {
    my ( $self ) = @_;

    my $data_files = {};
    my $current_key;

    my $KEY_LINE = qr{^\s*@([\w./]+)\s*$};

    while(<::DATA>) {
      if ( my ($key) = /$KEY_LINE/ ) {
        $current_key = $key;
        next;
      }
      elsif ( $current_key ) {
        $data_files->{$current_key} .= $_;
      }
    }

    my $template = Template->new;
    while ( my ( $fname, $content) = each $data_files ) {
      my $result;
      $template->process( \$content, $self, \$result );
      $data_files->{$fname} = $result;
    }
    return $data_files;
  }
}

#############################################
#############################################
#############################################
package Scripts {
  use Moose;
  use autodie;
  use File::Slurp qw/write_file read_file/;

  has 'cnf', is => 'ro', isa => 'Settings', required => 1;

  sub filename {
    my ( $self, $name ) = @_;
    my $app = $self->cnf->appname;
    my $scripts_fullpath = $app->path_to('script');

    $scripts_fullpath . "/" . $self->cnf->scripts_prefix . $name;
  }

  sub gen_script {
    my ( $self, $filename, $key ) = @_;
    $key ||= $filename;

    write_file( $self->filename($filename), $self->cnf->writer_opts, $self->cnf->data_files->{$key} );    
  }

  sub gen_reset_admin_password {
    my ( $self ) = @_;
    $self->gen_script('reset_admin_password.pl');
  }

  sub gen_upgrade_db {
    my ( $self ) = @_;
    $self->gen_script('upgrade_db.pl');
  }
}

#############################################
#############################################
#############################################

package CatalystAppFile {
  use Moose;
  use File::Slurp;

  has 'cnf', is => 'ro', isa => 'Settings', required => 1;

  sub modify_plugins {
    my ( $self ) = @_;
    my $content = read_file( $self->cnf->app_filename );
    my $plugins_line = join("\n    ", @{ $self->cnf->plugins });
    $content =~ s{
      use \s+ Catalyst \s+ qw/[\s\w:+-]+/;
    }{use Catalyst qw/
    $plugins_line
/;}xms;

    write_file( $self->cnf->app_filename, $content );
  }

  sub add_plugins_to_makefile {
    my ( $self ) = @_;

    my $content = read_file( 'Makefile.PL' );
    my $MARKER = qr {test_requires 'Test::More' => '[\d.]+';};
    my @plugins = grep !/^-/, @{ $self->cnf->plugins };

    my $plugins = join("\n", map {
      !/^\+/ ? "requires \'Catalyst::Plugin::$_\';" :
               "requires \'" . substr($_, 1) . "\';"
    } @plugins);

    $content =~ s/($MARKER)/${plugins}\n\n${1}/;
    write_file( 'Makefile.PL', $content );
  }


  sub append_config {
    my ( $self ) = @_;

    my $content = read_file $self->cnf->conf_filename;
    if ( $content =~ /gen\.pl START/ ) {
      warn 'Config info already in conf file. Skipping...';
      return;
    }

    write_file( $self->cnf->conf_filename, { append => 1}, $self->cnf->data_files->{conf});
  }
}

#############################################
#############################################
#############################################

package DBxGen {
  use Moose;
  use File::Path qw/make_path/;
  use File::Slurp qw/read_file write_file/;

  has 'cnf', is => 'ro', isa => 'Settings', required => 1;

  sub prepare_path {
    my ( $self, @path ) = @_;
    my $app = $self->cnf->appname;

    my $path = $app->path_to(@path)->stringify;
    make_path($path);
    return $path;
  }

  sub gen_schema {
    my ( $self ) = @_;
    my $path = $self->prepare_path( 'lib', 'db' );
    write_file( "$path/Schema.pm", $self->cnf->writer_opts, $self->cnf->data_files->{'schema.pm'});
  }

  sub gen_resultsets {
    my ( $self ) = @_;
    my $path = $self->prepare_path('lib', 'db', 'Schema', 'Result');

    write_file( "$path/User.pm", $self->cnf->writer_opts, $self->cnf->data_files->{'user.pm'});
    write_file( "$path/Role.pm", $self->cnf->writer_opts, $self->cnf->data_files->{'role.pm'});    
    write_file( "$path/UserRole.pm", $self->cnf->writer_opts, $self->cnf->data_files->{'userrole.pm'});        
  }

  sub gen_dbmodel {
    my ( $self ) = @_;
    my $path = $self->cnf->model_filename('DB');
    write_file( $path, $self->cnf->writer_opts, $self->cnf->data_files->{'db.pm'});
  }

  sub deploy_initial_db {
    my ( $self ) = @_;
    my $dsn = $self->cnf->dsn;
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

#############################################
#############################################
#############################################

package Authen {
  use Moose;
  use File::Slurp qw/write_file read_file/;

  has 'cnf', is => 'ro', isa => 'Settings', required => 1;

  sub gen_members_controller {
    my ( $self ) = @_;    
    my $fname = $self->cnf->controller_filename( 'Members' );

    write_file( $fname, $self->cnf->writer_opts, $self->cnf->data_files->{'controller/members.pm'} );
  }

  sub gen_login_tt {
    my ( $self ) = @_;
    my $app = $self->cnf->appname;
    my $path = $app->path_to('root', 'src', 'login', 'login.tt2');
    $path->dir->mkpath;

    write_file( $path->stringify, 
                $self->cnf->writer_opts, 
                $self->cnf->data_files->{'tt/login'});
  }


  sub fill_db {
    my ( $self ) = @_;
    my $app = $self->cnf->appname;
    warn 'loading: ', $self->cnf->model_filename('DB') ;
    require( $self->cnf->model_filename('DB') );

    my $user = $app->model('DB::User');
    $user->create({
      username => 'admin',
      active => 'Y',
      name => 'Administrator',
      email_address => 'admin@myapp.com',
      password => 'ninja',
    });

    my $admin_role = $app->model('DB::Role')->create({
      name => 'admin',
    });

    $app->model('DB::Role')->create({
      name => 'user',
    });

    $user->find({ username => 'admin'})->add_to_roles( $admin_role );    
  }
}

#############################################
#############################################
#############################################

my $SETTINGS = Settings->new_with_options();
my $pm_name = $SETTINGS->appname =~ s/::/\//r . ".pm";
require $pm_name;

my $app = $SETTINGS->appname;

#########################
# Add plugins
#
my $new_conf = 0;

if ( $SETTINGS->task( 'plugins' ) ) {
  my $mainfile = CatalystAppFile->new( cnf => $SETTINGS );
  $new_conf = $mainfile->append_config;

  $mainfile->modify_plugins;
  $mainfile->add_plugins_to_makefile;
}


##########################
# Generate Script reset_admin_password.pl

my $scripts = Scripts->new( cnf => $SETTINGS );
if ( $SETTINGS->task('scripts') ) {
  $scripts->gen_reset_admin_password;
  $scripts->gen_upgrade_db;
}

##########################
# Generate Bootstrap View

if ( $SETTINGS->task('view') ) {
  system( $scripts->filename("create.pl"),
    "view", "HTML", "Bootstrap");
}


############################
# Create initial schema
#

if ( $SETTINGS->task('db' ) ) {
  my $dbgen = DBxGen->new( cnf => $SETTINGS );
  $dbgen->gen_schema;
  $dbgen->gen_resultsets;
  $dbgen->gen_dbmodel;
  $dbgen->deploy_initial_db;
}

################################
# Prepare users and roles

if ( $SETTINGS->task('users') ) {
  my $auth = Authen->new( cnf => $SETTINGS );
  $auth->gen_members_controller;

  if ( $new_conf ) {
    exec("perl", "${FindBin::Bin}/${FindBin::Script}", @ARGV);
    exit 0;
  }

  $auth->fill_db;
  $auth->gen_login_tt;
}


print "--- gen.pl END OK\n";


###################################################
###################################################
###                                             ###
###  CODE ENDS  HERE                            ###
###                                             ###
###################################################
###################################################


__END__

@reset_admin_password.pl
#!/usr/bin/env perl

# \[\% test \%\]

use strict;
use warnings;
use lib 'lib';

BEGIN { $ENV{CATALYST_DEBUG} = 0 }

use [% appname %];
use DateTime;

my $password = shift || 'admin';

my $admin = [% appname %]->model('DB::User')->find_or_create({
  username => 'admin',
  active => 'Y',
  name => 'Administrator',
  email_address => 'admin@home.com',
  password => '',
});

$admin->update({ password => $password, password_expires => DateTime->now });

@schema.pm
use utf8;
package db::Schema;

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

our $VERSION = 1;

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;

@user.pm
use utf8;
package db::Schema::Result::User;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "active",
  { data_type => "char", is_nullable => 0, size => 1 },
  "username",
  { data_type => "text", is_nullable => 0 },
  "password",
  { data_type => "text", is_nullable => 0 },
  "password_expires",
  { data_type => "timestamp", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "email_address",
  { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

__PACKAGE__->has_many(
  "user_roles",
  "db::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many("roles", "user_roles", "role");

__PACKAGE__->add_columns(
    '+password' => {
        passphrase       => 'rfc2307',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 14,
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    }
);

__PACKAGE__->meta->make_immutable;
1;

@role.pm
use utf8;
package db::Schema::Result::Role;
use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

__PACKAGE__->table("roles");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

__PACKAGE__->has_many(
  "user_roles",
  "db::Schema::Result::UserRole",
  { "foreign.role_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->many_to_many("users", "user_roles", "user");

__PACKAGE__->meta->make_immutable;
1;

@userrole.pm
use utf8;
package db::Schema::Result::UserRole;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

__PACKAGE__->table("user_roles");

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("user_id", "role_id");

__PACKAGE__->belongs_to(
  "role",
  "db::Schema::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->belongs_to(
  "user",
  "db::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

__PACKAGE__->meta->make_immutable;

1;

@db.pm
package [% appname %]::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'db::Schema',
);

1;
@conf
#gen.pl START
<Model::DB>
    schema_class db::Schema
    traits Caching
    <connect_info>
        dsn [% dsn %]
    </connect_info>
</Model::DB>

<Plugin::Authentication>
  <realms default>
    <credential>
      class =         Password
      password_field  password
      password_type   self_check
    </credential>
    <store>
      class           DBIx::Class
      user_model      DB::User
      role_relation   roles
      role_field      name
    </store>
  </realms>
</Plugin>

<Controller::Login>
  traits = [-RenderAsTTTemplate]
  <login_form_args authenticate_args>
    active = Y
  </login_form_args>
</Controller>

<View::HTML>
  TEMPLATE_EXTENSION .tt2
</View>

@upgrade_db.pl
use strict;
use warnings;
use v5.16;
use lib 'lib';
use DBIx::Class::Migration;

BEGIN { $ENV{CATALYST_DEBUG} = 0 }

use [% appname %];

my $schema = [% appname %]->model('DB')->schema;
my $migration = DBIx::Class::Migration->new(
  schema => $schema,
);

$migration->prepare();
$migration->upgrade();

@controller/members.pm
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

@tt/login
[% TAGS [- -] %]

[% META title = 'Welcome to MyApp: Please Log In' %]
<div>
  [% FOR field IN login_form.error_fields %]
  [% FOR error IN field.errors %]
  <p><span style="color: red;">[% field.label _ ': ' _ error %]</span></p>
  [% END %]
  [% END %]
</div>

<div>
  <form id="login_form" method="post" action="[% c.req.uri %]">
    <fieldset style="border: 0;">
      <table>
        <tr>
          <td><label class="label" for="username">Username:</label></td>
          <td><input type="text" name="username" value="" id="username" /></td>
        </tr>
        <tr>
          <td><label class="label" for="password">Password:</label></td>
          <td><input type="password" name="password" value="" id="password" /></td>
        </tr>
        <tr><td><input type="submit" name="submit" value="Login" /></td></tr>
      </table>
    </fieldset>
  </form>
</div>
