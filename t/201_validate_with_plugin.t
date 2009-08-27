use t::Utils;
use Mock::Language;
use Test::Declare;
use Data::Dumper;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
        Mock::Basic->insert('languages',{
            id   => 1,
            name => 'perl',
            kana => 'パール',
        });
        Mock::Basic->insert('languages',{
            id   => 2,
            name => 'python',
            kana => 'パイソン',
        });
    };

    test 'katakana' => run {
        my $perl = Mock::Language->find(1);
        my $result = $perl->validate({ kana => 'perl' });
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'kana' ], 'validation error happened in kana';
        is_deeply [ $result->error('kana') ], [ 'KATAKANA' ], 'error is KATAKANA';
    };

    test 'dbic_unique' => run {
        my $perl = Mock::Language->find(1);
        my $result = $perl->validate({ name => 'python' });
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'DBIC_UNIQUE' ], 'error is DBIC_UNIQUE';
    };

    cleanup {
        unlink './t/main.db';
    };
};

