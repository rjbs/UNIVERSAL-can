package UNIVERSAL::can;

use strict;
use warnings;

use vars qw( $VERSION $recursing );
$VERSION = '1.13_001';

use Scalar::Util 'blessed';
use warnings::register;

my $orig;
use vars '$always_warn';

BEGIN
{
    $orig = \&UNIVERSAL::can;

    no warnings 'redefine';
    *UNIVERSAL::can = \&can;
}

sub import
{
    my $class = shift;
    for my $import (@_)
    {
        $always_warn = 1 if $import eq '-always_warn';
        no strict 'refs';
        *{ caller() . '::can' } = \&can if $import eq 'can';
    }
}

sub can
{
    # don't get into a loop here
    goto &$orig if $recursing;

    # call an overridden can() if it exists
    local $@;
    my $can = eval { $_[0]->$orig('can') || 0 };

    # but only if it's a real class
    goto &$orig unless $can;

    # but not if it inherited this one
    goto &$orig if     $can == \&UNIVERSAL::can;

    # redirect to an overridden can, making sure not to recurse and warning
    local $recursing = 1;
    my    $invocant  = shift;

    _report_warning();
    return $invocant->can(@_);
}

sub _report_warning
{
    if ( $always_warn || warnings::enabled() )
    {
        my $calling_sub = ( caller(2) )[3] || '';
        warnings::warn("Called UNIVERSAL::can() as a function, not a method")
            if $calling_sub !~ /::can$/;
    }

    return;
}

1;
__END__

=head1 NAME

UNIVERSAL::can - Hack around people calling UNIVERSAL::can() as a function

=head1 VERSION

Version 1.13_001

=head1 SYNOPSIS

To use this module, simply:

  use UNIVERSAL::can;

=head1 DESCRIPTION

The UNIVERSAL class provides a few default methods so that all objects can use
them.  Object orientation allows programmers to override these methods in
subclasses to provide more specific and appropriate behavior.

Some authors call methods in the UNIVERSAL class on potential invocants as
functions, bypassing any possible overriding.  This is wrong and you should not
do it.  Unfortunately, not everyone heeds this warning and their bad code can
break your good code.

This module replaces C<UNIVERSAL::can()> with a method that checks to see if
the first argument is a valid invocant has its own C<can()> method.  If so, it
gives a warning and calls the overridden method, working around buggy code.
Otherwise, everything works as you might expect.

Some people argue that you must call C<UNIVERSAL::can()> as a function because
you don't know if your proposed invocant is a valid invocant.  That's silly.
Use C<blessed()> from L<Scalar::Util> if you want to check that the potential
invocant is an object or call the method anyway in an C<eval> block and check
for failure.

Just don't break working code.

=head1 AUTHOR

chromatic, C<< <chromatic@wgz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-universal-can@rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=UNIVERSAL-can>.  This will
contact me, hold onto patches so I don't drop them, and will notify you of
progress on your request as I make changes.

=head1 ACKNOWLEDGEMENTS

Inspired by L<UNIVERSAL::isa> by Yuval Kogman, Autrijus Tang, and myself.

Adam Kennedy has tirelessly made me tired by reporting potential bugs and
suggesting ideas that found actual bugs.

Mark Clements helped to track down an invalid invocant bug.

Curtis "Ovid" Poe finally provided the inspiration I needed to clean up the
interface.

The Perl QA list had a huge... discussion... which inspired my realization that
this module needed to do what it does now.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 - 2007 chromatic. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
