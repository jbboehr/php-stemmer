<?php

$baseDir = __DIR__ . '/snowball-data/';

$languages = array();
foreach( scandir($baseDir) as $lang ) {
    if( $lang[0] === '.' || !is_dir($baseDir . $lang) ) {
        continue;
    }
    $languages[] = $lang;
}

$maxlen = 500;

function test_head($fh, $lang, $index) {
    fwrite($fh, "--TEST--\n");
    fwrite($fh, "Snowball Data $lang #$index\n");
    fwrite($fh, "--SKIPIF--\n");
    fwrite($fh, "<" . "?" ."php if(!extension_loaded('stemmer')) die('skip '); " . "?" . ">\n");
}

function test_case($fh, $lang, $inputarr, $outputarr) {
    fwrite($fh, "--FILE--\n");
    fwrite($fh, "<" . "?" ."php\n");
    foreach( $inputarr as $line ) {
        fwrite($fh, ' echo stemword(' 
                . var_export(trim($line), true) . ', ' 
                . var_export(ltrim($lang, '2'), true) . ', ' 
                . '"UTF_8"),"\n";' . "\n");
    }
    fwrite($fh, "--EXPECT--\n");
    foreach( $outputarr as $line ) {
        fwrite($fh, $line);
    }
}

function do_test($lang, $index, $inputarr, $outputarr) {
    $testFile = __DIR__ . '/tests/data-' . $lang . '-' . $index . '.phpt';
    $fh = fopen($testFile, 'c');
    test_head($fh, $lang, $index);
    test_case($fh, $lang, $inputarr, $outputarr);
    fclose($fh);
    
    echo "Wrote ", $testFile, ", ", count($inputarr), " cases\n";
}

foreach( $languages as $lang ) {
    $langDir = $baseDir . $lang . '/';
    
    $fh2 = fopen($langDir . 'voc.txt', 'r');
    $fh3 = fopen($langDir . 'output.txt', 'r');
    if( !$fh2 || !$fh3 ) {
        exit(1);
    }
    
    // Now read inputfile
    $index = 0;
    $counter = 0;
    $inputarr = array();
    $outputarr = array();
    while( false !== ($buffer2 = fgets($fh2)) &&
           false !== ($buffer3 = fgets($fh3)) ) {
        // Write a test
        if( $counter++ > $maxlen ) {
            $counter = 0;
            $index++;
            do_test($lang, $index, $inputarr, $outputarr);
            $inputarr = array();
            $outputarr = array();
        }
        // Add to buf array
        $inputarr[] = $buffer2;
        $outputarr[] = $buffer3;
    }
    
    // Write expected
    if( !empty($inputarr) ) {
        $index++;
        do_test($lang, $index, $inputarr, $outputarr);
    }
    
    
    fclose($fh2);
    fclose($fh3);
}
