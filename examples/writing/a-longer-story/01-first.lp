@-set CHAPTER=1
@-set STATUS=in development
@-set VERSION=0
@-include headers.lp

@--------------------------------------------------------------------------<-----
<section>
<summary>A first chapter of a story.</summary>

In the beginning, some<ell/> interesting stuff happened.


@-block box
@-------------------------------------------------------------------------------
The [[XSLT]] for this example converts named blocks to &lt;div> tags, with the
name as the class.  It explicitly ignores blocks named "treatment", which are
treated as a "comment" block.

Note that this is a text block, as such, these paragraph looking things will
automatically be marked as such by [[lpdoc]].  But embedded [[XML]] tags won't
automatically be quoted; that only happens in code blocks.  See [[lphelp]] and
[[lpdoc --help]] for details.
@-

</section>
