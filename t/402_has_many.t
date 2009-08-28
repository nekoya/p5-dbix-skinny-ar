use t::Utils;
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
        my $tokyo = Mock::Prefecture->find({ name => 'tokyo' });
        ok my $members = $tokyo->members, 'get related rows';
        is scalar @$members, 2, 'amount of rows';
        is $members->[0]->name, 'taro', 'first row name';
        is $members->[1]->name, 'hanako', 'second row name';
    };

    cleanup {
        unlink './t/main.db';
    };
};

