<?php

$baseDir = __DIR__ . '/snowball-data/';

//$disabledLanguages = array('lovins', 'kraaij_pohlmann', 'german2');

$languages = array();
foreach( scandir($baseDir) as $lang ) {
    if( $lang[0] === '.' || !is_dir($baseDir . $lang) ) {
        continue;
    }
    //if( !in_array($lang, $disabledLanguages) ) {
	    $languages[] = $lang;
    //}
}

$maxlen = 5000;

function test_head($fh, $lang, $index) {
    fwrite($fh, "--TEST--\n");
    fwrite($fh, "Stemmer - Snowball Data $lang #$index\n");
    fwrite($fh, "--SKIPIF--\n");
    fwrite($fh, "<" . "?" ."php \n");
    fwrite($fh, "if( !extension_loaded('stemmer') ) die('skip '); \n");
    fwrite($fh, "if( !in_array(" . var_export($lang, true) . ", stemmer_languages()) ) die('skip ');\n");
    fwrite($fh, "?" . ">\n");
}

function test_case($fh, $lang, $inputarr, $outputarr) {
    $charset = 'UTF_8';
    
    fwrite($fh, "--FILE--\n");
    fwrite($fh, "<" . "?" ."php\n");
    foreach( $inputarr as $line ) {
        fwrite($fh, ' echo stemmer_stem_word(' 
                . var_export($line, true) . ', ' 
                . var_export($lang, true) . ', ' 
                . var_export($charset, true) . '),"\n";' . "\n");
    }
    fwrite($fh, "--EXPECT--\n");
    foreach( $outputarr as $line ) {
        fwrite($fh, $line . "\n");
    }
}

function do_test($lang, $index, $inputarr, $outputarr) {
    $testFile = __DIR__ . '/tests/data-' . $lang . '-' . $index . '.phpt';
    if( file_exists($testFile) ) {
        unlink($testFile);
    }
    $fh = fopen($testFile, 'c');
    test_head($fh, $lang, $index);
    test_case($fh, $lang, $inputarr, $outputarr);
    fclose($fh);
    
    echo "Wrote ", $testFile, ", ", count($inputarr), " cases\n";
}

function mb_fgets($fh)
{
    $buf = '';
    $pos = false;
    $fstart = ftell($fh);
    while( !feof($fh) ) {
        $str = fread($fh, 256);
        if( $str === false ) {
            break;
        }
        $buf .= $str;
        $pos = mb_strpos($buf, "\n");
        if( $pos !== false ) {
            break;
        }
    }
    
    // Not found, return the rest of string
    if( $pos === false ) {
        return $buf ? $buf : false;
    }
    
    // Return up to and including the newline, and rewind the file descriptor
    $ret = mb_substr($buf, 0, $pos);
    fseek($fh, $fstart + $pos + 1, SEEK_SET);
    return $ret;
}


foreach( $languages as $lang ) {
    $langDir = $baseDir . $lang . '/';
    
    $fh2 = fopen($langDir . 'voc.txt', 'rb');
    $fh3 = fopen($langDir . 'output.txt', 'rb');
    if( !$fh2 || !$fh3 ) {
        exit(1);
    }
    
    // Now read inputfile
    $index = 0;
    $counter = 0;
    $inputarr = array();
    $outputarr = array();
    while( false !== ($buffer2 = mb_fgets($fh2)) &&
           false !== ($buffer3 = mb_fgets($fh3)) ) {
            // Write a test
            if( ++$counter >= $maxlen ) {
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
