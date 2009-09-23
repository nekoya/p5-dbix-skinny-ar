use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Mock::Language;
use Mock::Gender;

BEGIN { Mock::Basic->setup_test_db }
END   { unlink './t/main.db' }

my $model = Mock::Language->new;
{
    note 'delete row object';
    my $perl = $model->find(1);
    ok $perl->delete, 'deleted row object';
    is $model->find(1), undef, 'record deleted';
}

{
    note 'call delete as class method';
    throws_ok { $model->delete } qr/^Delete needs where sentence/;
    isa_ok $model->find(2), 'Mock::Language', 'assert target row';
    ok $model->delete({ id => 2 }), 'call delete as class method by hashref';
    is $model->find(2), undef, 'record deleted';
};
