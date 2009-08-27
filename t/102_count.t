use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'count' => run {
        is(Mock::Language->count({ name => 'php' }), 0, 'no amount of count');
        is(Mock::Language->count, 3, 'count all');
        is(Mock::Language->count({ name => 'perl' }), 1, 'count by name');
    };

    cleanup {
        unlink './t/main.db';
    };
};

