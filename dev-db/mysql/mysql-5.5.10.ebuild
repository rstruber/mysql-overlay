# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/mysql/mysql-5.5.1_alpha_pre2.ebuild,v 1.8 2010/04/01 20:41:21 robbat2 Exp $

MY_EXTRAS_VER="live"
EAPI=2
MY_PV="${PV//_alpha_pre/-m}"
MY_PV="${MY_PV//_/-}"

inherit toolchain-funcs mysql-v2
# only to make repoman happy. it is really set in the eclass
IUSE="$IUSE"

# Define the mysql-extras source
EGIT_REPO_URI="git://git.overlays.gentoo.org/proj/mysql-extras.git"

# REMEMBER: also update eclass/mysql*.eclass before committing!
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"

# When MY_EXTRAS is bumped, the index should be revised to exclude these.
EPATCH_EXCLUDE=''

DEPEND="|| ( >=sys-devel/gcc-3.4.6 >=sys-devel/gcc-apple-4.0 )"

# Please do not add a naive src_unpack to this ebuild
# If you want to add a single patch, copy the ebuild to an overlay
# and create your own mysql-extras tarball, looking at 000_index.txt

# Official test instructions:
# USE='berkdb -cluster embedded extraengine perl ssl community' \
# FEATURES='test userpriv -usersandbox' \
# ebuild mysql-X.X.XX.ebuild \
# digest clean package
src_test() {

	TESTDIR="${CMAKE_BUILD_DIR}/mysql-test"

	# Bug #213475 - MySQL _will_ object strenously if your machine is named
	# localhost. Also causes weird failures.
	[[ "${HOSTNAME}" == "localhost" ]] && die "Your machine must NOT be named localhost"

	if ! use "minimal" ; then

		if [[ $UID -eq 0 ]]; then
			die "Testing with FEATURES=-userpriv is no longer supported by upstream. Tests MUST be run as non-root."
		fi
		has usersandbox $FEATURES && eerror "Some tests may fail with FEATURES=usersandbox"

		# Run CTest
		cmake-utils_src_test

		# Run mysql tests
		pushd "${TESTDIR}"
		perl mysql-test-run.pl
		popd

	else

		einfo "Skipping server tests due to minimal build."
	fi
}
