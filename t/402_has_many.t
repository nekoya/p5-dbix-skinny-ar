use lib './t';
use FindBin::libs;
use Test::More tests => 14;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db'  }

use Mock::Gender;
use Mock::Prefecture;
{
    note "has_many default settings";
    my $author = Mock::Author->find(1);
    ok my $books = $author->books, 'get related objects';
    is scalar @$books, 2, 'amount of rows';
    isa_ok $books->[0], 'Mock::Book';
    isa_ok $books->[1], 'Mock::Book';
    is $books->[0]->id, 1, 'assert book id';
    is $books->[1]->id, 3, 'assert book id';
}
{
    note "has no records";
    my $author = Mock::Author->find(3);
    is_deeply $author->books, [], 'return empty arrayref when record not found';
}
{
    note "auto detect not id PK";
    my $gender = Mock::Gender->find('female');
    ok my $authors = $gender->authors, 'get related objects';
    is scalar @$authors, 1, 'amount of rows';
    isa_ok $authors->[0], 'Mock::Author';
    is $authors->[0]->name, 'Lisa', 'assert name';
}
{
    note "belongs_to options (foreign key is not PK)";
    my $pref = Mock::Prefecture->find(2);
    ok my $towns = $pref->towns, 'get related objects';
    is scalar @$towns, 1, 'amount of rows';
    is $towns->[0]->name, 'Mitaka', 'assert name';
}
