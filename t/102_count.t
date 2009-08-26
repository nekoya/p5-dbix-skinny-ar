use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('languages',{
            id   => 1,
            name => 'perl',
        });
        Mock::Basic->insert('languages',{
            id   => 2,
            name => 'python',
        });
    };

    test 'count' => run {
        is(Mock::Language->count({ name => 'ruby' }), 0, 'no amount of count');
        is(Mock::Language->count, 2, 'count all');
        is(Mock::Language->count({ name => 'perl' }), 1, 'count by name');
    };

    cleanup {
        unlink './t/main.db';
    };
};

