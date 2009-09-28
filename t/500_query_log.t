use lib './t';
use FindBin::libs;
use Test::More tests => 1;
use Test::Exception;
use Mock::DB;

BEGIN { Mock::DB->setup_test_db }

use Mock::Author;
{
    Mock::DB->debug(1);
    Mock::Author->find(1);
    my $log = Mock::DB->query_log;
    is_deeply $log, [ "SELECT id, gender_name, name FROM authors WHERE (id = ?) LIMIT 1 :binds 1" ], 'query_log';
};
