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
# Testing cleanup_invalid_links()
#

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 5;
use English qw(-no_match_vars);

use File::stat;
use Stow::Util qw(make_symlink set_debug_level);

use testutil;

set_debug_level(5);

init_test_dirs();
cd("$TEST_DIR/target");

# setup stow directory
make_path('stow');
make_file('stow/.stow');

# perl
make_path('stow/perl/bin');
make_file('stow/perl/bin/perl');
make_file('stow/perl/bin/a2p');
make_path('stow/perl/info');
make_file('stow/perl/info/perl');
make_path('stow/perl/lib/perl');
make_path('stow/perl/man/man1');
make_file('stow/perl/man/man1/perl.1');

# emacs
make_path('stow/emacs/bin');
make_file('stow/emacs/bin/emacs');
make_file('stow/emacs/bin/etags');
make_path('stow/emacs/info');
make_file('stow/emacs/info/emacs');
make_path('stow/emacs/libexec/emacs');
make_path('stow/emacs/man/man1');
make_file('stow/emacs/man/man1/emacs.1');

# setup target directory
make_path('bin');
ok(make_link('bin/a2p', '../stow/perl/bin/a2p'), 'link a2p');
ok(make_link('bin/emacs', '../stow/emacs/bin/emacs'), 'link emacs');
ok(make_link('bin/etags', '../stow/emacs/bin/etags'), 'link etags');
ok(make_link('bin/perl', '../stow/perl/bin/perl'), 'link perl');
dies_ok {make_link('bin2/perl', '../stow/perl/bin/perl')} 'invalid link';
