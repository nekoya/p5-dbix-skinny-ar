BEGIN { $ENV{'ANY_MOOSE'} = 'Moose' }
use lib './t';
use FindBin::libs;
use Test::More 'no_plan';
use Test::Exception;
use Mock::Book;
use Mock::Pseudonym;

BEGIN { Mock::DB->setup_test_db }
END   { unlink './t/main.db' }

{
    note "with option";
    my $book1 = Mock::Book->find({ title => 'book1' });
    is $book1->author_id, 1, 'assert author_id';
    ok my $author = $book1->whose, 'get related record';
    isa_ok $author, 'Mock::Author';
    is $author->name, 'mike', 'assert author name';
}

{
    note "auto settings";
    my $john = Mock::Pseudonym->find({ name => 'John' });
    isa_ok $john, 'Mock::Pseudonym';
    throws_ok { $john->author_id }
        qr/Can't locate object method "author_id"/,
        'author_id is not implemented at Mock::Pseudonym';
    ok my $author = $john->author, 'get related record';
    isa_ok $author, 'Mock::Author';
    is $author->name, 'mike', 'assert author name';

    note "auto detect custom pk (not 'id')";
    ok my $gender = $author->gender, 'get related record';
    isa_ok $gender, 'Mock::Gender';
    is $gender->name, 'male', 'assert name';
}

{
    note "related record not found";
    my $book1 = Mock::Book->find({ title => 'book1' });
    ok $book1->author_id(99), 'set invalid author_id (no error arose)';
    is $book1->author_id, 99, 'assert author_id';
    throws_ok { $book1->whose }
        qr/^related row was not found/,
        'related row was not found';
}
