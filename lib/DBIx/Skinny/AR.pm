package DBIx::Skinny::AR;
use Any::Moose;
extends any_moose('::Object'), 'Class::Data::Inheritable';

our $VERSION = '0.0.1';

__PACKAGE__->mk_classdata('db');

has 'row' => (
    is      => 'rw',
    isa     => 'DBIx::Skinny::Row',
    trigger => \&_set_columns,
);

sub BUILD {
    my $self = shift;
    for my $attr ( $self->meta->get_all_attributes ) {
        $self->_chk_unique_value($attr->name)
            if $attr->does('DBIx::Skinny::AR::Meta::Attribute::Trait::Unique');
    }
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

use Carp;
use Lingua::EN::Inflect::Number qw/to_S to_PL/;

use DBIx::Skinny::AR::Meta::Attribute::Trait::Unique;

sub setup {
    my ($class, $db_class) = @_;
    $class->_ensure_load_class($db_class);
    __PACKAGE__->db($db_class);
}

sub table {
    my ($self) = @_;
    my $table = ref $self || $self;
    $table =~ s/^.*:://;
    to_PL(lc $table);
}

sub columns {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ columns };
}

sub pk {
    my ($self) = @_;
    $self->db->schema->schema_info->{ $self->table }->{ pk };
}

sub _set_columns {
    my ($self, $row) = @_;
    for my $col ( @{ $self->columns } ) {
        $self->$col($row->$col) if $self->can($col);
    }
}

sub _get_columns {
    my ($self) = @_;
    my $row;
    for my $col ( @{ $self->columns } ) {
        $row->{ $col } = $self->$col if $self->can($col);
    }
    return $row;
}

sub _chk_unique_value {
    my ($self, $key) = @_;
    my $where = { $key => $self->$key };
    my $pk = $self->pk;
    $where->{ $pk } = { '!=' => $self->$pk } if $self->$pk;
    croak "Attribute ($key) does not pass the type constraint because: ".
        $self->$key. " is not a unique value." if $self->count($where);
}

sub _get_where {
    my ($self, $where) = @_;
    return $where if ref $where eq 'HASH';
    return {} unless $where;
    return { $self->pk => $where } if !ref $where;
    croak 'Invalid where parameter';
}

sub find {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    my $row = $self->db->single(
        $self->table,
        $self->_get_where($where),
        $opt
    ) or return;
    $class->new({ row => $row });
}

sub find_all {
    my ($self, $where, $opt) = @_;
    my $class = ref $self || $self;
    my $rs = $self->db->search(
        $self->table,
        $self->_get_where($where),
        $opt
    );
    my @rows;
    while ( my $row = $rs->next ) {
        push @rows, $class->new({ row => $row });
    }
    return \@rows;
}

sub count {
    my ($self, $where) = @_;
    $self->db->count(
        $self->table,
        $self->pk,
        $self->_get_where($where)
    );
}

sub reload {
    my ($self) = @_;
    croak 'Reload not allowed call as class method' unless ref $self;
    my $pk = $self->pk;
    my $row = $self->db->single($self->table, { $pk => $self->$pk })
            or croak 'Record was deleted';
    $self->row($row);
}

sub create {
    my ($self, $args) = @_;
    my $class = ref $self || $self;
    my $obj = $class->new($args);
    my $row = $self->db->insert($self->table, $args);
    $obj->row($row);
    return $obj;
}

sub update {
    my ($self, $args, $where) = @_;
    if ( ref $self && $self->row ) {
        $args = $self->_get_columns unless $args;
        $self->$_($args->{$_}) for keys %$args;
        $self->row->update($args);
    } else {
        croak 'Update needs where sentence' unless $where;
        $self->db->update($self->table, $args, $where);
    }
}

sub delete {
    my ($self, $where) = @_;
    if ( ref $self && $self->row ) {
        $self->row->delete;
    } else {
        croak 'Delete needs where sentence' unless $where;
        $self->db->delete($self->table, $where);
    }
}

sub belongs_to {
    my ($class, $method, $params) = @_;
    croak 'belongs_to needs method name' unless $method;

    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key } || $target_class->pk;
    my $self_key = $params->{ self_key } || $method . '_' . $target_class->pk;
    my $clearer = 'clear_' . $method;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => $target_class,
        clearer  => $clearer,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $target = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            my $related = $target_class->find({ $target_key => $target })
                or croak "Related row was not found";
        }
    );
    $class->_add_clearer($self_key, $clearer);
}

sub _add_clearer {
    my ($self, $key, $clearer) = @_;
    my $attr = $self->meta->get_attribute($key);
    if ( $attr && $self->can($key) ) {
        $self->meta->add_after_method_modifier($key, sub {
            my $self = shift;
            $self->$clearer if @_;
        });
    }
}

sub has_one {
    my ($class, $method, $params) = @_;
    croak 'has_one needs method name' unless $method;

    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $method;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->pk;

    $class->meta->add_attribute(
        $method,
        is      => 'ro',
        isa     => "Undef | $target_class",
        clearer => 'clear_' . $method,
        lazy    => 1,
        default => sub {
            my $self = shift or return;
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            $target_class->find({ $target_key => $ident });
        }
    );
}

sub has_many {
    my ($class, $method, $params) = @_;
    croak 'has_many needs method name' unless $method;

    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst(to_S $method);
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || lc $class->_get_suffix . '_' . $class->pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        clearer  => 'clear_' . $method,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            $target_class->find_all({ $target_key => $ident });
        }
    );
}

sub many_to_many {
    my ($class, $method, $params) = @_;
    croak 'many_to_many needs method name' unless $method;

    my $target = to_S $method;
    my $self_key = $params->{ self_key } || $class->pk;
    my $target_class = $params->{ target_class }
        || $class->_get_namespace . ucfirst $target;
    $class->_ensure_load_class($target_class);
    my $target_key = $params->{ target_key }
        || $target_class->pk;

    $params->{ glue } ||= {};
    my $glue_table = $params->{ glue }->{ table };
    unless ( $glue_table ) {
        my $suffix = to_PL(lc $class->_get_suffix);
        $glue_table = $method . '_' . $suffix;
        unless ( exists $class->db->schema->schema_info->{ $glue_table } ) {
            $glue_table = $suffix . '_' . $method;
        }
    }
    my $glue_self_key = $params->{ glue }->{ self_key }
        || lc $class->_get_suffix . '_' . $class->pk;
    my $glue_target_key = $params->{ glue }->{ target_key }
        || $target . '_' . $target_class->pk;

    $class->meta->add_attribute(
        $method,
        is       => 'ro',
        isa      => "ArrayRef[$target_class]",
        clearer  => 'clear_' . $method,
        lazy     => 1,
        default  => sub {
            my $self = shift or return;
            my $where = shift || {};
            my $ident = $self->can($self_key)
                ? $self->$self_key
                : $self->row->$self_key or croak "Couldn't fetch $self_key";
            my @target_keys;
            my $rs = $self->db->search($glue_table, { $glue_self_key => $ident });
            while ( my $row = $rs->next ) {
                push @target_keys, $row->$glue_target_key;
            }
            $where->{ $target_key } = { IN => \@target_keys };
            return @target_keys ? $target_class->find_all($where) : [];
        }
    );
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

sub _ensure_load_class {
    my ($self, $class) = @_;
    Any::Moose::load_class($class)
        unless Any::Moose::is_class_loaded($class);
}

1;
__END__

=head1 NAME

DBIx::Skinny::AR - DBIx::Skinny's wrapper like ActiveRecord


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

DBIx::Skinny, DBIx::Skinny::Schema::Loader, Any::Moose
