use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Mock::Language;
use Mock::Gender;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

{
    note 'call count as class method';
    is(Mock::Language->count({ name => 'php' }), 0, 'no amount of count');
    is(Mock::Language->count, 3, 'count all');
    is(Mock::Language->count({ name => 'perl' }), 1, 'count by name');
}

{
    note 'call count as instance method';
    my $model = Mock::Language->new;
    is($model->count({ name => 'php' }), 0, 'no amount of count');
    is($model->count, 3, 'count all');
    is($model->count({ name => 'perl' }), 1, 'count by name');
}

{
    note 'call count as instance method with pk not id';
    my $model = Mock::Gender->new;
    is($model->count({ name => 'man' }), 0, 'no amount of count');
    is($model->count, 2, 'count all');
    is($model->count({ name => 'male' }), 1, 'count by name');
}
