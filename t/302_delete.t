use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'delete by row object' => run {
        my $perl = Mock::Language->find(1);
        ok $perl->delete, 'deleted row object';
        is(Mock::Language->find(1), undef, 'record deleted');
    };

    test 'delete by class method' => run {
        throws_ok { Mock::Language->delete } qr/^delete needs where sentence/;
        ok(Mock::Language->delete({ id => 2 }), 'call delete as class method by hashref');
        is(Mock::Language->find(2), undef, 'record deleted');
    };

    cleanup {
        unlink './t/main.db';
    };
};

