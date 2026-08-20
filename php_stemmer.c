#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "Zend/zend_smart_str.h"
#include "ext/standard/info.h"
#include "php_stemmer.h"
#include "stemmer_arginfo.h"
#include "libstemmer.h"

static PHP_MINFO_FUNCTION(stemmer)
{
    const char **list = sb_stemmer_list();
    const char **ptr;
    smart_str language_list = {0};

    // Make a list of supported languages
    for (ptr = list; *ptr != NULL; ptr++) {
        if (language_list.s != NULL) {
            smart_str_appendc(&language_list, ' ');
        }
        smart_str_appends(&language_list, *ptr);
    }
    smart_str_0(&language_list);

    // Print the table now
    php_info_print_table_start();
    php_info_print_table_row(2, "Version", PHP_STEMMER_VERSION);
    php_info_print_table_row(2, "Released", PHP_STEMMER_RELEASE);
    php_info_print_table_row(2, "License", PHP_STEMMER_LICENSE);
    php_info_print_table_row(2, "Authors", PHP_STEMMER_AUTHORS);
    php_info_print_table_row(2, "Languages", language_list.s != NULL ? ZSTR_VAL(language_list.s) : "");
    php_info_print_table_end();

    smart_str_free(&language_list);
}

zend_module_entry stemmer_module_entry = {
    STANDARD_MODULE_HEADER,
    PHP_STEMMER_EXTNAME,
    ext_functions,
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
    const char **list = sb_stemmer_list();
    const char **ptr;

    ZEND_PARSE_PARAMETERS_START(0, 0)
    ZEND_PARSE_PARAMETERS_END();

    array_init(return_value);
    for (ptr = list; *ptr != NULL; ptr++) {
        add_next_index_string(return_value, *ptr);
    }
}

PHP_FUNCTION(stemmer_stem_word)
{
    zval *arg;
    zend_string *lang;
    zend_string *enc;
    HashTable *arr_hash;
    const sb_symbol *stemmed = NULL;
    struct sb_stemmer *stemmer;

    ZEND_PARSE_PARAMETERS_START(3, 3)
        Z_PARAM_ZVAL(arg)
        Z_PARAM_STR(lang)
        Z_PARAM_STR(enc)
    ZEND_PARSE_PARAMETERS_END();

    stemmer = sb_stemmer_new(ZSTR_VAL(lang), ZSTR_VAL(enc));
    if (!stemmer) {
        RETURN_NULL();
    }

    if (Z_TYPE_P(arg) == IS_ARRAY) {
        array_init(return_value);
        arr_hash = Z_ARRVAL_P(arg);
        zval *data;
        ZEND_HASH_FOREACH_VAL(arr_hash, data)
        {
            if (Z_TYPE_P(data) == IS_STRING) {
                stemmed = sb_stemmer_stem(stemmer, (const sb_symbol *) Z_STRVAL_P(data), Z_STRLEN_P(data));
                if (stemmed) {
                    add_next_index_stringl(return_value, (const char *) stemmed, sb_stemmer_length(stemmer));
                } else {
                    add_next_index_null(return_value);
                }
            } else {
                add_next_index_null(return_value);
            }
        }
        ZEND_HASH_FOREACH_END();
    } else {
        convert_to_string(arg);
        stemmed = sb_stemmer_stem(stemmer, (const sb_symbol *) Z_STRVAL_P(arg), Z_STRLEN_P(arg));
        if (stemmed) {
            RETVAL_STRINGL((const char *) stemmed, sb_stemmer_length(stemmer));
        }
    }
    sb_stemmer_delete(stemmer);
}
