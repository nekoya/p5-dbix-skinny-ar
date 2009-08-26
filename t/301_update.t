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
    };

    test 'create' => run {
        is 1, 1, 'dummy';
    };

    cleanup {
        unlink './t/main.db';
    };
};

