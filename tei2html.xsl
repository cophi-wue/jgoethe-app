<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exist="http://exist.sourceforge.net/NS/exist"
    version="1.0">

    <xsl:param name="onload"/>
    <xsl:param name="anchor"/>
    
    <xsl:template match="/">
        <html>
            <head>
                <link href="styles/teihtml.css" type="text/css" rel="stylesheet" />
            </head>
            <body
                onload="{$onload}"
                onunload="top.sectionUnloaded()"
				id="{page/@node-id}">
                <xsl:apply-templates/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="div">
        <div>
            <xsl:if test="@xml:id">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="*[starts-with(local-name(.), 'div')]">
        <!--a name="{@xml:id}" id="{@xml:id}"/-->
        <div class="div" id="{@xml:id}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="page//head[@type = 'toc']">
        <xsl:if test="not(following-sibling::head//text())">
            <div class="heading1">
                <xsl:apply-templates />
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="page[@num = '1']/head[not(@type = 'toc')]">
        <div class="heading1">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="page//head[not(@type = 'toc')]">
        <xsl:variable name="level" select="count(ancestor::div5 | ancestor::div4 | ancestor::div3 | ancestor::div2)"/>
        <div class="heading{$level + 1}">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="table">
        <table>
            <xsl:apply-templates />
        </table>
    </xsl:template>

    <xsl:template match="row">
        <tr>
            <xsl:apply-templates />
        </tr>
    </xsl:template>

    <xsl:template match="cell">
        <xsl:variable name="width" select="round(100 div count(parent::row/cell))"></xsl:variable>
        <td width="{$width}%">
            <xsl:apply-templates />
        </td>
    </xsl:template>

    <xsl:template match="ref">
        <xsl:if test="string-length(text()) &gt; 0">
            <span class="ref" onclick="top.loadById('{@target}');">
                <xsl:apply-templates/>
            </span>
        </xsl:if>
    </xsl:template>

    <xsl:template match="figure">
        <xsl:if test="@entity">
            <img src="figure.xql?id={@entity}"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="graphic">
        <img src="{@url}"/>
    </xsl:template>
    
    <xsl:template match="lb">
        <br />
    </xsl:template>

    <xsl:template match="hi">
        <em>
            <xsl:apply-templates />
        </em>
    </xsl:template>

    <xsl:template match="sp">
        <div class="sp">
            <xsl:if test="@xml:id = $anchor">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
                <a name="{@xml:id}"/>
            </xsl:if>
            <xsl:apply-templates select="speaker" />
            <xsl:apply-templates select="lg|l|p|stage" />
        </div>        
    </xsl:template>

    <xsl:template match="lg">
        <div class="lg">
            <xsl:if test="@xml:id = $anchor">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
                <a name="{@xml:id}" />
            </xsl:if>
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="l">
        <p class="l">
            <xsl:if test="@xml:id = $anchor">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
                <a name="{@xml:id}" />
            </xsl:if>
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="speaker">
        <p class="speaker">
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="stage">
        <p class="stage">
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <xsl:template match="anchor">
        <a name="{@xml:id}" />
    </xsl:template>

    <xsl:template match="p">
        <p>
            <xsl:if test="@xml:id = $anchor">
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
                <a name="{@xml:id}" />
            </xsl:if>
            <xsl:apply-templates />
        </p>
    </xsl:template>
    
    <xsl:template match="name">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="seg"/>
    
    <xsl:template match="note[@type = 'Bild']">
        <a href="javascript:top.displayFigure('{figure/@entity}');">
            <img src="images/camera.png"/>
        </a>
        <!--xsl:apply-templates select="figure"/-->
    </xsl:template>
    
    <xsl:template match="note">
        <xsl:variable name="ttid" select="generate-id(.)"/>
        <a href="#" id="{$ttid}" class="note">?</a>
        <span id="for_{$ttid}" class="note_overlay">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
  
    <xsl:template match="exist:match">
        <span class="highlight"><xsl:apply-templates/></span>
    </xsl:template>
</xsl:stylesheet>