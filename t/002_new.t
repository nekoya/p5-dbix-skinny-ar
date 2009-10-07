use lib './t';
use FindBin::libs;
use Test::More tests => 1;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
{
    my $model = Mock::Book->new;
    isa_ok $model, 'Mock::Book';
}
