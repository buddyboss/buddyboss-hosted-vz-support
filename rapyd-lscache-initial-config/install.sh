#!/bin/bash

cd /var/www/webroot/ROOT/

# get the current list of all active plugins 
# we are going to use this later to skip all installed plugins apart for those we want to test
SKIPPLUGINS='^litespeed-cache$\|^object-cache-pro$\|^redis-cache$'
SKIPLIST=$(wp plugin list --status=active --field=name --quiet --skip-plugins 2>/dev/null | grep -v $SKIPPLUGINS | tr '\n' ',' )

# ┌──────────────────────────────────────────────────────────────────────────┐
# │ Make sure litespeed is installed & activate                              │
# └──────────────────────────────────────────────────────────────────────────┘

echo "checking is installed\n";
wp plugin is-installed litespeed-cache --quiet --skip-plugins 2>/dev/null

if [ "$?" -eq 0 ]
then
    wp plugin is-active litespeed-cache --quiet 2>/dev/null
	if [ $? -ne 0 ]; then
         echo "Activating LiteSpeed Plugin...\n"; 
    	 wp plugin activate litespeed-cache --quiet
    fi;
else
    echo "Installing LiteSpeed Plugin...\n"; 
    wp plugin install litespeed-cache --quiet;
fi


# ┌──────────────────────────────────────────────────────────────────────────┐
# │ Update the litespeed WordPress plugin to the latest version.             │
# └──────────────────────────────────────────────────────────────────────────┘


echo "Updating Litespeed plugin...\n";
wp plugin update litespeed-cache --quiet --skip-plugins="$SKIPLIST";
wp plugin activate litespeed-cache --quiet

# ┌──────────────────────────────────────────────────────────────────────────┐
# │ Configure litespeed for Rapyd!                                           │
# └──────────────────────────────────────────────────────────────────────────┘

# Delete existing LS Cache config
wp db query "DELETE FROM $(wp db prefix)_options WHERE option_name LIKE 'litespeed.%';"

wp litespeed-option set object false --quiet --skip-plugins="$SKIPLIST" 2>/dev/null  
wp litespeed-option set cache true --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-priv false --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-commenter false --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-rest false --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-page_login false --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-favicon true --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-resources true --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
wp litespeed-option set cache-mobile false  --quiet --skip-plugins="$SKIPLIST" 2>/dev/null    

# only update Do Not Cache URIs	fields when it's empty. get value & trim then.
cacheExc=$(wp litespeed-option get cache-exc | xargs);
if [ -z "$cacheExc" ]; then
   wp litespeed-option set cache-exc $'^/wp-admin\n ^/wp-json \n^/wp-login\n^/register' --quiet --skip-plugins="$SKIPLIST" 2>/dev/null
fi

wp litespeed-option set cache true --quiet --skip-plugins="$SKIPLIST" 2>/dev/null;

