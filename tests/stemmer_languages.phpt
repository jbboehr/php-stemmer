--TEST--
stemmer_languages
--SKIPIF--
<?php if(!extension_loaded('stemmer')) die('skip '); ?>
--FILE--
<?php
$list = stemmer_languages();
var_dump(in_array('english', $list));
var_dump(in_array('german', $list));
--EXPECT--
bool(true)
bool(true)
