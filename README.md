# ctstarter.pl

A smart starter template for Catalyst.

## Why ?

catalyst.pl default generator creates a basic app template. You get a psgi file, Makefile.PL and basic directory structure.

However, real world apps usually needs a bit more: Database, User management, and a JavaScript/CSS framework (or two).

ctstarter.pl aims to provide a true base template for a catalyst web application.

## Catalyzer Templates

catalyzer takes a template and some configuration options, and generates
the starter application for you according to the template.

Each template is a collection of Features, with possible default values
for the features.

We also included a default template that generates a catalyst
application with SQLite database, basic user management, an HTML view
and some TT templates using Twitter Bootstrap.

## Usage

Create an app with a builtin default template:

  catalyzer.pl --appname My::App --template templates/default

  catalyzer.pl --appname My::App --template
https://github.com/ynonp/catalyzer-spa-template.git

## Configuration Format

A template can be customized using a configuration file. The meaning of
the keys in the configuration depends on the template. For example, the
default template takes only a single configuration option: dsn.

You can pass a configuration file using --config-file. Here's a sample
config.json you can use:
 {
   "appname" : "My::Simple::App",
 }

And the full catalyzer command:

  catalyzer.pl --appname My::App --template templates/default
--config-file config.json   

## What You Get From Default Template

## [DBIx::Class Schema](https://metacpan.org/module/DBIx::Class)

Adds a lib/db directory, and inside it initial DBIx::Class Schema and Result-sets for managing users and roles.

	db
	├── Schema
	│   └── Result
	│       ├── Role.pm
	│       ├── User.pm
	│       └── UserRole.pm
	└── Schema.pm


## [DBIx::Class::Migration](https://metacpan.org/module/DBIx::Class::Migration)

DBIx::Class::Migration is a great tool to manage upgrading to the Schema definitions and the DB. 

ctstarter.pl gives you a first migration under share directory, along with a simple ready to use SQLite DB.

A new script is created in script directory called `myapp_upgrade_db.pl`. After adding Result Sets, use this script to upgrade your database.


	share/
	├── db-schema.db
	├── fixtures
	│   └── 1
	│       └── conf
	│           └── all_tables.json
	└── migrations
	    ├── SQLite
	    │   └── deploy
	    │       └── 1
	    │           ├── 001-auto-__VERSION.sql
	    │           └── 001-auto.sql
	    └── _source
	        └── deploy
	            └── 1
	                ├── 001-auto-__VERSION.yml
	                └── 001-auto.yml


## [Catalyst::Helper::View::Bootstrap](https://metacpan.org/module/Catalyst::Helper::View::Bootstrap)

ctstarter.pl uses Bootstrap view helper to create an HTML view, along with a starter set of .tt2 templates.

Twitter bootstrap is assumed to be hosted on the cloud, but you can edit any of the templates generated in `root/src` or `root/lib`.

Here's what you'll get:

	root/
	├── lib
	│   ├── config
	│   │   ├── main
	│   │   └── url
	│   └── site
	│       ├── footer
	│       ├── header
	│       ├── html
	│       ├── layout
	│       ├── sidemenu
	│       └── wrapper
	├── src
	│   ├── error.tt2
	│   ├── login
	│   │   └── login.tt2
	│   ├── message.tt2
	│   ├── ttsite.css
	│   └── welcome.tt2

## [User Management](http://www.catalystframework.org/calendar/2011/15)

Rafael Kitover wrote a great article on how to implement user management in a Catalyst app. ctstarter.pl implements his suggestions into your app. 

Only Blowfish hash is stored in the DB, and authentication is performed automatically using CatalystX::SimpleLogin

ctstarter.pl creates:

1. Result sets for users and roles
2. Initial admin user (username: admin, password: ninja)
3. A new controller `lib/MyApp/Controllers/Members.pm` with a base chain for member protected area (/members)
4. A new script `reset_admin_password.pl` which lets you choose a new admin password.
5. `login/login.tt2` template acting as a login form
6. A simple demo route `/members/hello` that requires login.

To see how everything works, just point your browser to `/members/hello`.

## Building Your Own Templates

A template is basically a list of features, with data files for each
feature. Here's what the default template looks like:

templates/default/
├── features
│   ├── DBIx
│   │   ├── DB.pm
│   │   ├── Schema.pm
│   │   ├── db-schema.db
│   │   └── upgrade_db.pl
│   ├── TwitterBootstrapView
│   │   ├── HTML.pm
│   │   ├── css
│   │   │   ├── bootstrap-theme.css
│   │   │   ├── bootstrap-theme.min.css
│   │   │   ├── bootstrap.css
│   │   │   └── bootstrap.min.css
│   │   ├── fonts
│   │   │   ├── glyphicons-halflings-regular.eot
│   │   │   ├── glyphicons-halflings-regular.svg
│   │   │   ├── glyphicons-halflings-regular.ttf
│   │   │   └── glyphicons-halflings-regular.woff
│   │   ├── include
│   │   │   ├── layout
│   │   │   │   └── simple
│   │   │   └── login
│   │   │       └── login.tt
│   │   └── js
│   │       ├── bootstrap.js
│   │       └── bootstrap.min.js
│   └── UserManagement
│       ├── Members.pm
│       ├── Role.pm
│       ├── User.pm
│       ├── UserRole.pm
│       └── reset_admin_password.pl
└── features.yaml

10 directories, 23 files

Each template needs an index file named features.yaml. Here's the
one from our default template

  - DefaultGenerator
  - TwitterBootstrapView

  - AddPlugins:
    - StackTrace

  - DBIx:
      dsn: dbi:SQLite:dbname=share/db-schema.db
  - UserManagement

As you can see, it lists all the features that will be used in the
template. All features are searched in namespace
`CatalystX::ProjectBuilder::Features`, so for example DefaultGenerator
feature is just a class named
`CatalystX::ProjectBuilder::Features::DefaultGenerator`.

Each feature takes input arguments from two sources: Default arguments
given in features.yaml, and runtime arguments given as a configuration
file to catalyzer.  
In the above features.yaml, the DBIx feature expects to get `dsn`, and
uses a default value `dbi:SQLite:dbname=share/db-schema.db`.

Features also deploy files which are part of the template.

To create a new template do the following:

1. Start with the existing default template
2. Change the features you need
3. Modify default parameters for these features
4. Modify deployment files for these features
5. Write new features as needed

## Adding A New Feature

Catalyzer will automatically load all .pm files under your template's
`features/` folder, as well as any feature specified in the
features.yaml file by namespace.

A feature is just a class that provides 3 functions:

1. process
2. post_process
3. required_keys

You'll also get a lot of functionality by including the 'Feature' role.

#### process function

The process function is called BEFORE the resulted Catalyst app is
loaded. You can use it to create files or modify config files, add
plugins etc. 

#### post_process function

After all feature's `process` functions were called, catalyzer loads the
resulted Catalyst app and starts calling post_process on each feature.  
post_process accepts, in addition to $self, the catalyst app as its
first argument. 

#### required_keys

This method returns a list of configuration keys the feature needs to
run. Catalyzer checks all required keys were passed in before running
the feature.

#### Feature Example

Let's take TwitterBootstrapView feature as an example and see how it is
implemented.

  package CatalystX::ProjectBuilder::Features::TwitterBootstrapView;
  use Moose;
  with 'CatalystX::ProjectBuilder::Feature';
  with 'CatalystX::ProjectBuilder::GenFiles';

  sub required_keys {}


  sub process {
    my ( $self ) = @_;

    $self->gen_dir({ from => ['css'], to => ['root', 'static', 'css'] });
    $self->gen_dir({ from => ['js'], to => ['root', 'static', 'js'] });
    $self->gen_dir({ from => ['fonts'], to => ['root', 'static', 'fonts'] });

    $self->gen_dir({ from => ['include'], to => ['root']});

    my @app_path = split /::/, $self->conf->{appname};
    $self->t_gen_file('HTML.pm', { to => ['lib', @app_path, 'View', 'HTML.pm']});
  }

The class consumes two roles: `Feature` and `GenFiles`. `Feature` provides
empty process() and post_process(), as well as support for input
configurations through $self->conf.

`GenFiles` provides the ability to deploy files from the template dir to
the application dir using gen_file, gen_dir or t_gen_file.

gen_file simply copies the file using File::Copy::Recursive

gen_dir copies a directory using File::Copy::Recursive

t_gen_file uses Template to render the file, providing $self->config as
the stash

