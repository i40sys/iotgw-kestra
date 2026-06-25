#!/bin/bash

rm install_packages_version.txt install_packages_noversion.txt
while read -r line; do
    pkg_name=$(echo "$line" | cut -d ' ' -f 1)
    pkg_version=$(echo "$line" | cut -d ' ' -f 3)
    echo ${pkg_name}=${pkg_version} >> install_packages_version.txt
    echo ${pkg_name} >> install_packages_noversion.txt
done < installed_packages.txt
