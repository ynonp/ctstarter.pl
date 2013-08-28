use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use CatalystX::ProjectBuilder::App::Catalyzer;
use CatalystX::ProjectBuilder;

my $catalyzer = CatalystX::ProjectBuilder::App::Catalyzer->new_with_options();
$catalyzer->run;

