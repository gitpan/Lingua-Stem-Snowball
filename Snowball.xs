#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "api.h"

typedef struct SN_env* (*SNCREATE)(void);
typedef void (*SNCLOSE)(struct SN_env *);
typedef int (*SNSTEM)(struct SN_env *);

typedef struct {
	char		*lang;
	struct SN_env 	*z;
	SNCREATE	init;
	SNCLOSE		close;
	SNSTEM		stem;
} STEM;

#include "config.c"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Lingua::Stem::Snowball               PACKAGE = Lingua::Stem::Snowball


double
constant(name,arg)
        char *          name
        int             arg

PROTOTYPES: DISABLE

int
get_stemmer_id(lang)
	char * lang
	CODE:
	int i;
	RETVAL=-1;
	for(i=0;i<NUMSTEM;i++)
		if ( strcmp(lang,stemmers[i].lang) == 0 ) {
			RETVAL = i;
			if ( ! stemmers[i].z ) {
				stemmers[i].z = (*stemmers[i].init)();
				if ( ! stemmers[i].z )
					RETVAL = -2;
			} 
		}
	OUTPUT:
	RETVAL

void
get_stemmer_list(out)
	SV *out;
	CODE:
	AV *ll = (AV*) SvRV(out);
	int i;

	for(i=0;i<NUMSTEM;i++)
		av_push(ll, newSVpv(stemmers[i].lang,strlen(stemmers[i].lang)) );

	OUTPUT:
	out

int
do_stem(id,word,lexem)
	int	id
	char *	word
	SV *	lexem
	CODE:
	int len = strlen(word);
	unsigned char *win = (unsigned char *)word;

	if ( id < 0 || id >= NUMSTEM || stemmers[id].z==NULL ) {
		RETVAL = -1;
	} else if ( len == 0 ) {
		RETVAL = -2;
	} else {
		int i;
		struct SN_env   *z = stemmers[id].z;

		for(i=0;i<len;i++)
			win[i] = tolower( (unsigned char)win[i] );
		SN_set_current(z, len, win);
		RETVAL = (*stemmers[id].stem)( z );
		if ( z->l && z->p )
			sv_setpvn( lexem, z->p, z->l ); 
	}
	OUTPUT:
	RETVAL
	lexem
