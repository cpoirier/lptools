<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                              xmlns="http://www.w3.org/TR/REC-html40" 
                              xmlns:lp="http://tapestry-os.org/tools/lp/doc">




<!--
=============================================================================================================
==
== href( label, url, target )
==   outputs an <a href> tag
==
==   label:  the label for the link
==   url:    the destination url for the link
==   target: the target window name 
==
=============================================================================================================
-->

<xsl:template name="href"
  ><xsl:param name="label"
 /><xsl:param name="url"
 /><xsl:param name="target"

 /><a
   ><xsl:attribute name="href"><xsl:value-of select="$url"/></xsl:attribute
   ><xsl:attribute name="target"><xsl:value-of select="$target"/></xsl:attribute
   ><xsl:apply-templates select="$label"
 /></a
></xsl:template> 




<!--
=============================================================================================================
==
== anchor( name )
==   outputs an <a name> tag
==
==   name:   the anchor name 
==
=============================================================================================================
-->

<xsl:template name="anchor"><xsl:param name="name"/><a><xsl:attribute name="name"><xsl:value-of select="$name"/></xsl:attribute></a></xsl:template> 



<!--
=============================================================================================================
==
== Miscellaneous HTMLisms.
==
=============================================================================================================
-->

<xsl:template match="em"><b><xsl:apply-templates/></b></xsl:template>
<xsl:template match="b"><b><xsl:apply-templates/></b></xsl:template>
<xsl:template match="i"><i><xsl:apply-templates/></i></xsl:template>




<!--
=============================================================================================================
==
== Useful macros
== 
=============================================================================================================
-->

<xsl:template name="em-dash"><xsl:text disable-output-escaping="yes">&amp;#151;</xsl:text></xsl:template>
<xsl:template name="nbsp"><xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text></xsl:template>

<xsl:template name="nbsps">
 <xsl:param name="repeats"/>

 <xsl:if test="$repeats > 0">
  <xsl:call-template name="nbsp"/>
  <xsl:call-template name="nbsps">
   <xsl:with-param name="repeats"><xsl:value-of select="$repeats - 1"/></xsl:with-param>
  </xsl:call-template>
 </xsl:if>
</xsl:template>




</xsl:stylesheet>
