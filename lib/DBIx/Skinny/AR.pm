package DBIx::Skinny::AR;

our $VERSION = '0.0.1';

use Carp;
use UNIVERSAL::require;
use Lingua::EN::Inflect::Number qw/to_S to_PL/;

use Mouse;
extends 'Mouse::Object', 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('db');
__PACKAGE__->mk_classdata('validator' => {
    module  => 'FormValidator::Simple',
    plugins => [],
});

has 'row' => (
    is  => 'rw',
    isa => 'DBIx::Skinny::Row',
);

no Mouse;

sub table { croak 'implement table name' }
sub validation { croak 'implement validation rules' }
sub default_search_column { 'id' }

sub debug {
    my ($class, $debug) = @_;
    $class->db->attribute->{ profile } = $debug;
}

sub query_log {
    my $class = shift;
    $class->db->profiler->query_log(@_);
}

sub setup {
    my ($class, $args) = @_;

    croak "implement db name" unless $args->{ db };
    $args->{ db }->require or croak "failed to load " . $args->{ db };
    $class->db($args->{ db });

    my $validator = $args->{ validator };
    $validator->{ module } ||= $class->validator->{ module };
    $validator->{ module }->require;

    for my $plugin ( @{ $validator->{ plugins } } ) {
        $validator->{ module }->load_plugin($plugin);
    }
    $class->validator($validator);
}

sub mk_accessors {
    my ($class) = @_;
    my $cols = $class->db->schema->schema_info->{ $class->table }->{ columns };
    for my $col ( @$cols ) {
        next if $class->can($col);
        no strict 'refs';
        *{"$class\::$col"} = sub {
            my ($self, $val) = @_;
            return $self->row->$col unless defined $val;
            $self->row->set({ $col => $val });
        };
    }
}

sub get_where {
    my ($class, $where) = @_;
    return $where if ref $where eq 'HASH';
    return {} unless defined $where;
    return { $class->default_search_column => $where };
}

sub find {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    $where = $class->get_where($where);
    my $row = $class->db->single($class->table, $where, $opt) or return;
    if ( ref $self ) {
        $self->row($row);
        return $self;
    }
    return $class->new({ row => $row });
}

sub find_all {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    $where = $class->get_where($where);
    my $rs = $class->db->search($class->table, $where, $opt);
    my @rows;
    while ( my $row = $rs->next ) {
        push @rows, $class->new({ row => $row });
    }
    return \@rows;
}

sub count {
    my ($class, $args) = @_;
    $class->db->count($class->table, 'id', $args);
}

sub validate {
    my ($self, $_args) = @_;
    my $class = ref $self || $self;
    my $args;
    if ( ref $self ) {
        $args = $self->row->get_columns;
        @$args{keys %$_args} = values %$_args if defined $_args;
    } else {
        $args = $_args or return;
    }
    my $validator = $class->validator->{ module };
    $validator->check($args => $class->validation);
}

sub create {
    my ($class, $args) = @_;
    my $result = $class->validate($args);
    croak $result if $result->has_error;
    my $row = $class->db->insert($class->table, $args);
    $class->new({ row => $row });
}

sub update {
    my $self = shift;
    my $method = '_update_' . (ref $self ? 'instance' : 'static');
    $self->$method(@_);
}

sub _update_instance {
    my ($self, $args) = @_;
    my $result = $self->validate($args);
    croak $result if $result->has_error;
    $self->row->update($args);
}

sub _update_static {
    my ($class, $args, $where) = @_;
    my $result = $class->validate($args);
    croak $result if $result->has_error;
    $class->db->update($class->table, $args, $where);
}

sub delete {
    my $self = shift;
    my $method = '_delete_' . (ref $self ? 'instance' : 'static');
    $self->$method(@_);
}

sub _delete_instance {
    my ($self) = @_;
    $self->row->delete;
}

sub _delete_static {
    my ($class, $where) = @_;
    croak 'delete needs where sentence' unless $where;
    $class->db->delete($class->table, $where);
}

sub belongs_to {
    my ($class, $method, $params) = @_;
    croak 'belongs_to needs method name' unless $method;
    $params ||= {};
    my $target = $class->_prepare_target_class($method, $params->{ class });
    my $column = $params->{ key } || $method . '_id';
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return unless $self->$column;
            my $related = $target->find({ id => $self->$column })
                or croak "related row was not found";
        }
    }
}

sub has_one {
    my ($class, $method, $params) = @_;
    croak 'has_one needs method name' unless $method;
    my ($target, $column) = $class->_prepare_related_params($method, $params);
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            return $target->find({ $column => $self->id });
        }
    }
}

sub has_many {
    my ($class, $method, $params) = @_;
    croak 'has_many needs method name' unless $method;
    my ($target, $column) = $class->_prepare_related_params(to_S($method), $params);
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            my $where = shift || {};
            $where->{ $column } = $self->id;
            return $target->find_all($where);
        }
    }
}

sub many_to_many {
    my ($class, $method, $params) = @_;
    croak 'many_to_many needs method name' unless $method;
    $params ||= {};
    my $glue = $params->{ glue } or croak 'many_to_many needs glue class name';
    my $target = $params->{ target }
        || $class->_get_namespace . ucfirst to_S($method);
    my $foreign_key = $params->{ key } || to_S($method) . '_id';
    my $self_key = $params->{ self } || lc $class->_get_suffix . '_id';
    {
        no strict 'refs';
        *{"$class\::$method"} = sub {
            my $self = shift or return;
            my $where = shift || {};
            my @ids;
            my $rs = $self->db->search($glue, { $self_key => $self->id });
            while ( my $row = $rs->next ) {
                push @ids, $row->$foreign_key;
            }
            $where->{ id } = { IN => \@ids };
            return @ids ? $target->find_all($where) : [];
        }
    }
}

sub _prepare_target_class {
    my ($self, $method, $target) = @_;
    my $class = ref $self || $self;
    $target ||= $class->_get_namespace . ucfirst $method;
    $target->require or croak "cannot require $target";
    return $target;
}

sub _prepare_related_params {
    my ($class, $method, $params) = @_;
    $params ||= {};
    my $target = $class->_prepare_target_class($method, $params->{ class });
    my $column = $params->{ key } || lc $class->_get_suffix . '_id';
    return ($target, $column);
}

sub _get_namespace {
    my $class = shift;
    $class =~ s/[^:]+$//;
    return $class;
}

sub _get_suffix {
    my $class = shift;
    $class =~ s/^.+:://;
    return $class;
}

1;
__END__

=head1 NAME

DBIx::Skinny::AR - DBIx::Skinny's wrapper like ActiveRecord


=head1 SYNOPSIS

setup your ar model (DBIx::Skinny already setup as MyApp::DB and MyApp::DB::Schema)

    package MyApp::DB::AR;
    use Any::Moose;
    extends 'DBIx::Skinny::AR';

    __PACKAGE__->setup({
        db => 'MyApp::DB',
        validator => {
            module  => 'FormValidator::Simple',
            plugins => [qw(
                FormValidator::Simple::Plugin::DBIC::Unique
                FormValidator::Simple::Plugin::Japanese
                FormValidator::Simple::Plugin::NetAddr::IP
            )],
        },
    });

    1;

create each model class

    package MyApp::Book;
    use Any::Moose;
    extends 'MyApp::DB::AR';

    __PACKAGE__->mk_accessors;

    sub table { 'books' }

    sub default_search_column { 'name' }

    sub validation {
        [
            id           => [ qw/UINT/ ],
            author_id    => [ qw/NOT_BLANK UINT/ ],
            name         => [ qw/NOT_BLANK ASCII/, [ qw/LENGTH 0 255/ ] ],
            { name => [ qw/id name/ ] } => [ [ 'DBIC_UNIQUE', __PACKAGE__, '!id', 'name' ] ],
        ];
    }

    __PACKAGE__->belongs_to('author');

    1;

in your apps

    use MyApp::Book;
    my $book = MyApp::Book->find($book_name);
    $book->name('new name');
    $book->update;

    my $books = MyApp::Book->find_all;

    my $author = $book->author;


=head1 DESCRIPTION

DBIx::Skinny::AR provides some interfaces like ActiveRecord.

 - find/find_all by any conditions
 - return object wrapped DBIx::Skinny::Row
 - validate before create/update
 - support belongs_to/has_one/has_many/many_to_many relationships


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Ryo Miyake C<< <ryo.studiom@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 SEE ALSO

DBIx::Skinny
