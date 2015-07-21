#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_stemmer.h"
#include "libstemmer.h"

#if PHP_MAJOR_VERSION < 7
#define _add_next_index_string(...) add_next_index_string(__VA_ARGS__, 1)
#define _RETVAL_STRING(a) RETVAL_STRING(a, 1)
#else
#define _add_next_index_string add_next_index_string
#define _RETVAL_STRING(a) RETVAL_STRING(a)
#endif

static PHP_MINFO_FUNCTION(stemmer)
{
  const char ** list = sb_stemmer_list();
  const char ** ptr;
  char language_list[256];
  size_t len = 0;

  // Make a list of supported languages
  language_list[0] = '\0';
  for( ptr = list ; *ptr != NULL; ptr++ ) {
    len += strlen(*ptr);
    strncat(language_list, *ptr, sizeof(language_list) - len - 1);
    len += 1;
    strncat(language_list, " ", sizeof(language_list) - len - 1);
  }
  language_list[len - 1] = '\0';

  // Print the table now
  php_info_print_table_start();
  php_info_print_table_row(2, "Version", PHP_STEMMER_VERSION);
  php_info_print_table_row(2, "Languages", language_list);
  php_info_print_table_end();
}

static zend_function_entry stemmer_functions[] = {
    PHP_FE(stemmer_languages, NULL)
    PHP_FE(stemmer_stem_word, NULL)
    {NULL, NULL, NULL}
};

zend_module_entry stemmer_module_entry = {
#if ZEND_MODULE_API_NO >= 20010901
    STANDARD_MODULE_HEADER,
#endif
    PHP_STEMMER_EXTNAME,
    stemmer_functions,
    NULL,
    NULL,
    NULL,
    NULL,
    PHP_MINFO(stemmer),
#if ZEND_MODULE_API_NO >= 20010901
    PHP_STEMMER_VERSION,
#endif
    STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_STEMMER
ZEND_GET_MODULE(stemmer)
#endif

PHP_FUNCTION(stemmer_languages)
{
    const char ** list = sb_stemmer_list();
    const char ** ptr;

    array_init(return_value);
    for( ptr = list ; *ptr != NULL; ptr++ ) {
        _add_next_index_string(return_value, *ptr);
    }
}

PHP_FUNCTION(stemmer_stem_word)
{
    zval * lang;
    zval * enc;
    zval * arg;
    HashTable * arr_hash;
    HashPosition pointer;
    const sb_symbol * stemmed = "";
    struct sb_stemmer * stemmer;
    
    if( zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "zzz", &arg, &lang, &enc) == FAILURE ) {
        RETURN_NULL();
    }

    convert_to_string(lang);
    convert_to_string(enc);

    stemmer = sb_stemmer_new(Z_STRVAL_P(lang), Z_STRVAL_P(enc));
    if( !stemmer ) {
        RETURN_NULL();
    }
    
    if( Z_TYPE_P(arg) == IS_ARRAY ) {
        array_init(return_value);
        arr_hash = Z_ARRVAL_P(arg);
#if PHP_MAJOR_VERSION < 7
        zval ** data;
        for( zend_hash_internal_pointer_reset_ex(arr_hash, &pointer);
                zend_hash_get_current_data_ex(arr_hash, (void **) &data, &pointer) == SUCCESS;
                zend_hash_move_forward_ex(arr_hash, &pointer) ) {
            if( Z_TYPE_PP(data) == IS_STRING ) {
                stemmed = sb_stemmer_stem(stemmer, Z_STRVAL_PP(data), Z_STRLEN_PP(data));
                _add_next_index_string(return_value, stemmed);
            } else {
                add_next_index_null(return_value);
            }
        }
#else
        zval * data;
        ZEND_HASH_FOREACH_VAL(arr_hash, data) {
            if( Z_TYPE_P(data) == IS_STRING ) {
                stemmed = sb_stemmer_stem(stemmer, Z_STRVAL_P(data), Z_STRLEN_P(data));
                _add_next_index_string(return_value, stemmed);
            } else {
                add_next_index_null(return_value);
            }
        } ZEND_HASH_FOREACH_END();
#endif
    } else {
        convert_to_string(arg);    
        stemmed = sb_stemmer_stem(stemmer, Z_STRVAL_P(arg), Z_STRLEN_P(arg));
        if( stemmed ) {
            _RETVAL_STRING(stemmed);
        }
    }
    sb_stemmer_delete(stemmer);
}

