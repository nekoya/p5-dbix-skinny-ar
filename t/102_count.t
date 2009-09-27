use lib './t';
use FindBin::libs;
use Mock::Basic;

BEGIN { Mock::Basic->setup_db }
END   { unlink './t/main.db'  }

use Test::More tests => 6;

{
    note 'call count as class method';
    is(Mock::Book->count({ title => 'book0' }), 0, 'no amount of count');
    is(Mock::Book->count, 4, 'count all');
    is(Mock::Book->count({ title => 'book1' }), 1, 'count by title');
}

{
    note 'call count as instance method, and custom PK';
    my $model = Mock::Author->new;
    is($model->count({ name => 'Kate' }), 0, 'no amount of count');
    is($model->count, 3, 'count all');
    is($model->count({ name => 'John' }), 1, 'count by name');
}
