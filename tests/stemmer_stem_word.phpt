--TEST--
stemmer_stem_word
--SKIPIF--
<?php if(!extension_loaded('stemmer')) die('skip '); ?>
--FILE--
<?php
var_dump(stemmer_stem_word('birds', 'english', 'UTF_8'));
var_dump(stemmer_stem_word(array('birds', 'words', 123), 'english', 'UTF_8'));
--EXPECT--
string(4) "bird"
array(3) {
  [0]=>
  string(4) "bird"
  [1]=>
  string(4) "word"
  [2]=>
  NULL
}

