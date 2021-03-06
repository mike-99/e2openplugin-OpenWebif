#!/bin/bash

D=$(pushd $(dirname $0) &> /dev/null; pwd; popd &> /dev/null)
P=${D}/ipkg.tmp.$$
B=${D}/ipkg.build.$$

pushd ${D} &> /dev/null
VER=$(head -n 1 CHANGES.md | grep -i '## Version' | sed 's/^## Version \([[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\)/\1/')
# '%cd': committer date (format respects --date= option); '%t': abbreviated tree hash
GITVER=git$(git log -1 --format="%cd" --date="format:%Y%m%d")

PKG=${D}/enigma2-plugin-extensions-openwebif_${VER}-${GITVER}_all.ipk
if [ "$1" == "novxg" ]; then
	PKG=${D}/enigma2-plugin-extensions-openwebif_${VER}-${GITVER}_novxg.ipk
fi

if [ "$1" == "vti" ]; then
	PKG=${D}/enigma2-plugin-extensions-openwebif_${VER}-${GITVER}_vti.ipk
fi

popd &> /dev/null

mkdir -p ${P}
mkdir -p ${P}/CONTROL
mkdir -p ${B}

cat > ${P}/CONTROL/control << EOF
Package: enigma2-plugin-extensions-openwebif
Version: ${VER}-${GITVER}-r0
Description: Control your receiver with a browser
Architecture: all
Section: extra
Priority: optional
Maintainer: E2OpenPlugins members
Homepage: https://github.com/E2OpenPlugins/e2openplugin-OpenWebif
Depends: python-json, python-cheetah, python-pyopenssl, python-unixadmin, python-misc, python-twisted-web, python-pprint, python-compression, python-ipaddress, python-six (>= 1.14)
Source: https://github.com/E2OpenPlugins/e2openplugin-OpenWebif
EOF

mkdir -p ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/
cp -rp ${D}/plugin/* ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/
for f in $(find ./locale -name *.po ); do
	l=$(echo ${f%} | sed 's/\.po//' | sed 's/.*locale\///')
	mkdir -p ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/locale/${l%}/LC_MESSAGES
	msgfmt -o ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/locale/${l%}/LC_MESSAGES/OpenWebif.mo ./locale/$l.po
done

if [ "$1" == "vti" ]; then

	# Nur die Vu+ und OW-Remotes ins IPK kopieren.
	pushd ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/public/images/remotes
	mkdir x
	mv ow_remote.png vu* x/
	rm -f *.*
	mv x/* .
	rm -fr x

	# Nur die Vu+ box images ins IPK kopieren.
	cd ../boxes
	mkdir x
	mv vu* x/
	rm -f *.*
	mv x/* .
	rm -fr x

	# Nur die Templates für Vu+ Remotes ins IPK kopieren
	cd ../../static/remotes
	mkdir x
	mv vu_* x/
	rm -f *.*
	mv x/* .
	rm -fr x

	popd

fi

cheetah-compile -R ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/
python -O -m compileall ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/

if [ "$1" == "novxg" ]; then
	rm -rf ${P}/usr/lib/enigma2/python/Plugins/Extensions/OpenWebif/public/vxg/
fi

tar -C ${P} -czf ${B}/data.tar.gz . --exclude=CONTROL
tar -C ${P}/CONTROL -czf ${B}/control.tar.gz .

echo "2.0" > ${B}/debian-binary

cd ${B}
ls -la
ar -r ${PKG} ./debian-binary ./data.tar.gz ./control.tar.gz 

cd -

rm -rf ${P}
rm -rf ${B}
