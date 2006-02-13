#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../ppport.h"

#define NUMLANG 12
#define NUMSTEM 24

#include "include/libstemmer.h"

typedef struct sb_stemmer SnowStemmer;

typedef struct stemmifier {
    SnowStemmer **stemmers;
} Stemmifier;

typedef struct langenc {
    char *lang;
    char *encoding; /* the real name of the encoding */
    char *snowenc;  /* the variant that libstemmer_c needs */
} LangEnc;

LangEnc lang_encs[] = {
    { "da", "ISO-8859-1", "ISO_8859_1" },
    { "de", "ISO-8859-1", "ISO_8859_1" },
    { "nl", "ISO-8859-1", "ISO_8859_1" },
    { "en", "ISO-8859-1", "ISO_8859_1" },
    { "es", "ISO-8859-1", "ISO_8859_1" },
    { "fi", "ISO-8859-1", "ISO_8859_1" },
    { "fr", "ISO-8859-1", "ISO_8859_1" },
    { "it", "ISO-8859-1", "ISO_8859_1" },
    { "no", "ISO-8859-1", "ISO_8859_1" },
    { "pt", "ISO-8859-1", "ISO_8859_1" },
    { "ru", "KOI8-R",     "KOI8_R",    },
    { "sv", "ISO-8859-1", "ISO_8859_1" },
    { "da", "UTF-8",      "UTF_8"      },
    { "de", "UTF-8",      "UTF_8"      },
    { "nl", "UTF-8",      "UTF_8"      },
    { "en", "UTF-8",      "UTF_8"      },
    { "es", "UTF-8",      "UTF_8"      },
    { "fi", "UTF-8",      "UTF_8"      },
    { "fr", "UTF-8",      "UTF_8"      },
    { "it", "UTF-8",      "UTF_8"      },
    { "no", "UTF-8",      "UTF_8"      },
    { "pt", "UTF-8",      "UTF_8"      },
    { "ru", "UTF-8",      "UTF_8"      },
    { "sv", "UTF-8",      "UTF_8"      },
};

MODULE = Lingua::Stem::Snowball  PACKAGE = Lingua::Stem::Snowball

PROTOTYPES: disable 

void
_derive_stemmer(obj_hash)
    HV *obj_hash;
PREINIT:
    char  *lang;
    char  *encoding;
    SV   **sv_ptr;
    int i;
    int stemmer_id;
PPCODE:
    /* extract lang and encoding member variables */
    sv_ptr = hv_fetch(obj_hash, "lang", 4, 0);
    if (!sv_ptr)
        croak("Couldn't find member variable 'lang'");
    lang = SvPV_nolen(*sv_ptr);
    sv_ptr = hv_fetch(obj_hash, "encoding", 8, 0);
    if (!sv_ptr)
        croak("Couldn't find member variable 'encoding'");
    encoding = SvPV_nolen(*sv_ptr);

    /* see if the combo of lang and encoding is supported */
    stemmer_id = -1;
    for(i = 0; i < NUMSTEM; i++) {
        if (   strcmp(lang,     lang_encs[i].lang)     == 0 
            && strcmp(encoding, lang_encs[i].encoding) == 0 
        ) {
            IV          temp;
            Stemmifier *stemmifier;
            SV         *stemmifier_sv;

            /* we have a match, so we know the stemmer id now */
            stemmer_id = i;

            /* retrieve communal Stemmifier */
            stemmifier_sv 
                = get_sv("Lingua::Stem::Snowball::stemmifier", TRUE);
            if (!SvROK(stemmifier_sv)) {
                croak("Internal error: can't access stemmifier");
            }
            temp = SvIV(SvRV(stemmifier_sv));
            stemmifier = INT2PTR(Stemmifier*, temp);

            /* construct a stemmer for lang/enc if there isn't one yet */
            if ( ! stemmifier->stemmers[stemmer_id] ) {
                stemmifier->stemmers[stemmer_id] 
                    = sb_stemmer_new(lang, lang_encs[stemmer_id].snowenc);
                if ( ! stemmifier->stemmers[stemmer_id]  ) {
                    croak("Failed to allocate an sb_stemmer - out of mem");
                }
            } 

            break;
        }
    }

    /* set the value of $self->{stemmer_id} */
    sv_ptr = hv_fetch(obj_hash, "stemmer_id", 10, 0);
    if (!sv_ptr)
        croak("Couldn't access $self->{stemmer_id}");
    sv_setiv(*sv_ptr, stemmer_id);

bool
_validate_language(lang_sv)
    SV *lang_sv;
PREINIT:
    char   *lang;
    STRLEN  len;
    int     i;
CODE:
    lang = SvPV(lang_sv, len);

    RETVAL = FALSE;
    for (i = 0; i < NUMLANG; i++) {
        if ( strcmp(lang, lang_encs[i].lang) == 0 )
            RETVAL = TRUE;
    }
OUTPUT: RETVAL


void
stemmers(...)
PREINIT:
    SV  *lang_sv;
    int  i;
PPCODE:
    for (i = 0; i < NUMLANG; i++) {
        XPUSHs( sv_2mortal(
            newSVpvn( lang_encs[i].lang, strlen(lang_encs[i].lang) )
        ));
    }
    XSRETURN(NUMLANG);

void
stem_in_place(obj, words_av)
    SV  *obj;
    AV  *words_av;
PREINIT:
    HV                *obj_hash;
    SV               **sv_ptr;
    IV                 stemmer_id;
    SV                *stemmifier_sv;
    Stemmifier        *stemmifier;
    char              *word_ptr;
    STRLEN             len;
    SnowStemmer       *stemmer;
    const sb_symbol   *input_text;
    const sb_symbol   *stemmed_output;
    IV                 i, max;
PPCODE:
    /* extract hash from object */
    if (SvROK(obj) && SvTYPE(SvRV(obj))==SVt_PVHV)
        obj_hash = (HV*)SvRV(obj);
    else    
        croak("not a hash reference");

    /* retrieve the stemmifier */
    stemmifier_sv = get_sv("Lingua::Stem::Snowball::stemmifier", TRUE);
    if(!SvROK(stemmifier_sv))
        croak("$Lingua::Stem::Snowball::stemmifier isn't a Stemmifier");
    i = SvIV(SvRV(stemmifier_sv));
    stemmifier = INT2PTR(Stemmifier*, i);

    /* figure out which sb_stemmer to use */
    sv_ptr = hv_fetch(obj_hash, "stemmer_id", 10, 0);
    if (!sv_ptr)
        croak("Couldn't access stemmer_id");
    stemmer_id = SvIV(*sv_ptr);
    if (   stemmer_id < 0 
        || stemmer_id >= NUMSTEM 
        || stemmifier->stemmers[stemmer_id] == NULL
    ) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(obj);
        PUTBACK;
        call_method("_derive_stemmer", G_DISCARD);
        FREETMPS;
        LEAVE;
    
        /* extract what should now be a valid stemmer_id */
        sv_ptr = hv_fetch(obj_hash, "stemmer_id", 10, 0);
        stemmer_id = SvIV(*sv_ptr);
    }
	if (stemmer_id != -1) {
		stemmer = stemmifier->stemmers[stemmer_id];

		max = av_len(words_av);
		for (i = 0; i <= max; i++) {
			sv_ptr = av_fetch(words_av, i, 0);
			if (!SvOK(*sv_ptr))
				continue;
			input_text     = (const sb_symbol*)SvPV(*sv_ptr, len);
			stemmed_output = sb_stemmer_stem(stemmer, input_text, (int)len);
			len = sb_stemmer_length(stemmer);
			sv_setpvn(*sv_ptr, (char*)stemmed_output, len);
		}
	}

MODULE = Lingua::Stem::Snowball PACKAGE = Lingua::Stem::Snowball::Stemmifier

=for comment

Create a new Stemmifier object.

=cut

SV*
new(class)
    char* class;
PREINIT:
    Stemmifier *stemmifier;
PPCODE:
    New(0, stemmifier, 1, Stemmifier);
    Newz(0, stemmifier->stemmers, NUMSTEM, SnowStemmer*);
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), class, (void*)stemmifier);
    XSRETURN(1);

void
DESTROY(obj_ref)
    SV *obj_ref;
PREINIT:
    Stemmifier *stemmifier;
    IV          temp;
    int         i;
PPCODE:
    temp = SvIV( SvRV(obj_ref) );
    stemmifier = INT2PTR(Stemmifier*, temp);
    for (i = 0; i < NUMSTEM; i++) {
        if (stemmifier->stemmers[i] != NULL)
            sb_stemmer_delete(stemmifier->stemmers[i]);
    }
    Safefree(stemmifier);
    
    
    
