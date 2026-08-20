/* This is a generated file, edit the .stub.php file instead.
 * Stub hash: 82a047834b2c94a309eae5a31774b6aa7a4836b0 */

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_stemmer_languages, 0, 0, IS_ARRAY, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_MASK_EX(arginfo_stemmer_stem_word, 0, 3, MAY_BE_ARRAY|MAY_BE_STRING|MAY_BE_NULL)
	ZEND_ARG_TYPE_INFO(0, arg, IS_MIXED, 0)
	ZEND_ARG_TYPE_INFO(0, lang, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, enc, IS_STRING, 0)
ZEND_END_ARG_INFO()


ZEND_FUNCTION(stemmer_languages);
ZEND_FUNCTION(stemmer_stem_word);


static const zend_function_entry ext_functions[] = {
	ZEND_FE(stemmer_languages, arginfo_stemmer_languages)
	ZEND_FE(stemmer_stem_word, arginfo_stemmer_stem_word)
	ZEND_FE_END
};
