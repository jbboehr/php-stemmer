#ifndef PHP_STEMMER_PHP_H
#define PHP_STEMMER_PHP_H 1

#define PHP_STEMMER_VERSION "2.0.0"
#define PHP_STEMMER_RELEASE "2026-08-20"
#define PHP_STEMMER_LICENSE "BSD-3-Clause"
#define PHP_STEMMER_AUTHORS "© anno Domini nostri Jesu Christi 2008-2026 Javeline B.V., John Boehr, & contributors"
#define PHP_STEMMER_EXTNAME "stemmer"

extern zend_module_entry stemmer_module_entry;
#define phpext_stemmer_ptr &stemmer_module_entry

#endif
