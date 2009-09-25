use lib './t';
use FindBin::libs;
use Test::More tests => 9;
use Mock::Book;
use Mock::Gender;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call count as class method';
    is(Mock::Book->count({ title => 'book0' }), 0, 'no amount of count');
    is(Mock::Book->count, 3, 'count all');
    is(Mock::Book->count({ title => 'book1' }), 1, 'count by title');
}

{
    note 'call count as instance method';
    my $model = Mock::Book->new;
    is($model->count({ title => 'book0' }), 0, 'no amount of count');
    is($model->count, 3, 'count all');
    is($model->count({ title => 'book1' }), 1, 'count by title');
}

{
    note 'call count as instance method (custom pk)';
    my $model = Mock::Gender->new;
    is($model->count({ name => 'man' }), 0, 'no amount of count');
    is($model->count, 2, 'count all');
    is($model->count({ name => 'male' }), 1, 'count by name');
}
