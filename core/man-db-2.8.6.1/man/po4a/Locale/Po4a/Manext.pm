#! /usr/bin/perl -w

=encoding UTF-8

=head1 NAME

Locale::Po4a::Manext - private extended version of Locale::Po4a::Man

=head1 DESCRIPTION

Extended version of Locale::Po4a::Man that copes with a few intricacies of
man-db's manual pages, until such time as these are incorporated into po4a
proper.

=head1 SEE ALSO

L<Locale::Po4a::Man(3pm)>.

=head1 AUTHOR

 Colin Watson <cjwatson@debian.org>

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Colin Watson.

man-db is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

man-db is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with man-db; if not, write to the Free Software Foundation,
Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

package Locale::Po4a::Manext;

use 5.006;
use strict;
use warnings;

use vars qw(@ISA);
@ISA = qw(Locale::Po4a::Man);

use version;

use Locale::Po4a::Man;
use Locale::Po4a::TransTractor;

sub initialize {
    my $self = shift;
    $self->SUPER::initialize(@_);

    $self->{manext_shift_tbl_state} = 0;
    $self->{manext_shift_tbl_lines} = [];
    $self->{manext_push_tbl_state} = 0;
    $self->{manext_push_tbl_line} = '';
}

sub shiftline {
    my $self = shift;

    if (version->parse($Locale::Po4a::TransTractor::VERSION) >= '0.47') {
        return $self->SUPER::shiftline();
    }

    my ($line, $ref);

    if (@{$self->{manext_shift_tbl_lines}}) {
        ($line, $ref) = @{shift @{$self->{manext_shift_tbl_lines}}};
        return ($line, $ref);
    }

NEXT_LINE:
    ($line, $ref) = $self->SUPER::shiftline();

    if (!defined $line) {
        # end of file
        return ($line, $ref);
    }

    if ($line =~ /^\.TS/) {
        $self->{manext_shift_tbl_state} = 1;
    } elsif ($line =~ /^\.TE/) {
        $self->{manext_shift_tbl_state} = 0;
    } elsif ($self->{manext_shift_tbl_state} == 1) {
        if ($line =~ /\.$/) {
            $self->{manext_shift_tbl_state} = 2;
        }
    } elsif ($self->{manext_shift_tbl_state} == 2) {
        # Theoretically s/@/\t/g should be enough, but for some reason
        # Locale::Po4a::Man splits on /\\t/ rather than on /\t/.
        if ($line =~ /T\{$/) {
            my ($l2, $r2) = $self->SUPER::shiftline();
            while (defined $l2) {
                $line .= $l2;
                last if $l2 =~ /^T\}/;
                ($l2, $r2) = $self->SUPER::shiftline();
            }
        }
        if ($line =~ /@/) {
            for my $column (split /@/, $line) {
                next if $column =~ /^$/m;
                push @{$self->{manext_shift_tbl_lines}}, [$column, $ref];
            }
            ($line, $ref) = @{shift @{$self->{manext_shift_tbl_lines}}};
            return ($line, $ref);
        }
    }

    return ($line, $ref);
}

sub pushline {
    my ($self, $line) = (shift, shift);

    if (version->parse($Locale::Po4a::TransTractor::VERSION) >= '0.47') {
        $self->SUPER::pushline($line);
        return;
    }

    if ($line =~ /^\.TS/) {
        $self->{manext_push_tbl_state} = 1;
    } elsif ($line =~ /^\.TE/) {
        $self->{manext_push_tbl_state} = 0;
    } elsif ($self->{manext_push_tbl_state} == 1) {
        if ($line =~ /\.$/) {
            $self->{manext_push_tbl_state} = 2;
        }
    } elsif ($self->{manext_push_tbl_state} == 2) {
        if (length $self->{manext_push_tbl_line}) {
            $self->{manext_push_tbl_line} .= '@';
        }
        $self->{manext_push_tbl_line} .= $line;
        if ($self->{manext_push_tbl_line} =~ /\n$/) {
            $self->SUPER::pushline($self->{manext_push_tbl_line});
            $self->{manext_push_tbl_line} = '';
        }
        return;
    }

    $self->SUPER::pushline($line);
}

sub translate {
    my ($self, $str, $ref, $type) = (shift, shift, shift, shift);
    my %options = @_;

    if (defined $type and $type eq 'tbl table') {
        if (version->parse($Locale::Po4a::TransTractor::VERSION) < '0.47') {
            if ($str =~ /^T\{\n?(.*)T\}(\n?)$/s) {
                my $inner = $1;
                chomp $inner;
                return "T{\n" .
                       $self->SUPER::translate($inner, $ref, $type, %options) .
                       "\nT}$2";
            }
        } else {
            my $postline = '';
            if (chomp $str) {
                $postline = "\n";
            }
            if ($str =~ /@/) {
                return join('@', map {
                    $self->translate($_, $ref, 'tbl table manext')
                } split (/@/, $str, -1)) . $postline;
            } else {
                return $self->translate($str, $ref, 'tbl table manext') .
                       $postline;
            }
        }
    }

    if (defined $type and $type =~ /^tbl table(?: manext)$/) {
        # Do not translate horizontal rules.
        return $str if $str =~ /^[-_=]$/;

        # Do not translate table entries that consist only of numbers (e.g.
        # the sections table in man(1)).
        return $str if $str =~ /^[0-9]+$/;

        # Do not translate table entries that consist only of a groff
        # special character or escape (e.g. the --ascii translation table in
        # man(1)).
        if ($str =~ /^\\[^([]$/ or              # e.g. \`
            $str =~ /^\\\(..$/ or               # e.g. \(bu
            $str =~ /^\\\[.*?\]$/ or            # e.g. \[bu]
            $str =~ /^\\[^([][^([]$/ or         # e.g. \fB
            $str =~ /^\\[^([]\(..$/ or          # e.g. \n(XX
            $str =~ /^\\[^([]\[.*?\]$/) {       # e.g. \*[softhyphen]
            return $str;
        }

        # Do not translate "latin1" and "ascii" (from the --ascii
        # translation table in man(1)).
        return $str if $str =~ /^(?:latin1|ascii)$/;

        # Do not translate symbols used in the --ascii translation table in
        # man(1).
        return $str if $str =~ /^[o'x]$/;

        $type =~ s/ manext$//;
    }

    if (not defined $type and $self->{type} eq 'TH') {
        # Do not translate page names and other similar headings.
        return $str if $str =~ /^%.*%$/ or $str =~ /^[A-Z]+$/;
    }

    return $self->SUPER::translate($str, $ref, $type, %options);
}

1;
