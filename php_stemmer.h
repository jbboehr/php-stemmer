#ifndef PHP_STEMMER_PHP_H
#define PHP_STEMMER_PHP_H 1

#define PHP_STEMMER_VERSION "1.0.3"
#define PHP_STEMMER_EXTNAME "stemmer"

PHP_FUNCTION(stemmer_languages);
PHP_FUNCTION(stemmer_stem_word);

extern zend_module_entry stemmmer_module_entry;
#define phpext_stemmer_ptr &stemmer_module_entry

#endif
