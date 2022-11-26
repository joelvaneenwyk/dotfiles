#!/usr/bin/perl
#
# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

#
# Utilities shared by test scripts
#

package testutil;

use strict;
use warnings;

use Carp qw(croak);
use File::Basename;
use File::Path qw(make_path remove_tree);
use File::Spec;
use IO::Scalar;

use Stow;
use Stow::Util qw(make_symlink parent canon_path error);

use testutil;

remove();
make_path('_test/stow/pkg1/bin1');
make_file('_test/stow/pkg1/bin1/file1')
    or error("Could not create file.");
make_symlink('stow/pkg1/bin1', '_test/bin1')
    or error("Could not create directory link.");
make_symlink('stow/pkg1/bin1/file1', '_test/file1')
    or error("Could not create file link.");
remove();

sub remove {
    unlink '_test/stow/pkg1/bin1';
    unlink '_test/bin1';
    unlink '_test/file1';
    remove_tree '_test/';
}

1;

# Local variables:
# mode: perl
# cperl-indent-level: 4
# end:
# vim: ft=perl
