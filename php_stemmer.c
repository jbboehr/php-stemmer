#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "ext/standard/info.h"
#include "php_stemmer.h"
#include "libstemmer.h"

#define _add_next_index_string add_next_index_string


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

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO(stemmer_languages_args, IS_ARRAY, 0)
    ZEND_ARG_TYPE_INFO(0, data, IS_STRING, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO(stemmer_stem_word_args, IS_STRING, 1)
    ZEND_ARG_INFO(0, arg)
    ZEND_ARG_TYPE_INFO(0, lang, IS_STRING, 0)
    ZEND_ARG_TYPE_INFO(0, enc, IS_STRING, 0)
ZEND_END_ARG_INFO()

static zend_function_entry stemmer_functions[] = {
    PHP_FE(stemmer_languages, stemmer_languages_args)
    PHP_FE(stemmer_stem_word, stemmer_stem_word_args)
    PHP_FE_END
};

zend_module_entry stemmer_module_entry = {
    STANDARD_MODULE_HEADER,
    PHP_STEMMER_EXTNAME,
    stemmer_functions,
    NULL,
    NULL,
    NULL,
    NULL,
    PHP_MINFO(stemmer),
    PHP_STEMMER_VERSION,
    STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_STEMMER
ZEND_GET_MODULE(stemmer)
#endif

PHP_FUNCTION(stemmer_languages)
{
    const char ** list = sb_stemmer_list();
    const char ** ptr;

    ZEND_PARSE_PARAMETERS_START(0, 0)
    ZEND_PARSE_PARAMETERS_END();

    array_init(return_value);
    for( ptr = list ; *ptr != NULL; ptr++ ) {
        add_next_index_string(return_value, *ptr);
    }
}

PHP_FUNCTION(stemmer_stem_word)
{
    zval * arg;
    zend_string * lang;
    zend_string * enc;
    HashTable * arr_hash;
    HashPosition pointer;
    const sb_symbol * stemmed = "";
    struct sb_stemmer * stemmer;

    ZEND_PARSE_PARAMETERS_START(3, 3)
        Z_PARAM_ZVAL(arg)
        Z_PARAM_STR(lang)
        Z_PARAM_STR(enc)
    ZEND_PARSE_PARAMETERS_END();

    stemmer = sb_stemmer_new(ZSTR_VAL(lang), ZSTR_VAL(enc));
    if( !stemmer ) {
        RETURN_NULL();
    }
    
    if( Z_TYPE_P(arg) == IS_ARRAY ) {
        array_init(return_value);
        arr_hash = Z_ARRVAL_P(arg);
        zval * data;
        ZEND_HASH_FOREACH_VAL(arr_hash, data) {
            if( Z_TYPE_P(data) == IS_STRING ) {
                stemmed = sb_stemmer_stem(stemmer, Z_STRVAL_P(data), Z_STRLEN_P(data));
                _add_next_index_string(return_value, stemmed);
            } else {
                add_next_index_null(return_value);
            }
        } ZEND_HASH_FOREACH_END();
    } else {
        convert_to_string(arg);    
        stemmed = sb_stemmer_stem(stemmer, Z_STRVAL_P(arg), Z_STRLEN_P(arg));
        if( stemmed ) {
            RETVAL_STRING(stemmed);
        }
    }
    sb_stemmer_delete(stemmer);
}

