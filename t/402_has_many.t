use t::Utils;
use Mock::Gender;
use Mock::Prefecture;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'no record' => run {
        my $kyoto = Mock::Prefecture->find({ name => 'kyoto' });
        is_deeply $kyoto->members, [], 'return empty arrayref if no records';
    };

    test 'basic' => run {
        my $male = Mock::Gender->find({ name => 'male' });
        ok my $members = $male->members, 'got related rows';
        is scalar @$members, 1, 'amount of rows';
        is $members->[0]->name, 'taro', 'first row name';
    };

    test 'key/class params' => run {
        my $tokyo = Mock::Prefecture->find({ name => 'tokyo' });
        ok my $members = $tokyo->members, 'got related rows';
        is scalar @$members, 2, 'amount of rows';
        is $members->[0]->name, 'taro', 'first row name';
        is $members->[1]->name, 'hanako', 'second row name';
    };

    test 'additional where conds' => run {
        my $tokyo = Mock::Prefecture->find({ name => 'tokyo' });
        ok my $members = $tokyo->members({ name => 'hanako' }), 'got related rows with where conds';
        is scalar @$members, 1, 'amount of rows';
        is $members->[0]->name, 'hanako', 'first row name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

