#!/bin/bash

if [ "$1" = "deploy" ]; then
    docker cp $0 wordpress:/change_colours.sh
    docker exec wordpress bash /change_colours.sh
else
    if [ -d "/var/www/html/wp-content" ]; then
		cd /var/www/html/wp-content
		find . -type f -exec sed -i 's/3f729b/5E4A92/Ig' {} +
		find . -type f -exec sed -i 's/8bc34a/58B674/Ig' {} +
		find . -type f -exec sed -i 's/005a87/200F76/Ig' {} +
		find . -type f -exec sed -i 's/224f72/3B2B69/Ig' {} +
		find . -type f -exec sed -i 's/00897b/0F2C7B/Ig' {} +
	else
		echo "/var/www/html/wp-content doesn't exist"
	fi
fi
