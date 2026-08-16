--TEST--
stemmer arginfo
--SKIPIF--
<?php if(!extension_loaded('stemmer')) die('skip '); ?>
--FILE--
<?php
$languages = new ReflectionFunction('stemmer_languages');
var_dump($languages->getNumberOfParameters());
var_dump($languages->getNumberOfRequiredParameters());
var_dump((string) $languages->getReturnType());

$stemWord = new ReflectionFunction('stemmer_stem_word');
$returnTypes = array_map(
    static fn(ReflectionNamedType $type): string => $type->getName(),
    $stemWord->getReturnType()->getTypes()
);
sort($returnTypes);

var_dump($stemWord->getNumberOfParameters());
var_dump($stemWord->getNumberOfRequiredParameters());
var_dump($returnTypes);
--EXPECT--
int(0)
int(0)
string(5) "array"
int(3)
int(3)
array(3) {
  [0]=>
  string(5) "array"
  [1]=>
  string(4) "null"
  [2]=>
  string(6) "string"
}
