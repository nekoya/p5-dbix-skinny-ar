use lib './t';
use FindBin::libs;
use Test::More tests => 4;
use Test::Exception;
use Mock::Book;
use Mock::Gender;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

{
    my $book1 = Mock::Book->find({ title => 'book1' });
    ok $book1->title('book4'), 'modified to unique title';
    throws_ok { $book1->title('book2') }
        qr/^Attribute \(title\) does not pass the type constraint because: book2 is not a unique value./,
        'failed set not unique title';
}

{
    my $male = Mock::Gender->find({ name => 'male' });
    ok $male->name('female'), 'modified to allowed name';
    throws_ok { $male->name('man') }
        qr/^Attribute \(name\) does not pass the type constraint/,
        'failed set not allowed name';
}
