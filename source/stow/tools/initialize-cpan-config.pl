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

use CPAN;

sub normalize_path {
    my ($path) = @_;
    my $normalized = $path;
    $normalized =~ s#\\#/#g;
    return $normalized;
}

sub initialize_config {
    my $initialized = 0;

    # Hook the print function to allow quiet mode
    *CPAN::Shell::myprint = sub {
        my($self, $what) = @_;
        print $what if $initialized;
    };

    my $config = CPAN::HandleConfig;

    $config->load(doit => 1, autoconfig => 1);

    print "Config: " . $config->require_myconfig_or_config() . "\n";
    $initialized = 1;

    $config->edit(auto_commit => 'yes');
    $config->edit(prerequisites_policy => 'follow');
    $config->edit(build_requires_install_policy => 'yes');

    $config->edit(build_dir => normalize_path($CPAN::Config->{build_dir}));
    $config->edit(bzip2 => normalize_path($CPAN::Config->{bzip2}));
    $config->edit(cpan_home => normalize_path($CPAN::Config->{cpan_home}));
    $config->edit(gpg => normalize_path($CPAN::Config->{gpg}));
    $config->edit(gzip => normalize_path($CPAN::Config->{gzip}));
    $config->edit(histfile => normalize_path($CPAN::Config->{histfile}));
    $config->edit(keep_source_where => normalize_path($CPAN::Config->{keep_source_where}));
    $config->edit(make => normalize_path($CPAN::Config->{make}));
    $config->edit(make_install_make_command => normalize_path($CPAN::Config->{make_install_make_command}));
    $config->edit(pager => normalize_path($CPAN::Config->{pager}));
    $config->edit(patch => normalize_path($CPAN::Config->{patch}));
    $config->edit(shell => normalize_path($CPAN::Config->{shell}));
    $config->edit(tar => normalize_path($CPAN::Config->{tar}));
    $config->edit(unzip => normalize_path($CPAN::Config->{unzip}));
    $config->edit(wget => normalize_path($CPAN::Config->{wget}));
    $config->edit(prefs_dir => normalize_path($CPAN::Config->{prefs_dir}));
}

initialize_config
