use lib './t';
use FindBin::libs;
use Test::More tests => 5;
use Test::Exception;

use Mock::SQLite;
use Mock::Book;
use Mock::Gender;
{
    is(Mock::Book->count, 3, 'count all');
}
{
    is(Mock::Book->count(1), 1, 'count by PK');
}
{
    is(Mock::Book->count({ title => 'book1' }), 1, 'count by hashref');
}
{
    is(Mock::Book->count({ title => 'book0' }), 0, 'no amount of count');
}
{
    my $model = Mock::Book->new;
    is $model->count, 3, 'call count as instance method';
}
