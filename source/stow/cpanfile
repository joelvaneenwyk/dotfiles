requires 'perl', '>=5.006';

use constant IS_WIN32 => $^O eq 'MSWin32';

requires 'Carp';
requires 'IO::File';
requires 'IO::Scalar';
requires 'ExtUtils::PL2Bat';
requires 'Module::Build';

if (IS_WIN32) {
    requires 'Win32::Mutex';
    requires 'Inline::C';
}

recommends 'App::cpanminus';

on 'configure' => sub {
};

on 'build' => sub {
    requires 'Module::Build';
    requires 'CPAN::DistnameInfo';
};

on 'test' => sub {
    requires 'Test::Output';
    requires 'Test::More';
    requires 'Test::Exception';
    recommends 'TAP::Formatter::JUnit';
    recommends 'Devel::Cover::Report::Coveralls';
};

on 'runtime' => sub {
};

on 'develop' => sub {
    recommends 'Perl::LanguageServer';
    recommends 'Perl::Critic';
    recommends 'Perl::Tidy';
};
