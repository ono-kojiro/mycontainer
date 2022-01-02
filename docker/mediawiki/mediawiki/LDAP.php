<?php

$LDAPProviderDomainConfigs = "/var/www/ldap.json";
$LDAPAuthentication2AllowLocalLogin = true;

$wgPluggableAuth_ButtonLabel = "Log In";

$wgDebugLogFile = "/var/log/mediawiki/debug-{$wgDBname}.log";

$wgLocaltimezone = "Asia/Tokyo";
date_default_timezone_set( $wgLocaltimezone );

