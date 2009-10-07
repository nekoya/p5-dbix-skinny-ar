package Mock::DB;
use DBIx::Skinny setup => +{
    dsn => 'dbi:SQLite:test.db',
    username => '',
    password => '',
};

sub debug {
    my ($class, $debug) = @_;
    $class->attribute->{ profile } = $debug;
}

sub query_log {
    my $class = shift;
    $class->profiler->query_log(@_);
}

package Mock::DB::Schema;
use base qw/DBIx::Skinny::Schema::Loader/;

__PACKAGE__->load_schema;

1;
