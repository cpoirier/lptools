<meta>
 <title>Hello, World for lptools</title>
 <keywords>lptools, Hello World</keywords>
</meta>

<section>
<title>Introduction</title>

<note>Read the README first!!!</note>

This example is intended to demonstrate the basic features of the lptools suite,
including [[lpcc]], [[lproots]], [[lpdoc]], and [[build]].  

This file is a valid lp file, and contains this discussion, (written in an 
arbitrary XML schema), the literate source for a [[c]] hello world program, 
and a discussion of the [[Buildfile]] used to build it.

<note>The full documentation for the literate programming environment is 
available by running [[lphelp]], and most of that information will not be
repeated here.</note>

<note>The full documentation for the build system is available by running
[[build --help]], and most of that information will not be repeated here.</note>

</section>




<section>
<title>Hello, World</title>

So far, we have used only text blocks in this example.  In fact, to this point,
there is only one text block.  

Let's change that now.

@-block language=c; main() skeleton
@-------------------------------------------------------------------------------
int main( void )
{
   {{main() body}}
}

@-

The above block is a code block (because it specifies a [[language]]).  It 
ends where the next block starts, which occurs on a line that starts with 
either one of [[@-]] or [[@-block]].

The [[main()]] function references another block, [[main() body]], which will
be expanded in place of the reference when the code is assembled by [[lpcc]]
(called transclusion).


@-block language=c; main() body
@-------------------------------------------------------------------------------
/* {{main() body description}} */

printf( "Hello, world\n" );

{{a final point}}


@-block main() body description 
@-------------------------------------------------------------------------------
Outputs the phrase "Hello, world",
followed by a newline.            
@-

When [[lpcc]] transcludes a block, it copies the text that brackets the 
reference onto each line of the transcluded block.  The reference in 
[[main() skeleton]] to [[main() body]] is indented 3 spaces, and so will be the 
contents of [[main() body]] when [[lpcc]] assembles the output.  The reference 
to [[main() body description]] from [[main() body]] is enclosed in the [[c]] 
comment marker, and so will be the description text when it is transcluded.

As you may have guessed, transclusion is recursive: [[main()]] will look 
like this, when assembled by [[lpcc]] (the code here is actually pasted from
the output [[lpcc]] created for [[hello-world.c]] (below).

@-block language=c++; fully assembled main() 
@-------------------------------------------------------------------------------
int main( void )
{
   /* Outputs the phrase "Hello, world", */
   /* followed by a newline.             */
   
   printf( "Hello, world\n" );
   
   if( 1 < 2 )  return 10; 
}

@-

This last block makes demonstrates a useful point: you don't have to use every
block you define -- [[fully assembled main()]] is never transcluded anywhere.

Note also that, while our example is all in one file, it could just as easily 
have been spread across multiple files.  In fact, a block in file [[A]] can 
reference a block in file [[B]] that references a block in file [[C]] that 
references a different block in file [[A]], and [[lpcc]] will still correctly 
assemble the code.  


In [[main() body]], there is a reference to [[a final point]], which is defined
below this paragraph.  It is present just to prove a point: when [[lpdoc]]
assembles this file into [[XML]] documentation, the embedded less-than signs
(<), both here and in the code block, will automatically be converted to 
[[XML]] entities.

@-block language=c; a final point
@-------------------------------------------------------------------------------
if( 1 < 2 )  return 10; 
@-


<section>
<title>Assembly</title>

We have one more thing to do.  We must assemble our "hello world" program into
something that can be compiled.  We do that with a code block that is marked
a [[root]].

@-block root=; language=c; hello-world.c
@-------------------------------------------------------------------------------
#include <stdio.h>

{{main() skeleton}}

@-

</section> <!-- Assembly -->

</section>





<section>
<title>Build Scripts<title>

This example ships with two files: 
<list type="numbered">
 <li>this file ([[hello-world.lp]])</li>
 <li>the instructions to the [[build]] system ([[Buildfile]])</li>
</list>

The Buildfile will not normally be a literate program, unless you are 
okay with running [[lpcc]] yourself to generate it sometime before invoking
[[build]].  But we do just that for this example -- the copy of [[Buildfile]] 
included with this example was created from this file.


<section>
<title>Basic [[Buildfile]]</title>

In most cases, you will not need to put everything in your [[Buildfile]], as
we do here, but will instead use separate libraries of [[build]] instructions
that you will simply [[(include)]] in your [[Buildfile]].

This block defines the "local" information for building our targets, and 
transcludes the rest of the instructions from below.  Note that it is also a
root code block.

@-block root=; language=build; Buildfile
@-------------------------------------------------------------------------------
{{root descriptions}}
{{hello-world descriptions}}
{{documentation descriptions}}


(-- Define our raw sources )

(def-sources hello-world.lp)


(-- Provide a target for cleaning up everything but Buildfile )

(def-macro clean 
   (do
      (each $file (get-alias @all-targets)
         (if (not (wildcard $file Buildfile)) (delete $file))
      )
   )
)

@-

</section> <!-- Basic [[Buildfile]] -->



<section>
<title>Build framework</title>


The following code tells the [[build]] system how to discover what roots can
be built from an [[lp]] source file, and how to build them (with [[lpcc]]).
The production describes what can be built, and the action describes how to
build it.  

Note that the action suppresses line directives in the output of [[lpcc]].
This is necessary because we are generating all files with one set of rules,
and [[Buildfile]] can't have line directives. 


@-block language=build; root descriptions
@-------------------------------------------------------------------------------
(def-production lpcc 0 *.lp (pipe-in lproots $source))
(def-action each lpcc (system lpcc --root=$target-file --output=$target 
                                   --disable-line-directives $source)
)

@-




We also need to tell [[build]] how to build [[hello-world]] from the generated
[[c]] sources.  As above, the production describes what can be built, and the
action describes how to build it.  The only real difference in structure here
is that this action is an [[all]] action, while the previous was an [[each]]
action.  [[all]] actions can accept multiple sources for one target.  [[each]] 
actions can accept only one source for each target.


@-block language=build; hello-world descriptions
@-------------------------------------------------------------------------------
(def-production cc 0 *.c hello-world)
(def-action all cc (system gcc -o $target $sources))

@-




And finally, we tell [[build]] how to generate documentation from the lp 
sources.

@-block language=build; documentation descriptions
@-------------------------------------------------------------------------------
(def-production lpdoc 0 *.lp *.xml)
(def-action each lpdoc (system lpdoc --output=$target $source))


@-
</section> <!-- Build framework -->

</section> <!-- The Buildfile -->
