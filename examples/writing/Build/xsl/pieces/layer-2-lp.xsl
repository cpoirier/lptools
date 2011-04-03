<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                              xmlns="http://www.w3.org/TR/REC-html40" 
                              xmlns:lp="http://tapestry-os.org/tools/lp/doc">



<!--
=============================================================================================================
==
== Output <lp:identifier> contents in monospace.
==
=============================================================================================================
-->

<xsl:template match="lp:identifier"><code><xsl:apply-templates/></code></xsl:template>




<!--
=============================================================================================================
==
== Appropriately convert <lp:ref> tags to hypertext.
== 
=============================================================================================================
-->

<xsl:template match="lp:ref">
  <xsl:call-template name="href">
   <xsl:with-param name="label" select="child::node()"/>
   <xsl:with-param name="url"><xsl:value-of select="@file"/><xsl:if test="@name">#<xsl:value-of select="@name"/></xsl:if></xsl:with-param>
  </xsl:call-template>
</xsl:template>




<!--
=============================================================================================================
==
== Convert <lp:block> tags into a div with the block name converted to a css class.
== 
=============================================================================================================
-->

<xsl:template match="lp:block[@name]">
  <div>
    <xsl:attribute name="class"><xsl:value-of select="@name"/></xsl:attribute>
    <xsl:apply-templates/>
  </div>
</xsl:template>





<!--
=============================================================================================================
==
== Convert <lp:p> tags into <p> tags.  HTML considers lists to be peers, not children,
== of paragraphs.  In order to simulate lists inside paragraphs, we have to alter
== the style of the paragraph to eliminate the paragraph's bottom margin.
== 
=============================================================================================================
-->

<xsl:template match="lp:p | p"
  ><p
    ><xsl:if test="./list[@type='bullet'] or ./list[@type='numbered']"
      ><xsl:attribute name="style">margin-bottom: 0pt;</xsl:attribute
    ></xsl:if
    ><xsl:apply-templates
 /></p
></xsl:template>




<!--
=============================================================================================================
==
== Output the various types of lists: bullet, numbered, and inline.
== 
=============================================================================================================
-->

<xsl:template match="list[@type='bullet']">
 <xsl:variable name="separator"><xsl:choose><xsl:when test="@separator"><xsl:value-of select="@separator"/></xsl:when><xsl:otherwise>;</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="terminator"><xsl:choose><xsl:when test="@terminator"><xsl:value-of select="@terminator"/></xsl:when><xsl:otherwise>.</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="join"><xsl:choose><xsl:when test="@join"><xsl:value-of select="@join"/></xsl:when><xsl:otherwise>and</xsl:otherwise></xsl:choose></xsl:variable>

 <!-- HTML does not allow lists inside paragraphs.  lp:p tags are converted to HTML paragraphs, -->
 <!-- so if the list is inside an lp:p, we must end the HTML paragraph and start a new one      -->
 <!-- after.  The lp:p template ensures the paragraph "before" is correctly styled (no bottom   -->
 <!-- margin).  We do the same for any paragraphs we create.                                    -->
 
 <xsl:if test="name(parent::node())='lp:p' or name(parent::node())='p'">
  <xsl:text disable-output-escaping="yes">&lt;/p></xsl:text>
 </xsl:if>
 

 <ul>
  <xsl:for-each select="li">
   <li>
    <xsl:apply-templates/>
    <xsl:choose>
     <xsl:when test="position() = last()"><xsl:value-of select="$terminator"/> </xsl:when>
     <xsl:otherwise><xsl:value-of select="$separator"/> </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position() + 1 = last()"><xsl:text> </xsl:text><xsl:value-of select="$join"/></xsl:if>
   </li>
  </xsl:for-each>
 </ul>


 <!-- See comments above.  -->

 <xsl:if test="name(parent::node())='lp:p' or name(parent::node())='p'">
  <xsl:text disable-output-escaping="yes">&lt;p style="margin-top: 0pt;"></xsl:text>
 </xsl:if>

</xsl:template>



<xsl:template match="list[@type='numbered']">
 <xsl:variable name="separator"><xsl:choose><xsl:when test="@separator"><xsl:value-of select="@separator"/></xsl:when><xsl:otherwise>;</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="terminator"><xsl:choose><xsl:when test="@terminator"><xsl:value-of select="@terminator"/></xsl:when><xsl:otherwise>.</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="join"><xsl:choose><xsl:when test="@join"><xsl:value-of select="@join"/></xsl:when><xsl:otherwise>and</xsl:otherwise></xsl:choose></xsl:variable>

 <!-- HTML does not allow lists inside paragraphs.  lp:p tags are converted to HTML paragraphs, -->
 <!-- so if the list is inside an lp:p, we must end the HTML paragraph and start a new one      -->
 <!-- after.  The lp:p template ensures the paragraph "before" is correctly styled (no bottom   -->
 <!-- margin).  We do the same for any paragraphs we create.                                    -->
 
 <xsl:if test="name(parent::node())='lp:p' or name(parent::node())='p'">
  <xsl:text disable-output-escaping="yes">&lt;/p></xsl:text>
 </xsl:if>
 

 <ol>
  <xsl:for-each select="li">
   <li>
    <xsl:apply-templates/>
    <xsl:choose>
     <xsl:when test="position() = last()"><xsl:value-of select="$terminator"/> </xsl:when>
     <xsl:otherwise><xsl:value-of select="$separator"/> </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position() + 1 = last()"><xsl:text> </xsl:text><xsl:value-of select="$join"/></xsl:if>
   </li>
  </xsl:for-each>
 </ol>


 <!-- See comments above.  -->

 <xsl:if test="name(parent::node())='lp:p' or name(parent::node())='p'">
  <xsl:text disable-output-escaping="yes">&lt;p style="margin-top: 0pt;"></xsl:text>
 </xsl:if>

</xsl:template>


<xsl:template match="list[@type='inline']">
 <xsl:variable name="separator"><xsl:choose><xsl:when test="@separator"><xsl:value-of select="@separator"/></xsl:when><xsl:otherwise>;</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="terminator"><xsl:choose><xsl:when test="@terminator"><xsl:value-of select="@terminator"/></xsl:when><xsl:otherwise>.</xsl:otherwise></xsl:choose></xsl:variable>
 <xsl:variable name="join"><xsl:choose><xsl:when test="@join"><xsl:value-of select="@join"/></xsl:when><xsl:otherwise>and</xsl:otherwise></xsl:choose></xsl:variable>

 <xsl:for-each select="li">
  <xsl:apply-templates/>
  <xsl:choose>
   <xsl:when test="position() = last()"><xsl:value-of select="$terminator"/><xsl:text> </xsl:text></xsl:when>
   <xsl:otherwise><xsl:value-of select="$separator"/><xsl:text> </xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:if test="position() + 1 = last()"><xsl:text> </xsl:text><xsl:value-of select="$join"/><xsl:text> </xsl:text></xsl:if>
 </xsl:for-each>
</xsl:template>




</xsl:stylesheet>
