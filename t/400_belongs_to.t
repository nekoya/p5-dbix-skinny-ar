use t::Utils;
use Mock::Member;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'args(method)' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        is $taro->gender_id, 1, 'assert gender_id';
        ok my $gen = $taro->gender, 'get related record';
        isa_ok $gen, 'Mock::Gender';
        is $gen->name, 'male', 'assert gender name';
    };

    test 'args(method => column)' => run {
        my $hanako = Mock::Member->find({ name => 'hanako' });
        is $hanako->gender_id, 2, 'assert gender_id';
        ok my $pref = $hanako->prefecture, 'get related record';
        isa_ok $pref, 'Mock::Prefecture';
        is $pref->name, 'tokyo', 'assert prefecture name';
    };

    test 'args(method => column, target_class)' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        is $taro->gender_id, 1, 'assert gender_id';
        ok my $gen = $taro->gen, 'get related record';
        isa_ok $gen, 'Mock::Gender';
        is $gen->name, 'male', 'assert gender name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

