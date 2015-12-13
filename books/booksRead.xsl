<?xml version="1.0" encoding="UTF-8"?>
<!---<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/TR/xhtml1/strict"> -->
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:strip-space elements="Tagline"/>
<xsl:output method="html"/>
<xsl:template match="/">
	<html>
	<head>
		<title>Books I've Read</title>
		<script src="sorttable.js"></script>
		<style type="text/css">
		/* Sortable tables */
		table.sortable thead {
			background-color:#eee;
			color:#666666;
			font-weight: bold;
			cursor: default;
		}
		th {
			text-decoration: underline;
		}
		</style>
	</head>
	<body onload="sorttable.init()">
		<xsl:apply-templates select="freefour"/>
	</body>
	</html>
</xsl:template>

<xsl:template match="freefour">
<table border="1" class="sortable">
	<thead>
		<tr>
		<th class="sorttable_alpha">Title</th>
		<th>Author</th>
		<th>Date Read</th>
		<th>Pages</th>
		<th>ISBN</th>
		</tr>
	</thead>
	<xsl:apply-templates select="book">
		<xsl:sort select="Date" order="descending"/>
	</xsl:apply-templates>
	</table>
</xsl:template>

<xsl:template match="book">
	<tr>
		<td><xsl:value-of select="Title"/><xsl:apply-templates select="Tagline"/></td>
		<td>
			<xsl:attribute name="sorttable_customkey">
				<xsl:value-of select="AuthorL"/><xsl:value-of select="AuthorF"/><xsl:value-of select="Date"/>
			</xsl:attribute>
			<xsl:value-of select="AuthorF"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="AuthorL"/>
		</td>
		<!-- <td><xsl:value-of select="Date"/></td> !-->
		<td align="right"><xsl:apply-templates select="Date"/></td>
		<td align="right"><xsl:apply-templates select="Pages"/></td>
		<td align="right"><xsl:apply-templates select="ISBN"/></td>
	</tr>
</xsl:template>

<xsl:template match="Pages">
	<xsl:choose>
	  <xsl:when test=". = 0">
		?
	  </xsl:when>
	  <xsl:otherwise>
		<xsl:value-of select="."/>
	  </xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="Tagline">
	<xsl:if test="string(.)">: <xsl:value-of select="."/></xsl:if>
</xsl:template>

<xsl:template match="Date">
	<xsl:call-template name="FormatDate">
		<xsl:with-param name="DateTime" select="."/>
	</xsl:call-template>
</xsl:template>


<xsl:template name="FormatDate">
	<xsl:param name="DateTime" />
	<!-- old date format 2006-01-14 -->
	<!-- new date format 01/14/2006 -->
	<xsl:variable name="year">
		<xsl:value-of select="substring($DateTime,0,5)" />
	</xsl:variable>
	<xsl:variable name="month">
		<xsl:value-of select="substring($DateTime,6,2)" />
	</xsl:variable>
	<xsl:variable name="day">
		<xsl:value-of select="substring($DateTime,9,2)" />
	</xsl:variable>
	<xsl:if test="$month != 00">
		<xsl:value-of select="$month"/>
		<xsl:value-of select="'/'"/>
	</xsl:if>
	<xsl:if test="$day != 00">
		<xsl:value-of select="$day"/>
		<xsl:value-of select="'/'"/>
	</xsl:if>
	<xsl:if test="$year != 00">
		<xsl:value-of select="$year"/>
	</xsl:if>
	<xsl:if test="$year = 00">
		?
	</xsl:if>
</xsl:template>

</xsl:transform>