# ctstarter.pl

A smart starter template for Catalyst.

## Why ?

catalyst.pl default generator creates a basic app template. You get a psgi file, Makefile.PL and basic directory structure.

However, real world apps usually needs a bit more: Database, User management, and a JavaScript/CSS framework (or two).

ctstarter.pl aims to provide a true base template for a catalyst web application.

## Usage

	catalyst.pl MyApp
	cd MyApp
	perl Makefile.PL
	
	ctstarter.pl
	
After creating the initial directories with catalyst.pl, you can just run ctstarter.pl from a catalyst root directory.

## What You Get

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

## More Awsomeness

ctstarter.pl supports command line options to run only the features you need. 

	ctstarter.pl --tasks=view

Supported values:

- `scripts` creates the new scripts (reset_admin_password.pl and upgrade_db.pl).  
- `plugins` adds a bunch of useful plugins to your application main file and to the Makefile.PL requires section.
- `view` creates the HTML view and bootstrap view templates
- `db` creates the database migrations
- `users` creates the DB tables and templates for users and roles

See:
	
	ctstarter.pl -h
	
For other command line options.

## What Next

ctstarter.pl is meant to help users new to catalyst get an easier head start. If you find any issues or feature requests, please report here on github.
