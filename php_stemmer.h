#ifndef PHP_STEMMER_PHP_H
#define PHP_STEMMER_PHP_H 1

#define PHP_STEMMER_VERSION "1.0.3"
#define PHP_STEMMER_RELEASE "2024-06-19"
#define PHP_STEMMER_LICENSE "BSD-3-Clause"
#define PHP_STEMMER_AUTHORS "© anno Domini nostri Jesu Christi 2008-2024 Javeline B.V., John Boehr, & contributors"
#define PHP_STEMMER_EXTNAME "stemmer"

PHP_FUNCTION(stemmer_languages);
PHP_FUNCTION(stemmer_stem_word);

extern zend_module_entry stemmmer_module_entry;
#define phpext_stemmer_ptr &stemmer_module_entry

#endif
