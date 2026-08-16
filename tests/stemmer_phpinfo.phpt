--TEST--
stemmer phpinfo
--SKIPIF--
<?php if(!extension_loaded('stemmer')) die('skip '); ?>
--FILE--
<?php
ob_start();
phpinfo(INFO_MODULES);
$info = ob_get_clean();

var_dump(str_contains($info, 'Languages'));
var_dump(str_contains($info, 'english'));
--EXPECT--
bool(true)
bool(true)
