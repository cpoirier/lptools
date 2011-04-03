<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/TR/REC-html40" xmlns:lp="http://tapestry-os.org/tools/lp/doc">

<!--
=============================================================================================================
==
== The ellipsis is handled as a tag to minimize the cost of changing its formatting.
==
=============================================================================================================
-->

<xsl:template name="ellipsis-dot">
 <xsl:param name="count"/>
 <xsl:param name="lead" select="false()"/>

 <xsl:if test="boolean($lead)"><xsl:call-template name="nbsp"/></xsl:if>
 <xsl:text>.</xsl:text>
 <xsl:if test="$count &gt; 1">
  <xsl:call-template name="nbsp"/> 
  <xsl:call-template name="ellipsis-dot">

   <xsl:with-param name="count" select="$count - 1"/>
  </xsl:call-template>
 </xsl:if>
</xsl:template>

<xsl:template match="ell">
 <xsl:call-template name="ellipsis-dot">
  <xsl:with-param name="count" select="3"/>
  <xsl:with-param name="lead"  select="true()"/>
 </xsl:call-template>
</xsl:template>

<xsl:template match="ell-e">
 <xsl:call-template name="ellipsis-dot">
  <xsl:with-param name="count" select="4"/>
 </xsl:call-template>
</xsl:template>



<!--
=============================================================================================================
==
== Miscellaneous other writing tags.
==
=============================================================================================================
-->

<xsl:template match="m-"><xsl:call-template name="em-dash"/></xsl:template>

<xsl:template match="em"><i><xsl:apply-templates/></i></xsl:template>
<xsl:template match="t"><i><xsl:apply-templates/></i></xsl:template>
<xsl:template match="t/em"><xsl:text disable-output-escaping="yes">&lt;/i&gt;</xsl:text><xsl:apply-templates/><xsl:text disable-output-escaping="yes">&lt;i&gt;</xsl:text></xsl:template>
<xsl:template match="book"><u><xsl:apply-templates/></u></xsl:template>

<xsl:template match="section"><xsl:apply-templates/><hr/></xsl:template>
<xsl:template match="section[position()=last()]"><xsl:apply-templates/></xsl:template>

<xsl:template match="section/summary"></xsl:template>
<xsl:template match="section/title"><p><b><xsl:apply-templates/></b></p></xsl:template>

<xsl:template match="ignore"></xsl:template>
<xsl:template match="chapters"></xsl:template>




<!--
=============================================================================================================
==
== Treatment blocks are to be ignored.
==
=============================================================================================================
-->

<xsl:template match="lp:block[@name='treatment']"></xsl:template>




<!--
=============================================================================================================
==
== Normal chapter or chapterless writing.
==
=============================================================================================================
-->
<xsl:template match="lp:doc">
<xsl:variable name="chapter-number"><xsl:value-of select="@CHAPTER"/></xsl:variable>
<xsl:variable name="chapter-title">
 <xsl:for-each select="chapters[position()=1]">
  <xsl:value-of select="chapter[position()=$chapter-number]"/>
 </xsl:for-each>
</xsl:variable>
<xsl:variable name="full-title">
 <xsl:value-of select="@TITLE"/><xsl:if test="@CHAPTER"> - <xsl:value-of select="@CHAPTER"/>. <xsl:value-of select="$chapter-title"/></xsl:if>
</xsl:variable>

<html>
<head>
<xsl:call-template name="css-stylesheets"/>
<link rel="up" type="text/html" href="index.html"></link>

<xsl:for-each select="chapters[position()=1]">
 <xsl:for-each select="chapter[position()=($chapter-number - 1)]">
  <link rel="prev" type="text/html">
   <xsl:attribute name="title"><xsl:value-of select="text()"/></xsl:attribute>
   <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
  </link>
 </xsl:for-each>

 <xsl:for-each select="chapter[position()=($chapter-number + 1)]">
  <link rel="next" type="text/html">
   <xsl:attribute name="title"><xsl:value-of select="text()"/></xsl:attribute>
   <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
  </link>
 </xsl:for-each>

 <link rel="contents" type="text/html" title="Table of Contents" href="index.html"></link>

 <xsl:for-each select="chapter">
  <xsl:variable name="number"><xsl:number level="single" format="1" count="chapter"/></xsl:variable>

  <link rel="section" type="text/html">
   <xsl:attribute name="title"><xsl:value-of select="text()"/></xsl:attribute>
   <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
  </link>
 </xsl:for-each>
</xsl:for-each>

<meta name="robots" content="noindex,nofollow,noarchive"></meta>
<title><xsl:value-of select="$full-title"/> (by <xsl:value-of select="@AUTHOR"/>)</title>
</head>
<body>

<table class="heading" width="100%" bgcolor="#FFFFCC" cellpadding="3pt" cellspacing="0pt">
<tr>
   <td class="name"><xsl:value-of select="$full-title"/></td>
   <td align="center">Copyright <xsl:value-of select="@YEAR"/><xsl:text> </xsl:text><xsl:value-of select="@AUTHOR"/></td>
   <td align="right">
     <xsl:choose>
       <xsl:when test="@CHAPTER"><a href="index.html">Table of Contents</a></xsl:when>
       <xsl:otherwise><a href="index.html">Up to Story Index</a></xsl:otherwise>
     </xsl:choose>
   </td>
</tr>
</table>

<xsl:if test="@STATUS != 'final'">
 <p class="status">Status: <xsl:value-of select="@STATUS"/> <xsl:call-template name="nbsps"><xsl:with-param name="repeats" select="5"/></xsl:call-template> Version: <xsl:value-of select="@VERSION"/></p>
</xsl:if>

<xsl:apply-templates/>


<xsl:for-each select="chapters[position()=1]">
  <hr class="chapter-links"/>

  <xsl:for-each select="chapter[position()=($chapter-number + 1)]">
    <p class="chapter-links">continue with <a>
     <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
     <xsl:apply-templates/>
    </a></p>
  </xsl:for-each>

  <xsl:for-each select="chapter[position()=($chapter-number - 1)]">
    <p class="chapter-links">back to <a>
     <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
     <xsl:apply-templates/>
    </a></p>
  </xsl:for-each>

  <p class="chapter-links">up to the <a href="index.html">Table of Contents</a></p>
</xsl:for-each>

</body>
</html>

</xsl:template>





<!--
=============================================================================================================
==
== Chapter table of contents.
==
=============================================================================================================
-->
<xsl:template match="lp:doc[@TOC]">
<html>
<head>
<xsl:call-template name="css-stylesheets"/>
<link rel="up" type="text/html" href="../index.html"></link>

<xsl:for-each select="chapters[position()=1]">
 <xsl:for-each select="chapter[position()=1]">
  <link rel="next" type="text/html">
   <xsl:attribute name="title"><xsl:value-of select="text()"/></xsl:attribute>
   <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
  </link>
 </xsl:for-each>

 <link rel="contents" type="text/html" title="Table of Contents" href="index.html"></link>

 <xsl:for-each select="chapter">
  <xsl:variable name="number"><xsl:number level="single" format="1" count="chapter"/></xsl:variable>

  <link rel="section" type="text/html">
   <xsl:attribute name="title"><xsl:value-of select="text()"/></xsl:attribute>
   <xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute>
  </link>
 </xsl:for-each>
</xsl:for-each>

<meta name="robots" content="noindex,nofollow,noarchive"></meta>
<title><xsl:value-of select="@TITLE"/> (by <xsl:value-of select="@AUTHOR"/>)</title>
</head>
<body>

<table class="heading" width="100%" bgcolor="#FFFFCC" cellpadding="3pt" cellspacing="0pt">
<tr>
   <td class="name"><xsl:value-of select="@TITLE"/></td>
   <td align="center">Copyright <xsl:value-of select="@YEAR"/><xsl:text> </xsl:text><xsl:value-of select="@AUTHOR"/></td>
   <td align="right"><a href="../index.html">Up to Story Index</a></td>
</tr>
</table>

<p><center><b>Table of Contents</b></center></p>

<ol>
<xsl:for-each select="chapters[position()=1]">
  <xsl:for-each select="chapter">
    <li><a><xsl:attribute name="href"><xsl:value-of select="@file"/>.html</xsl:attribute><xsl:apply-templates/></a></li>
  </xsl:for-each>
</xsl:for-each>
</ol>

</body>
</html>

</xsl:template>

</xsl:stylesheet>


