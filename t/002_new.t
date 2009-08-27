use t::Utils;
use Mock::Language;
use Test::Declare;

plan tests => blocks;

describe 'instance object test' => run {
    test 'setup' => run {
        is(Mock::Language->db, 'Mock::Basic', 'assert db name');
        is(Mock::Language->table, 'languages', 'assert table name');
        my $validator = Mock::Language->validator;
        is $validator->{ module }, 'FormValidator::Simple', 'assert validator module';
        is_deeply $validator->{ plugins }, [qw(
        FormValidator::Simple::Plugin::DBIC::Unique
        FormValidator::Simple::Plugin::Japanese
        )], 'assert validator plugins';
    };
};
