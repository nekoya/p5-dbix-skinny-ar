use lib './t';
use FindBin::libs;
use Test::More tests => 6;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Book;
{
    note 'delete row object';
    my $model = Mock::Book->new;
    my $book1 = $model->find(1);
    ok $book1->delete, 'deleted row object';
    is $model->find(1), undef, 'record deleted';
}
{
    note 'call delete as class method';
    my $model = Mock::Book->new;
    throws_ok { $model->delete } qr/^Delete needs where sentence/;
    isa_ok $model->find(2), 'Mock::Book', 'assert target row';
    ok $model->delete({ id => 2 }), 'call delete as class method by hashref';
    is $model->find(2), undef, 'record deleted';
}
