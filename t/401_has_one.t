use lib './t';
use FindBin::libs;
use Test::More tests => 9;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Gender;
use Mock::Prefecture;
{
    note "has_one default settings";
    my $author = Mock::Author->find(1);
    ok my $book = $author->book, 'get related object';
    isa_ok $book, 'Mock::Book';
    is $book->id, 1, 'assert book id';
}
{
    note "has no records";
    my $author = Mock::Author->find(3);
    is $author->book, undef, 'return undef when record not found';
}
{
    note "auto detect not id PK";
    my $gender = Mock::Gender->find('female');
    ok my $author = $gender->author, 'get related object';
    isa_ok $author, 'Mock::Author';
    is $author->name, 'Lisa', 'assert name';
}
{
    note "belongs_to options (foreign key is not PK)";
    my $pref = Mock::Prefecture->find(2);
    ok my $town = $pref->town, 'get related object';
    is $town->name, 'Mitaka', 'assert name';
}

