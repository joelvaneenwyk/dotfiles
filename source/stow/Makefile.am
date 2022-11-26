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

## Process this file with Automake to produce Makefile.in

bin_SCRIPTS = bin/stow bin/chkstow
info_TEXINFOS = doc/stow.texi
dist_man_MANS = doc/stow.8

PDF = doc/manual.pdf
HTML = doc/manual-single.html

dist_doc_DATA = \
	README.md INSTALL.md \
	$(PDF) $(HTML) doc/version.texi \
	ChangeLog doc/ChangeLog.OLD

# automake magic to define where *_DATA files get installed:
pmdir = $(PMDIR)
pmstowdir = $(pmdir)/Stow

pm_DATA = lib/Stow.pm
pmstow_DATA = lib/Stow/Util.pm

is_msys = { \
    if test -n '$(MSYSTEM)'; then \
        true; \
    else \
        false; \
    fi; \
}

# We require this -I parameter to ensure that the include of the
# default ignore list in the manual works.  Unfortunately this is
# the only way to do it:
#
#   http://article.gmane.org/gmane.comp.sysutils.automake.bugs/4334/match=passing+parameters
#
# even though it annoyingly produces a warning with the -Wall option
# to AM_INIT_AUTOMAKE which has to be silenced via -Wno-override.
AM_MAKEINFOFLAGS = -I $(srcdir) -I $(srcdir)/doc -I $(srcdir)/automake

#  `local' compile in the current directory, leaving all the auxiliary
#          files around.  This is the traditional TeX use.
#  `tidy'  compile in a local *.t2d directory, where the auxiliary files
#          are left.  Output files are copied back to the original file.
#  `clean' same as `tidy', but remove the auxiliary directory afterwards.
#          Every compilation therefore requires the full cycle.
export TEXI2DVI_BUILD_MODE = clean

# Add '--debug' to get a very detailed output log (equivalent to 'set -x')
TEXI2DVI = texi2dvi $(AM_MAKEINFOFLAGS)

# Specifically used when converting from '.texi' to '.pdf'
TEXI2PDF = $(TEXI2DVI) --pdf

doc_deps = $(info_TEXINFOS) doc/version.texi

DEFAULT_IGNORE_LIST = $(srcdir)/default-ignore-list

TESTS_DIR = $(srcdir)/t
TESTS_OUT = tmp-testing-trees _test
TESTS_ENVIRONMENT = $(PERL) -Ibin -Ilib -I$(TESTS_DIR)

# This is a kind of hack; TESTS needs to be set to ensure that the
# `check-am' target makes check-TESTS, but we override check-TESTS
# so it doesn't really matter what it's set to, as long as it already
# exists (otherwise automake will try to build it).
TESTS = t

# GNU autotools standardised on the 'check' target, but CPAN (and the
# rest of the world) standardised on the 'test' target.
test: check

# required in vpath mode to ensure $build/t/ exists
check_DATA = $(TESTS_OUT)

# Test::Harness produces cleaner output than automake's default test
# harness, albeit without the pretty colours provided by the
# `color-tests' AM_INIT_AUTOMAKE option.  This also dodges having to
# set TESTS to the full list of tests, which is good because automake
# doesn't support wildcards, and so it would be too easy to forget to
# add a new one to the list.
#
# Note that automake's `check' rule cannot be overridden
# for some weird reason:
#
#   http://thread.gmane.org/gmane.comp.sysutils.automake.general/13040/focus=13041
#
# so we override check-TESTS instead which is where the real work is
# done anyway.  Unfortunately this produces a warning with the -Wall
# option to AM_INIT_AUTOMAKE which has to be silenced via
# -Wno-override.
check-TESTS:
	dir=$(TESTS_DIR); \
	$(TESTS_ENVIRONMENT) -MTest::Harness -e 'runtests(@ARGV)' "$${dir#./}"/*.t

$(TESTS_OUT):
	mkdir -p $@

CPAN_FILES = MANIFEST MANIFEST.SKIP Build.PL META.yml META.json
EXTRA_DIST = \
	bin/stow.in bin/chkstow.in lib/Stow.pm.in lib/Stow/Util.pm.in \
	doc/manual-split \
	$(TESTS) t/testutil.pm \
	$(TEXINFO_TEX) \
	$(DEFAULT_IGNORE_LIST) \
	$(CPAN_FILES)
CLEANFILES = $(bin_SCRIPTS) $(pm_DATA) $(pmstow_DATA)
DISTCLEANFILES = Makefile.in configure Build MYMETA.* $(PDF)
MAINTAINERCLEANFILES = $(dist_man_MANS) $(HTML) $(PDF) ChangeLog

# clean up auto-generated files
clean-local:
	-rm -rf $(TESTS_OUT) _Inline _build
maintainer-clean-local:
	-rm -rf doc/manual-split cover_db

# this is more explicit and reliable than the config file trick
edit = sed -e 's|[@]PERL[@]|$(PERL)|g' \
	   -e 's|[@]VERSION[@]|$(VERSION)|g' \
	   -e "s|[@]USE_LIB_PMDIR[@]|$$use_lib_pmdir|g"

pmdir_in_INC = \
	PERL5LIB= $(PERL) -V | \
	    awk '/@INC:/ {p=1; next} p==1 {print $$1}' | \
	    sed 's/\\/\//g' | \
	    grep -q "`$(CYGPATH_P) '$(pmdir)'`"

calc_use_lib_pmdir = \
	if $(pmdir_in_INC); then \
	    use_lib_pmdir=""; \
	else \
	    use_lib_pmdir="use lib \"`$(CYGPATH_P) '$(pmdir)'`\";"; \
	fi

check_pmdir = \
	echo; \
	echo "\# Perl modules will be installed to `$(CYGPATH_P) '$(pmdir)'`"; \
	echo "\# "; \
	if $(pmdir_in_INC); then \
	    echo "\# This is in $(PERL)'s built-in @INC, so everything"; \
	    echo "\# should work fine with no extra effort."; \
	else \
	    echo "\# This is not in $(PERL)'s built-in @INC, so the"; \
	    echo "\# front-end scripts will have an appropriate \"use lib\""; \
	    echo "\# line inserted to compensate."; \
	fi; \
	echo

bin/stow: bin/stow.in Makefile.am
	[ -d bin ] || mkdir bin # required in vpath mode
	@$(check_pmdir)
	@$(calc_use_lib_pmdir); \
	$(edit) < $< > $@
	@echo "Generated $@ from $<"
	chmod +x $@

bin/chkstow: bin/chkstow.in Makefile.am
	@[ -d bin ] || mkdir bin # required in vpath mode
	@$(edit) < $< > $@
	@echo "Generated $@ from $<"
	chmod +x $@

lib/Stow.pm: lib/Stow.pm.in $(DEFAULT_IGNORE_LIST) Makefile.am
	@[ -d lib ] || mkdir lib # required in vpath mode
	@( $(edit) < $<; cat $(DEFAULT_IGNORE_LIST) ) > $@
	@echo "Generated $@ from $< and $(DEFAULT_IGNORE_LIST)"

lib/Stow/Util.pm: lib/Stow/Util.pm.in Makefile.am
	@[ -d lib/Stow ] || mkdir -p lib/Stow # required in vpath mode
	@$(edit) < $< > $@
	@echo "Generated $@ from $<"

##############################################################################
# The below rules should only be needed by developers.
##############################################################################

cpanm:
	( \
	    echo "yes"     \
	    echo ""        \
	    echo "no"      \
	    echo "exit"    \
	) | COMSPEC="" "$(PERL)" "./tools/initialize-cpan-config.pl" || true; \
	"$(PERL)" -MCPAN -e "CPAN::Shell->notest('install', 'App::cpanminus')" 2>&1; \
	"$(PERL)" -MApp::cpanminus::fatscript \
	    -le 'my $$c = App::cpanminus::script->new; $$c->parse_options(@ARGV); $$c->doit;' -- \
	    --installdeps --notest --with-recommends --with-suggests . 2>&1; \
	CPANM_RESULT=$$?; \
	if [ $$CPANM_RESULT != 0 ]; then \
	    echo ---------------------------------------------------; \
	    cat ~/.cpanm/build.log; \
	    echo ---------------------------------------------------; \
	    exit $$CPANM_RESULT; \
	fi

doc/stow.8: bin/stow.in Makefile.am
	[ -d doc ] || mkdir doc # required in vpath mode
	$(edit) < $< | pod2man --name stow --section 8 > $@

# We use automake's built-in rule to generate stow.info.  The built-in
# rules would also generate doc/stow.html and doc/stow.pdf, but after
# installation we want $(docdir) (typically /usr/share/doc/stow/) to
# contain manual-single.html, manual.pdf, and manual-split/*.html, to
# make it explicitly obvious that these files contain the user manual
# rather than some other Stow-related documentation.
#
# If it were not for a troublesome dependency on doc/$(am__dirstamp):
#
#   http://article.gmane.org/gmane.comp.sysutils.automake.general/13192
#
# we could have achieved this using the built-in rules combined with
# install-data-hook to rename from stow.pdf to manual.pdf etc. on
# install.  Instead, by overriding the built-in rules with modified
# versions, we can kill both birds with one stone.
.PHONY: manual-single-html-all

doc/stow.dvi: doc/stow.texi $(srcdir)/doc/version.texi doc/$(am__dirstamp)
	[ -d doc ] || mkdir doc # required in vpath mode
	if $(is_msys); then \
	    TEXMFOUTPUT="doc" \
	    TEXINPUTS="`$(CYGPATH_P) '$(STOW_ROOT)'`/doc$(PATH_SEPARATOR)$(srcdir)$(PATH_SEPARATOR)$(srcdir)/doc$(PATH_SEPARATOR)$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	    pdfetex \
	        --output-format dvi -output-directory=`test -f 'doc/stow.texi' || echo '$(srcdir)/'`/doc \
	        `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi </dev/null; \
	    rm -rf \
	        "doc/stow.aux" "doc/stow.cp" \
	        "doc/stow.log" "doc/stow.toc"; \
	else \
	    $(AM_V_TEXI2DVI)TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	    MAKEINFO='$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc' \
	    $(TEXI2DVI) $(AM_V_texinfo) --build-dir=$(@:.dvi=.t2d) -o $@ $(AM_V_texidevnull) \
	    `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi; \
	fi

doc/stow.pdf: doc/stow.texi $(srcdir)/doc/version.texi doc/$(am__dirstamp)
	[ -d doc ] || mkdir doc # required in vpath mode
	if $(is_msys); then \
	    TEXMFOUTPUT="doc" \
	    TEXINPUTS="`$(CYGPATH_P) '$(STOW_ROOT)'`/doc$(PATH_SEPARATOR)$(srcdir)$(PATH_SEPARATOR)$(srcdir)/doc$(PATH_SEPARATOR)$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	    pdfetex \
	        -output-directory=`test -f 'doc/stow.texi' || echo '$(srcdir)/'`/doc \
	        `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi </dev/null; \
	    rm -rf \
	        "doc/stow.aux" "doc/stow.cp" \
	        "doc/stow.log" "doc/stow.toc"; \
	else \
	    $(AM_V_TEXI2PDF)TEXINPUTS="$(am__TEXINFO_TEX_DIR)$(PATH_SEPARATOR)$$TEXINPUTS" \
	    MAKEINFO='$(MAKEINFO) $(AM_MAKEINFOFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc' \
	    $(TEXI2PDF) $(AM_V_texinfo) --build-dir=$(@:.pdf=.t2p) -o $@ $(AM_V_texidevnull) \
	    `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi; \
	fi

manual-single-html-all: \
	$(HTML)

# Modern approach using $(MAKEINFOHTML) --no-split
# Differences to the older two approaches:
#
#   - Nicer navigation links between sections
$(HTML): $(doc_deps)
	[ -d doc ] || mkdir doc # required in vpath mode
	-rm -f $@
	$(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) -I doc -I $(srcdir)/doc \
	    --no-split `$(MAKEINFO) --help | grep -q "set-customization-variable" && echo '--set-customization-variable USE_TITLEPAGE_FOR_TITLE=1'` \
	    -o "$@" \
	    `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi

$(PDF): $(doc_deps) $(HTML) doc/stow.pdf
	[ -d doc ] || mkdir doc # required in vpath mode
	mv `test -f 'doc/stow.pdf' || echo '$(srcdir)/'`doc/stow.pdf "$@"

doc/manual-split: $(doc_deps)
	rm -rf $@.new
	if $(MAKEINFOHTML) $(AM_MAKEINFOHTMLFLAGS) $(MAKEINFOFLAGS) \
	    -I $(srcdir) -I doc -I $(srcdir)/doc \
	    -o $@.new `test -f 'doc/stow.texi' || echo '$(srcdir)/'`doc/stow.texi; \
	then \
	    rm -rf $@; \
	    mv $@.new $@; \
	else \
	    rm -Rf $@.new $@; \
	    exit 1; \
	fi

# The split version of the manual is copied to $(docdir)/manual-split
# by install-data-hook.  The whole subdirectory is included via
# EXTRA_DIST in order to avoid having to list each file explicitly in
# dist_doc_DATA, since automake doesn't support wildcards, and
# dist_doc_DATA cannot refer to directories while EXTRA_DIST can (go
# figure ...)

install-data-hook: doc/manual-split
	cp -r $(srcdir)/doc/manual-split $(DESTDIR)$(docdir)

uninstall-hook:
	chmod -R u+w $(DESTDIR)$(docdir)/manual-split
	rm -rf $(DESTDIR)$(docdir)/manual-split
	rm -f $(DESTDIR)/info/dir

# Using install-data-hook has the slightly annoying disadvantage that
# by default the split version of the manual isn't automatically
# rebuilt during development by a simple `make'.  A workaround hack
# for this is to piggy-back the dependency onto manual-single.html,
# which *is* automatically rebuilt by `make':
$(HTML): doc/manual-split

# With the above hack, this probably isn't necessary but is safer to
# keep in anyway:
dist-hook: doc/manual-split

dist-hook: $(dist_man_MANS)
	## If we are creating a distribution from a git checkout, ensure
	## the ChangeLog file is in sync the git repository.
	if test -e "$(srcdir)/.git"; then \
	    rm -f ChangeLog \
	        && $(MAKE) $(AM_MAKEFLAGS) ChangeLog \
	        && cp -f ChangeLog $(distdir)/ChangeLog; \
	fi

ChangeLog: doc/ChangeLog.OLD
	if [ -e "$(srcdir)/.git" ]; then \
	    ( \
	        git log \
	            --format="format:%ad  %aN <%aE>%n%n    * %w(70,0,4)%s%+b%n" \
	            --name-status \
	            v2.0.2..HEAD | sed 's/^\([A-Z]\)\t/      \1 /'; \
	        cat "$<" \
	    ) > "$(srcdir)/$@"; \
	    echo "Rebuilt '$@' from git commit history."; \
	else \
	    echo "Not in a git repository; can't update ChangeLog."; \
	fi
