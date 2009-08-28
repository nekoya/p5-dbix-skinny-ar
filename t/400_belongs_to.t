use t::Utils;
use Mock::Member;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'basic' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        is $taro->gender_id, 1, 'assert gender_id';
        ok my $gen = $taro->gender, 'get related record';
        isa_ok $gen, 'Mock::Gender';
        is $gen->name, 'male', 'assert gender name';
    };

    test 'args key' => run {
        my $hanako = Mock::Member->find({ name => 'hanako' });
        is $hanako->pref_id, 1, 'assert pref_id';
        ok my $pref = $hanako->prefecture, 'get related record';
        isa_ok $pref, 'Mock::Prefecture';
        is $pref->name, 'tokyo', 'assert prefecture name';
    };

    test 'args key/class' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        is $taro->gender_id, 1, 'assert gender_id';
        ok my $gen = $taro->gen, 'get related record';
        isa_ok $gen, 'Mock::Gender';
        is $gen->name, 'male', 'assert gender name';
    };

    test 'related row was not found' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        $taro->gender_id('');
        is $taro->gender, undef, 'return undef when foreign_key is null';

        $taro->gender_id(3);
        throws_ok { $taro->gender } qr/^related row was not found/, 'threw exception if related row was not found';
    };

    cleanup {
        unlink './t/main.db';
    };
};

