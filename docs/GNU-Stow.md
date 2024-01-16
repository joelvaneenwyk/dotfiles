# Overview

As of **August 2021**, GNU Stow does not work on native Windows without patches due to lack of symlink support (see [perlport - symlinks](https://perldoc.perl.org/perlport#symlink)). POSIX style symlinks were not added to Windows until somewhat recently so it is not a surprise, but it is still a bit surprising how much is broken in various libraries (e.g. [symlink() function is unimplemented on this machine error in windows · Issue #114 · thoughtbot/ember-cli-rails](https://github.com/thoughtbot/ember-cli-rails/issues/114)) due to this not being available so it is still surprising it has not been officially fixed. Well, it turns out, after way too much digging, that symlinks are, in fact, fixed on Windows:

* [symlink for Windows by tonycoz · Pull Request #18306 · Perl/perl5](https://github.com/Perl/perl5/pull/18306/files)

This fixes [[feature] Implement the symlink function on Windows · Issue #18005 · Perl/perl5](https://github.com/Perl/perl5/issues/18005). The fix is part of `File::Spec::Win32` v3.80 which is part of Perl 5.34 which is not currently available in [Strawberry Perl for Windows](https://strawberryperl.com/) as of August 31st, 2021 even though it was released in May 20, 2021. Full release notes at [perldelta - what is new for perl v5.34.0 - metacpan.org](https://metacpan.org/release/XSAWYERX/perl-5.34.0/view/pod/perldelta.pod) but the key piece is:

* `File::Spec` has been upgraded from version 3.78 to 3.80.

## Progress

Although this is fixed in latest Perl , it would still be good to have a version working. It would also be good for Stow to notify you clearly what does and does not work.

1. Add 'Win32' override to Stow that uses a combination of [symlink for Windows by tonycoz · Pull Request #18306 · Perl/perl5](https://github.com/Perl/perl5/pull/18306/files) and [Win32_Links/Links.pm at master · Jlevens/Win32_Links](https://github.com/Jlevens/Win32_Links/blob/master/lib/Win32/Links.pm). If this approach of using Inline::C is too painful or limiting may fall back to a system call as suggested on this thread: [How to create symlink using Perl?](https://www.perlmonks.org/bare/?node_id=933175). There is also some good feedback/thoughts on [Handling of symlinks on Windows (Perl, MSYS2, Cygwin) - DEV Community](https://dev.to/hakonhagland/handling-of-symlinks-on-windows-perl-msys2-cygwin-52h3) to re-review before calling it done.
2. Create working solution on [joelvaneenwyk/stow at win32](https://github.com/joelvaneenwyk/stow/tree/win32)
3. Follow guidelines on [perlport - Writing portable Perl - Perldoc Browser](https://perldoc.perl.org/perlport#PLATFORMS)
4. Fix unit tests for Stow. This may require fixing `stat` as well as described on [Perl - Detecting symbolic links under Windows 10 - Stack Overflow](https://stackoverflow.com/questions/50244042/perl-detecting-symbolic-links-under-windows-10).
5. Add auto-sync GitHub action so that it doesn't need to be maintained or at least get a notification when an update happens, see [Can forks be synced automatically in GitHub? - Stack Overflow](https://stackoverflow.com/questions/23793062/can-forks-be-synced-automatically-in-github).

### Notes

* Would be great to use [Win32::Symlink - Symlink support on Windows - metacpan.org](https://metacpan.org/pod/Win32::Symlink) or [Win32::NTFS::Symlink - Support for NTFS symlinks and junctions on Microsoft Windows - metacpan.org](https://metacpan.org/pod/Win32::NTFS::Symlink) but they both seem broken in some way or another.

## TeX

* [texi2dvi - Creating PDF documents from .texi files - TeX - LaTeX Stack Exchange](https://tex.stackexchange.com/questions/71604/creating-pdf-documents-from-texi-files)

## Resources

* [How to create symlink using Perl?](https://www.perlmonks.org/?displaytype=print;node_id=933175;replies=1)
* [The CYGWIN environment variable](https://cygwin.com/cygwin-ug-net/using-cygwinenv.html)
* [Win32_Links: Perl module to seamlessly support symlinks on Windows -- no need to refactor the code between  Win/Linux](https://github.com/Jlevens/Win32_Links)
* [delete folder and its content with plain perl](https://www.perlmonks.org/?node_id=1202880)
* [StrawberryPerl](https://github.com/StrawberryPerl)
* [Strawberry Perl for Windows - Releases](https://strawberryperl.com/releases.html)
* [delete folder and its content with plain perl](https://www.perlmonks.org/?node_id=1202880)
* [Handling of symlinks on Windows (Perl, MSYS2, Cygwin) - DEV Community](https://dev.to/hakonhagland/handling-of-symlinks-on-windows-perl-msys2-cygwin-52h3)
* [File::Path - Create or remove directory trees - Perldoc Browser](https://perldoc.perl.org/File::Path)
* [perlport - Writing portable Perl - Perldoc Browser](https://perldoc.perl.org/perlport)

## Perl Development

Some resources while digging into various issues with Perl.

* [Download Padre, the Perl IDE](https://padre.perlide.org/download.html) - Perhaps this is good for some people but this is not the type of tool I need. It feels quite clunky and my development speed is not increased from use.
* [VSCode as a Perl IDE - DEV Community](https://dev.to/perldean/vscode-as-a-perl-ide-3cco)
* [IDEs (Integrated Development Environments) and Other Tools for Perl - The Perl Beginners’ Site](https://perl-begin.org/IDEs-and-tools/)
