#!/usr/bin/perl

use CPAN;

my $config = CPAN::HandleConfig;
$config->load(doit => 1, autoconfig => 1);
$config->edit(auto_commit => 'yes');
$config->edit(build_requires_install_policy => 'yes');
$config->edit(prerequisites_policy => 'follow');
