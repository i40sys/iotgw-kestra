while read -r line; do
    pkg_name=$(echo $line | awk '{print $1}')
    pkg_version=$(echo $line | awk '{print $2}')
    opkg install ${pkg_name}=${pkg_version}
done < installed-packages.txt
