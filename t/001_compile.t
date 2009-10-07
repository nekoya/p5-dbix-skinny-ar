use lib './t';
use FindBin::libs;
use Test::More tests => 1;

use Mock::SQLite;

BEGIN { use_ok( 'Mock::Book' ); }
