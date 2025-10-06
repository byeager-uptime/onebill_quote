# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains XSL-FO templates for generating PDF quotes from OneBill billing system XML data for Uptime VoIP services.

## Key Files

- **template10071.xsl** - Main XSL-FO template that transforms OneBill quote XML into formatted PDF estimates
- **template10071.xsl.backup** - Backup of original template before redesign
- **contract_terms.txt** - Legal terms and conditions content (plain text source)
- **OneBill Developer Guide.postman_collection (1).json** - OneBill API documentation with XML structure examples
- **Uptime-VoIP-MSA.md** - Complete Master Services Agreement template (reference only, not used in quotes)

## XSL Template Architecture

### XML Data Structure
The template expects OneBill quote XML with the following critical paths:
- `/quote/quoteBusinsessProfile/` - **Note: Contains intentional typo** (not "quoteBusinessProfile"). This matches production OneBill XML schema. Do NOT "fix" this typo.
- `/quote/quoteSubscriberProfile/` - Customer billing information
- `/quote/quoteLineItems/` - Product line items with nested charge details
- `/quote/quoteLineItems/quoteChargeDetails[eventType='REC']` - Monthly recurring charges
- `/quote/quoteLineItems/quoteChargeDetails[eventType='ONE_TIME']` - One-time charges
- `/quote/quoteLineItems[bundleElementName!='']` - Bundle items
- `/quote/quoteLineItems/quoteAddOnLineItems/` - Add-on products

### Design Requirements
- **Brand color**: #214761 (navy blue) - used for headers and accents
- **Date format**: mm/dd/yyyy (US format)
- **Contact info**: 989-402-4026 | 5444 N Coleman RD, STE D, Coleman MI 48618 | uptimevoip.co | help@uptimevoip.co
- **Header layout**: Logo left, "ESTIMATE" label right with quote number and date
- **Single page sequence** - Original template had duplicate page sequences causing blank pages

### Key Technical Patterns

**Tax Grouping via XSL Keys:**
```xml
<xsl:key name="quoteReclineItems-by-description"
         match="quoteChargeDetails[eventType='REC']/taxLineItem/lineItems[taxAmount!=0]"
         use="description" />
```
Used to consolidate duplicate tax descriptions across line items.

**invoiceDescription Logic:**
Always prefer `invoiceDescription` when present, fall back to `productName` + `pricePlanName`:
```xml
<xsl:choose>
  <xsl:when test="../invoiceDescription">
    <fo:block font-weight="bold"><xsl:value-of select="../invoiceDescription"/></fo:block>
  </xsl:when>
  <xsl:otherwise>
    <fo:block font-weight="bold"><xsl:value-of select="../productName"/></fo:block>
    <fo:block font-size="8pt" color="#666666"><xsl:value-of select="../pricePlanName"/></fo:block>
  </xsl:otherwise>
</xsl:choose>
```

**Date Formatting:**
Converts ISO date (YYYY-MM-DD) to US format (mm/dd/yyyy):
```xml
<xsl:value-of select="concat(substring(/quote/quoteCreatedDate, 6, 2), '/',
                             substring(/quote/quoteCreatedDate, 9, 2), '/',
                             substring(/quote/quoteCreatedDate, 1, 4))"/>
```

**Contract Term Dynamic Insertion:**
```xml
<xsl:value-of select="/quote/contractTerm"/>
```
Replaces placeholder `{{contractterm}}` from contract_terms.txt with actual quote data.

## Terms and Conditions

The complete terms are hardcoded in the XSL template (lines 585-700) and sourced from `contract_terms.txt`. This includes:
- Sections 1-10 with all subsections
- Proper formatting with `fo:block` elements and spacing
- Font size 7pt for body, 9pt for section headers
- Bold headers with navy blue color

**Important:** If legal terms need updating, modify `contract_terms.txt` first, then manually copy the formatted content into the XSL template's terms section. XSLT 1.0 cannot dynamically read external text files.

## Common Modifications

### Updating Brand Colors
Change the `$uptime_blue` variable at the top of template10071.xsl.

### Modifying Contact Information
Update footer static content (lines 96-104) with new address, phone, email, or website.

### Adding New Quote Fields
1. Identify the XML path from OneBill Developer Guide or existing template
2. Add `<xsl:value-of select="/quote/path/to/field"/>` at appropriate location
3. Ensure proper formatting with `fo:block` and styling attributes

### Testing Changes
Generate a quote through OneBill system after template modifications. There is no local XSL-FO processor in this repository - testing requires the production OneBill environment.

## Important Notes

- **NEVER change `quoteBusinsessProfile` to `quoteBusinessProfile`** - this typo matches production XML
- Always maintain single page-sequence (do not add additional `<fo:page-sequence>` elements)
- Keep backup before major template changes
- Date format is mm/dd/yyyy (US), not dd/mm/yyyy (international)
- All monetary amounts use the `dollar` decimal format with thousands separators
- Multi-page quotes use `keep-together.within-page="always"` for table rows to prevent orphaned content
