# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/mysql-connector-c++/mysql-connector-c++-1.1.0_pre814.ebuild,v 1.3 2010/03/25 18:59:39 robbat2 Exp $

EAPI="2"

inherit eutils cmake-utils flag-o-matic

DESCRIPTION="MySQL database connector for C++ (mimics JDBC 4.0 API)"
HOMEPAGE="http://forge.mysql.com/wiki/Connector_C++"
URI_DIR="Connector-C++"
SRC_URI="mirror://mysql/Downloads/${URI_DIR}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="debug examples gcov static"

DEPEND=">=virtual/mysql-5.1
	dev-libs/boost
	dev-libs/openssl"
RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}/${P}-fix-cmake.patch" )

src_configure() {
	# native lib/wrapper needs this!
	append-flags "-fno-strict-aliasing"

	mycmakeargs=(
		"-DMYSQLCPPCONN_BUILD_EXAMPLES=OFF"
		"-DMYSQLCPPCONN_ICU_ENABLE=OFF"
		$(cmake-utils_use debug MYSQLCPPCONN_TRACE_ENABLE)
		$(cmake-utils_use gconv MYSQLCPPCONN_GCOV_ENABLE)
	)

	cmake-utils_src_configure
}

src_compile() {
	# make
	cmake-utils_src_compile mysqlcppconn

	# make static
	use static && cmake-utils_src_compile mysqlcppconn-static
}

src_install() {
	# install - ignore failure for now ...
	emake DESTDIR="${D}" install/fast

	# fast install fails on useflag [-static-libs]
	# http://bugs.mysql.com/bug.php?id=52281
	insinto /usr/include
	doins driver/mysql_{connection,driver}.h || die

	dodoc ANNOUNCE* CHANGES* README || die

	# examples
	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins "${S}"/examples/* || die
	fi
}
