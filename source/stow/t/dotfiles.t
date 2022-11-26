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
# Test case for dotfiles special processing
#

use strict;
use warnings;


use Test::More tests => 6;
use English qw(-no_match_vars);

use Stow::Util qw(set_debug_level);

use testutil;
init_test_dirs();
cd("$TEST_DIR/target");

my $stow;

#
# process a dotfile marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    normalize_path(get_link_target('.foo')),
    '../stow/dotfiles/dot-foo',
    => 'processed dotfile'
);

#
# ensure that turning off dotfile processing links files as usual
#

$stow = new_Stow(dir => '../stow', dotfiles => 0);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-foo');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    normalize_path(get_link_target('dot-foo')),
    '../stow/dotfiles/dot-foo',
    => 'unprocessed dotfile'
);


#
# process folder marked with 'dot' prefix
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles/dot-emacs');
make_file('../stow/dotfiles/dot-emacs/init.el');

$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    normalize_path(get_link_target('.emacs')),
    '../stow/dotfiles/dot-emacs',
    => 'processed dotfile folder'
);

#
# corner case: paths that have a part in them that's just "$DOT_PREFIX" or
# "$DOT_PREFIX." should not have that part expanded.
#

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-');

# Not supported on Windows since long path is not supported which is required
# for non-standard characters at the end of a folder e.g., '.' (dot)
if ($^O ne 'MSWin32') {
    make_path('../stow/dotfiles/dot-.');
    make_file('../stow/dotfiles/dot-./foo');
}

$stow = new_Stow(dir => '../stow', dotfiles => 1);
$stow->plan_stow('dotfiles');
$stow->process_tasks();
is(
    normalize_path(get_link_target('dot-')),
    '../stow/dotfiles/dot-',
    => 'processed dotfile'
);

SKIP: {
    skip 'Windows does not support trailing dot characters in path', 1 if $^O eq 'MSWin32';

    is(
        normalize_path(get_link_target('dot-.')),
        '../stow/dotfiles/dot-.',
        => 'unprocessed dotfile'
    );
}

#
# simple unstow scenario
#

$stow = new_Stow(dir => '../stow', dotfiles => 1);

make_path('../stow/dotfiles');
make_file('../stow/dotfiles/dot-bar');
make_link('.bar', '../stow/dotfiles/dot-bar');

$stow->plan_unstow('dotfiles');
$stow->process_tasks();
ok(
    $stow->get_conflict_count == 0 &&
    -f '../stow/dotfiles/dot-bar' &&
    ! -e '.bar'
    => 'unstow a simple dotfile'
);
