use t::Utils;
use Mock::Member;
use Test::Declare;
use Data::Dumper;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'katakana' => run {
        my $taro = Mock::Member->find(1);
        my $result = $taro->validate({ kana => 'taro' });
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'kana' ], 'validation error happened in kana';
        is_deeply [ $result->error('kana') ], [ 'KATAKANA' ], 'error is KATAKANA';
    };

    test 'dbic_unique' => run {
        my $perl = Mock::Member->find(1);
        my $result = $perl->validate({ name => 'hanako' });
        ok $result->has_error, 'validation failed';
        is_deeply [ $result->error ], [ 'name' ], 'validation error happened in name';
        is_deeply [ $result->error('name') ], [ 'DBIC_UNIQUE' ], 'error is DBIC_UNIQUE';
    };

    cleanup {
        unlink './t/main.db';
    };
};

