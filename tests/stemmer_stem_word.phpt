--TEST--
stemmer_stem_word
--SKIPIF--
<?php if(!extension_loaded('stemmer')) die('skip '); ?>
--FILE--
<?php
var_dump(stemmer_stem_word('birds', 'english', 'UTF_8'));
var_dump(stemmer_stem_word(array('birds', 'words', 123), 'english', 'UTF_8'));
var_dump(stemmer_stem_word('birds', 'not-a-language', 'UTF_8'));
var_dump(stemmer_stem_word(array('birds'), 'not-a-language', 'UTF_8'));
var_dump(stemmer_stem_word('birds', 'english', 'not-an-encoding'));
var_dump(stemmer_stem_word('', 'english', 'UTF_8'));
var_dump(stemmer_stem_word(123, 'english', 'UTF_8'));
var_dump(stemmer_stem_word(array('first' => 'birds', 9 => 'words'), 'english', 'UTF_8'));

$binaryScalar = stemmer_stem_word("\0", 'english', 'UTF_8');
$binaryArray = stemmer_stem_word(array("\0"), 'english', 'UTF_8');
var_dump(strlen($binaryScalar), bin2hex($binaryScalar));
var_dump(strlen($binaryArray[0]), bin2hex($binaryArray[0]));
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
NULL
NULL
NULL
string(0) ""
string(3) "123"
array(2) {
  [0]=>
  string(4) "bird"
  [1]=>
  string(4) "word"
}
int(1)
string(2) "00"
int(1)
string(2) "00"
