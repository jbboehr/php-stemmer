--TEST--
Stemmer - Snowball corpus
--SKIPIF--
<?php
if (!extension_loaded('stemmer')) {
    die('skip stemmer extension is not loaded');
}

$corpusDir = getenv('STEMMER_CORPUS_DIR');
if ($corpusDir === false || $corpusDir === '') {
    die('skip STEMMER_CORPUS_DIR is not configured');
}
?>
--FILE--
<?php
function openCorpusFile(string $directory, string $name): array
{
    $path = $directory . '/' . $name . '.txt';
    if (is_file($path)) {
        $handle = fopen($path, 'rb');
        if ($handle === false) {
            throw new RuntimeException('Unable to open ' . $path);
        }

        return [$handle, false];
    }

    $path .= '.gz';
    if (is_file($path)) {
        if (!extension_loaded('zlib')) {
            throw new RuntimeException('zlib is required to read the gzipped Snowball corpus');
        }

        $handle = gzopen($path, 'rb');
        if ($handle === false) {
            throw new RuntimeException('Unable to open ' . $path);
        }

        return [$handle, true];
    }

    throw new RuntimeException('Missing corpus file ' . $directory . '/' . $name . '.txt[.gz]');
}

function readCorpusLine($handle, bool $compressed)
{
    return $compressed ? gzgets($handle) : fgets($handle);
}

function closeCorpusFile($handle, bool $compressed): void
{
    if ($compressed) {
        gzclose($handle);
    } else {
        fclose($handle);
    }
}

function testCorpusBatch(string $language, array $words, array $expected, int $firstLine): void
{
    $actual = stemmer_stem_word($words, $language, 'UTF_8');
    if (!is_array($actual) || count($actual) !== count($expected)) {
        throw new RuntimeException($language . ' corpus batch returned an unexpected result');
    }

    foreach ($expected as $offset => $expectedStem) {
        if ($actual[$offset] !== $expectedStem) {
            throw new RuntimeException(sprintf(
                '%s corpus mismatch on line %d: %s stemmed to %s; expected %s',
                $language,
                $firstLine + $offset,
                var_export($words[$offset], true),
                var_export($actual[$offset], true),
                var_export($expectedStem, true)
            ));
        }
    }

    $lastOffset = count($words) - 1;
    $sampleOffsets = $lastOffset === 0 ? [0] : [0, $lastOffset];
    foreach ($sampleOffsets as $offset) {
        $scalarStem = stemmer_stem_word($words[$offset], $language, 'UTF_8');
        if ($scalarStem !== $expected[$offset]) {
            throw new RuntimeException(sprintf(
                '%s scalar corpus mismatch on line %d: %s stemmed to %s; expected %s',
                $language,
                $firstLine + $offset,
                var_export($words[$offset], true),
                var_export($scalarStem, true),
                var_export($expected[$offset], true)
            ));
        }
    }
}

$corpusDir = getenv('STEMMER_CORPUS_DIR');
if (!is_dir($corpusDir)) {
    throw new RuntimeException('STEMMER_CORPUS_DIR is not a directory: ' . $corpusDir);
}

$availableLanguages = array_fill_keys(stemmer_languages(), true);
$knownUnsupportedLanguages = array_fill_keys(['german2', 'kraaij_pohlmann', 'lovins'], true);
$testedLanguages = 0;
$testedWords = 0;

foreach (scandir($corpusDir) as $language) {
    $languageDir = $corpusDir . '/' . $language;
    if ($language[0] === '.' || !is_dir($languageDir)) {
        continue;
    }

    $hasVocabulary = is_file($languageDir . '/voc.txt') || is_file($languageDir . '/voc.txt.gz');
    $hasOutput = is_file($languageDir . '/output.txt') || is_file($languageDir . '/output.txt.gz');
    if (!$hasVocabulary && !$hasOutput) {
        continue;
    }
    if (!$hasVocabulary || !$hasOutput) {
        throw new RuntimeException('Incomplete corpus data for ' . $language);
    }

    if (!isset($availableLanguages[$language])) {
        if (!isset($knownUnsupportedLanguages[$language])) {
            throw new RuntimeException('libstemmer does not provide the corpus language ' . $language);
        }
        continue;
    }

    [$wordHandle, $wordCompressed] = openCorpusFile($languageDir, 'voc');
    [$outputHandle, $outputCompressed] = openCorpusFile($languageDir, 'output');
    $words = [];
    $expected = [];
    $line = 0;
    $firstLine = 1;

    while (true) {
        $wordLine = readCorpusLine($wordHandle, $wordCompressed);
        $outputLine = readCorpusLine($outputHandle, $outputCompressed);
        if ($wordLine === false && $outputLine === false) {
            break;
        }
        if ($wordLine === false || $outputLine === false) {
            throw new RuntimeException('Corpus files have different lengths for ' . $language);
        }

        ++$line;
        $words[] = rtrim($wordLine, "\r\n");
        $expected[] = rtrim($outputLine, "\r\n");

        if (count($words) === 5000) {
            testCorpusBatch($language, $words, $expected, $firstLine);
            $testedWords += count($words);
            $words = [];
            $expected = [];
            $firstLine = $line + 1;
        }
    }

    if ($words !== []) {
        testCorpusBatch($language, $words, $expected, $firstLine);
        $testedWords += count($words);
    }

    closeCorpusFile($wordHandle, $wordCompressed);
    closeCorpusFile($outputHandle, $outputCompressed);
    ++$testedLanguages;
}

if ($testedLanguages !== 29 || $testedWords !== 11019345) {
    throw new RuntimeException(sprintf(
        'Expected 29 languages and 11019345 words; tested %d languages and %d words',
        $testedLanguages,
        $testedWords
    ));
}

$marker = getenv('STEMMER_CORPUS_MARKER');
if ($marker !== false && $marker !== '' && !touch($marker)) {
    throw new RuntimeException('Unable to record that the Snowball corpus test passed');
}

echo "OK (29 languages, 11019345 words)\n";
?>
--EXPECT--
OK (29 languages, 11019345 words)
