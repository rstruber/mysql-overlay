# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit cmake-utils eutils flag-o-matic versionator

MAJOR="$(get_version_component_range 1-2 $PV)"
MY_PN="mysql-connector-odbc"
MY_P="${MY_PN}-${PV/_p/r}-src"

DESCRIPTION="ODBC driver for MySQL"
HOMEPAGE="http://www.mysql.com/products/myodbc/"
SRC_URI="mirror://mysql/Downloads/Connector-ODBC/${MAJOR}/${MY_P}.tar.gz"
RESTRICT="primaryuri"

LICENSE="GPL-2"
SLOT="${MAJOR}"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

RDEPEND="
	dev-db/unixODBC
	>=virtual/mysql-4.1
"
DEPEND="${DEPEND} ${RDEPEND}"
S=${WORKDIR}/${MY_P}

# Careful!
DRIVER_NAME="${PN}-${SLOT}"

src_prepare() {
	# Remove Tests
	sed -i -e "s/ADD_SUBDIRECTORY(test)//" \
		"${S}/CMakeLists.txt"

	# Fix as-needed on the installer binary
	echo "TARGET_LINK_LIBRARIES(myodbc-installer odbc)" >> "${S}/installer/CMakeLists.txt"

	# Patch document path so it doesn't install files to /usr
	epatch "${FILESDIR}/cmake-doc-path.patch"
}

src_configure() {
	# The RPM_BUILD flag does nothing except install to /usr/lib64 when "x86_64"
	mycmakeargs+=(
		-DWITH_UNIXODBC=1
		-DRPM_BUILD=1
		-DMYSQL_LIB="$(mysql_config --variable=pkglibdir)/libmysqlclient_r.so"
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	dodir /usr/share/${PN}-${SLOT}
	for i in odbc.ini odbcinst.ini; do
		einfo "Building $i"
			sed \
			-e "s,__PN__,${DRIVER_NAME},g" \
			-e "s,__PF__,${PF},g" \
			-e "s,libmyodbc3.so,libmyodbc${SLOT:0:1}.so,g" \
			>"${D}"/usr/share/${PN}-${SLOT}/${i} \
			<"${FILESDIR}"/${i}.m4 \
			|| die "Failed to build $i"
	done;
}

pkg_config() {

	[ "${ROOT}" != "/" ] && \
		die 'Sorry, non-standard ROOT setting is not supported :-('

	local msg='MySQL ODBC driver'
	local drivers=$(/usr/bin/odbcinst -q -d)

	if echo $drivers | grep -vq "^\[${DRIVER_NAME}\]$" ; then
		ebegin "Installing ${msg}"
		/usr/bin/odbcinst -i -d -f /usr/share/${PN}-${SLOT}/odbcinst.ini
		rc=$?
		eend $rc
		[ $rc -ne 0 ] && die
	else
		einfo "Skipping already installed ${msg}"
	fi

	local sources=$(/usr/bin/odbcinst -q -s)
	msg='sample MySQL ODBC DSN'
	if echo $sources | grep -vq "^\[${DRIVER_NAME}-test\]$"; then
		ebegin "Installing ${msg}"
		/usr/bin/odbcinst -i -s -l -f /usr/share/${PN}-${SLOT}/odbc.ini
		rc=$?
		eend $rc
		[ $rc -ne 0 ] && die
	else
		einfo "Skipping already installed ${msg}"
	fi
}

pkg_postinst() {

	elog "If this is a new install, please run the following command"
	elog "to configure the MySQL ODBC drivers and sources:"
	elog "emerge --config =${CATEGORY}/${PF}"
	elog "Please note that the driver name used to form the DSN now includes the SLOT."
}
