use t::Utils;
use Mock::Member;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    init {
        Mock::Basic->setup_test_db;
    };

    test 'no record' => run {
        my $taro = Mock::Member->find({ name => 'taro' });
        is $taro->namecard, undef, 'return undef if related record was not found';
    };

    test 'exists' => run {
        my $hanako = Mock::Member->find({ name => 'hanako' });
        ok my $card = $hanako->namecard, 'get related namecard';
        isa_ok $card, 'Mock::Namecard';
        is $card->member_id, $hanako->id, 'assert foreign_key';
    };

    test 'custom key/class' => run {
        my $hanako = Mock::Member->find({ name => 'hanako' });
        ok my $card = $hanako->nc, 'get related namecard';
        isa_ok $card, 'Mock::Namecard';
        is $card->member_id, $hanako->id, 'assert foreign_key';
    };

    cleanup {
        unlink './t/main.db';
    };
};

