# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit cmake-multilib eutils

DESCRIPTION="Client Library for C is used to connect applications developed in C/C++ to MariaDB/MySQL databases"
HOMEPAGE="http://mariadb.org/"
SRC_URI="
	http://ftp.osuosl.org/pub/mariadb/${PN}/Source/${PN}.tar.gz
	http://mirrors.fe.up.pt/pub/mariadb/${PN}/Source/${PN}.tar.gz
	http://ftp-stud.hs-esslingen.de/pub/Mirrors/mariadb/${PN}/Source/${PN}.tar.gz
	"
LICENSE="LGPL-2.1"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc static-libs"

RDEPEND="dev-libs/openssl"
DEPEND="${RDEPEND}
	doc? ( app-text/xmlto )"
S="${WORKDIR}/${PN}"

src_prepare() {
	epatch "${FILESDIR}/multilib-install.patch"
}

src_configure() {
	mycmakeargs+=(
		-DMYSQL_UNIX_ADDR="${EPREFIX}/var/run/mysqld/mysqld.sock"
		$(cmake-utils_use_build doc DOCS)
	)
	cmake-multilib_src_configure
}

src_install() {
	strip_static_libraries() {
		einfo "IN ${T}/usr/$(get_libdir)"
		rm "${T}/usr/$(get_libdir)/mariadb/libmariadbclient.a"
	}

	cmake-multilib_src_install
	if ! use static-libs ; then
		multilib_foreach_abi strip_static_libraries
	fi
}
