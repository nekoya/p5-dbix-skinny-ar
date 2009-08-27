use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'create' => run {
        is 1, 1, 'dummy';
    };

    cleanup {
        unlink './t/main.db';
    };
};

