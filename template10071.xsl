<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:decimal-format name="dollar" decimal-separator="." grouping-separator="," />

	<!-- XSL Keys for tax grouping -->
	<xsl:key name="quoteOneTimeLineItems-by-description" match="quoteChargeDetails[eventType='ONE_TIME']/taxLineItem/lineItems[taxAmount!=0]" use="description" />
	<xsl:key name="quoteReclineItems-by-description" match="quoteChargeDetails[eventType='REC']/taxLineItem/lineItems[taxAmount!=0]" use="description" />

	<!-- Font family variable -->
	<xsl:variable name="font_family" select="'Arial, Helvetica, sans-serif'" />

	<!-- Uptime brand color -->
	<xsl:variable name="uptime_blue" select="'#214761'" />

	<!-- Helper template to remove minus symbol from negative amounts -->
	<xsl:template name="removeMinusSymbol">
		<xsl:param name="amount" />
		<xsl:choose>
			<xsl:when test="$amount >= 0">
				<xsl:value-of select="concat(' ',/quote/quoteBusinsessProfile/currencySymbol,format-number($amount,'#,##0.00','dollar'))" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(' ',/quote/quoteBusinsessProfile/currencySymbol,format-number($amount*-1,'#,##0.00','dollar'))" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Main template -->
	<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">

			<!-- Page Layout Definitions -->
			<fo:layout-master-set>
				<!-- First page layout with full header -->
				<fo:simple-page-master master-name="first-page" page-height="11in" page-width="8.5in"
					margin-left="0.5in" margin-right="0.5in" margin-top="0.4in" margin-bottom="0.4in">
					<fo:region-body margin-top="1.8in" margin-bottom="0.5in"/>
					<fo:region-before extent="1.8in" region-name="first-page-header"/>
					<fo:region-after extent="0.5in"/>
				</fo:simple-page-master>

				<!-- Rest pages layout with small logo only -->
				<fo:simple-page-master master-name="rest-page" page-height="11in" page-width="8.5in"
					margin-left="0.5in" margin-right="0.5in" margin-top="0.4in" margin-bottom="0.4in">
					<fo:region-body margin-top="0.75in" margin-bottom="0.5in"/>
					<fo:region-before extent="0.75in" region-name="rest-page-header"/>
					<fo:region-after extent="0.5in"/>
				</fo:simple-page-master>

				<!-- Page sequence master to switch between first and rest pages -->
				<fo:page-sequence-master master-name="estimate-pages">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference master-reference="first-page" page-position="first"/>
						<fo:conditional-page-master-reference master-reference="rest-page" page-position="rest"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>
			</fo:layout-master-set>

			<!-- Calculate totals -->
			<xsl:variable name="recGrossTotal" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='REC']/grossAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='REC']/grossAmount) + sum(/quote/quoteLineItems[bundleElementName!='']/netAmount)" />
			<xsl:variable name="recTotalDiscount" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='REC']/discountAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='REC']/discountAmount) + sum(/quote/quoteLineItems[bundleElementName!='']/discountAmount)" />
			<xsl:variable name="recTotalTax" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='REC']/taxAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='REC']/taxAmount) + sum(/quote/quoteLineItems[bundleElementName!='']/taxAmount)" />
			<xsl:variable name="recSubTotal" select="$recGrossTotal + $recTotalDiscount" />
			<xsl:variable name="recTotal" select="$recGrossTotal + $recTotalDiscount + $recTotalTax" />

			<xsl:variable name="nonRecGrossTotal" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='ONE_TIME']/grossAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='ONE_TIME']/grossAmount)" />
			<xsl:variable name="nonRecTotalTax" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='ONE_TIME']/taxAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='ONE_TIME']/taxAmount)" />
			<xsl:variable name="nonRecTotalDiscount" select="sum(/quote/quoteLineItems/quoteChargeDetails[eventType='ONE_TIME']/discountAmount) + sum(/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='ONE_TIME']/discountAmount)" />
			<xsl:variable name="nonRecSubTotal" select="$nonRecGrossTotal + $nonRecTotalDiscount" />
			<xsl:variable name="nonRecTotal" select="$nonRecGrossTotal + $nonRecTotalDiscount + $nonRecTotalTax" />

			<xsl:variable name="isRecurringPresent" select="/quote/quoteLineItems/quoteChargeDetails/eventType='REC' or /quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails/eventType='REC'" />
			<xsl:variable name="isNonRecurringPresent" select="/quote/quoteLineItems/quoteChargeDetails/eventType='ONE_TIME' or /quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails/eventType='ONE_TIME'" />
			<xsl:variable name="isBundlePresent" select="/quote/quoteLineItems/bundleElementName!=''" />

			<xsl:variable name="total" select="$recTotal + $nonRecTotal" />

			<!-- Page Sequence -->
			<fo:page-sequence master-reference="estimate-pages">

		<!-- First Page Header -->
		<fo:static-content flow-name="first-page-header">
			<fo:block border-after-style="solid" border-after-width="0.5pt" border-after-color="#CCCCCC" padding-after="5pt">
				<fo:table width="100%" table-layout="fixed" font-family="{$font_family}">
					<fo:table-column column-width="50%"/>
					<fo:table-column column-width="50%"/>
					<fo:table-body>
						<fo:table-row>
							<!-- Left: Logo + Contact Info -->
							<fo:table-cell display-align="before" padding="5pt">
								<fo:block>
									<fo:external-graphic src="url({/quote/quoteBusinsessProfile/businessImageUrl})"
										content-width="150px" content-height="scale-to-fit" scaling="uniform"/>
								</fo:block>
								<fo:block font-size="9pt" margin-top="8pt">
									sales@uptimevoip.co
								</fo:block>
								<fo:block font-size="9pt">
									855.402.VOIP (8647)
								</fo:block>
							</fo:table-cell>
							<!-- Right: Gray Box with Customer Info + ESTIMATE -->
							<fo:table-cell padding="5pt">
								<fo:block background-color="#E8E8E8" padding="10pt">
									<fo:block font-size="28pt" font-weight="bold" text-align="center" margin-bottom="8pt">
										ESTIMATE
									</fo:block>
									<fo:block font-weight="bold" font-size="11pt" text-align="center" margin-bottom="4pt">
										<xsl:value-of select="/quote/quoteSubscriberProfile/subscriberName"/>
									</fo:block>
									<fo:block font-size="9pt" text-align="center" margin-bottom="2pt">
										<xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/addLine1"/>
										<xsl:if test="/quote/quoteSubscriberProfile/billingAddress/addLine2 !=''">, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/addLine2"/></xsl:if>
										, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/city"/>, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/state"/>
										<xsl:text> </xsl:text>
										<xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/zip"/>
									</fo:block>
									<fo:block font-size="9pt" text-align="center" margin-bottom="8pt">
										<xsl:value-of select="/quote/createdByEmail"/>
									</fo:block>
									<fo:block font-size="10pt" font-weight="bold" text-align="center">
										Valid for 30 days from issue date
									</fo:block>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</fo:table-body>
				</fo:table>
			</fo:block>
		</fo:static-content>

		<!-- Rest Pages Header (small logo only) -->
		<fo:static-content flow-name="rest-page-header">
			<fo:block border-after-style="solid" border-after-width="0.5pt" border-after-color="#CCCCCC" padding-after="5pt">
				<fo:external-graphic src="url({/quote/quoteBusinsessProfile/businessImageUrl})"
					content-width="50px" content-height="scale-to-fit" scaling="uniform"/>
			</fo:block>
		</fo:static-content>

				<!-- Footer -->
				<fo:static-content flow-name="xsl-region-after">
					<fo:block font-size="8px" color="#666666" font-family="{$font_family}"
						border-top="0.5pt solid #CCCCCC" padding-top="5pt">
						<fo:table width="100%" table-layout="fixed">
							<fo:table-column column-width="50%"/>
							<fo:table-column column-width="50%"/>
							<fo:table-body>
								<fo:table-row>
									<fo:table-cell text-align="left">
										<fo:block>Uptime VoIP</fo:block>
										<fo:block>5444 N Coleman RD, STE D</fo:block>
										<fo:block>Coleman MI 48618</fo:block>
									</fo:table-cell>
									<fo:table-cell text-align="right">
										<fo:block>Phone: 989-402-4026</fo:block>
										<fo:block>Email: help@uptimevoip.co</fo:block>
										<fo:block>Web: uptimevoip.co</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
						<fo:block text-align="center" margin-top="3pt">Page <fo:page-number/> of <fo:page-number-citation ref-id="last-page"/></fo:block>
					</fo:block>
				</fo:static-content>

				<!-- Main Content -->
				<fo:flow flow-name="xsl-region-body">

					<!-- Monthly Fees Section -->
					<xsl:if test="$isRecurringPresent or $isBundlePresent">
						<fo:block margin-top="15pt" margin-bottom="10pt">
							<fo:block font-size="14pt" font-weight="bold" color="{$uptime_blue}" margin-bottom="8pt">
								Monthly Fees
							</fo:block>

							<fo:table width="100%" table-layout="fixed" font-family="{$font_family}" font-size="9pt"
								border="0.5pt solid #CCCCCC">
								<fo:table-column column-width="35%"/>
								<fo:table-column column-width="15%"/>
								<fo:table-column column-width="10%"/>
								<fo:table-column column-width="10%"/>
								<fo:table-column column-width="15%"/>
								<fo:table-column column-width="15%"/>

								<fo:table-header>
									<fo:table-row background-color="#F5F5F5" font-weight="bold">
										<fo:table-cell padding="6pt" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Description</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Unit Price</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Qty</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Term</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Discount</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Total</fo:block>
										</fo:table-cell>
									</fo:table-row>
								</fo:table-header>

								<fo:table-body>
									<!-- Recurring Line Items -->
									<xsl:for-each select="/quote/quoteLineItems/quoteChargeDetails[eventType='REC']">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell padding="6pt" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="../invoiceDescription">
															<fo:block font-weight="bold"><xsl:value-of select="../invoiceDescription"/></fo:block>
														</xsl:when>
														<xsl:otherwise>
															<fo:block font-weight="bold"><xsl:value-of select="../productName"/></fo:block>
															<fo:block font-size="8pt" color="#666666"><xsl:value-of select="../pricePlanName"/></fo:block>
														</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number(unitGrossAmount, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="format-number(../quantity,'#')"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="../term"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="not(discountAmount>=0)">
															<xsl:call-template name="removeMinusSymbol">
																<xsl:with-param name="amount"><xsl:value-of select="discountAmount"/></xsl:with-param>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>-</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:variable name="a" select="grossAmount"/>
													<xsl:variable name="b" select="discountAmount"/>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number($a + $b, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- Bundle Items -->
									<xsl:for-each select="/quote/quoteLineItems[bundleElementName!='']">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell padding="6pt" border-bottom="0.5pt solid #F0F0F0">
												<fo:block font-weight="bold"><xsl:value-of select="productName"/></fo:block>
												<fo:block font-size="8pt" color="#666666"><xsl:value-of select="pricePlanName"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number(grossAmount, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="format-number(quantity,'#')"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="term"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="not(discountAmount>=0)">
															<xsl:call-template name="removeMinusSymbol">
																<xsl:with-param name="amount"><xsl:value-of select="discountAmount"/></xsl:with-param>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>-</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:variable name="a" select="netAmount"/>
													<xsl:variable name="b" select="discountAmount"/>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number($a + $b, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- Recurring Add-ons -->
									<xsl:for-each select="/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='REC']">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell padding="6pt" border-bottom="0.5pt solid #F0F0F0">
												<fo:block font-weight="bold"><xsl:value-of select="../productName"/></fo:block>
												<fo:block font-size="8pt" color="#666666"><xsl:value-of select="../pricePlanName"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number(unitGrossAmount, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="format-number(../quantity,'#')"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="../term"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="not(discountAmount>=0)">
															<xsl:call-template name="removeMinusSymbol">
																<xsl:with-param name="amount"><xsl:value-of select="discountAmount"/></xsl:with-param>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>-</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:variable name="aa" select="grossAmount"/>
													<xsl:variable name="bb" select="discountAmount"/>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number($aa + $bb, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- Subtotal and Taxes -->
									<fo:table-row keep-together.within-page="always">
										<fo:table-cell number-columns-spanned="5" padding="6pt" text-align="right" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold">Subtotal:</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold">
												<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($recSubTotal, '#,##0.00','dollar'))"/>
											</fo:block>
										</fo:table-cell>
									</fo:table-row>

									<!-- Tax Line Items -->
									<xsl:for-each select=".//quoteChargeDetails/taxLineItem/lineItems[generate-id()=generate-id(key('quoteReclineItems-by-description', description)[1])]">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell number-columns-spanned="5" padding="6pt" text-align="right">
												<fo:block><xsl:value-of select="description"/>:</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number(sum(key('quoteReclineItems-by-description',description)/taxAmount), '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- Monthly Total -->
									<fo:table-row keep-together.within-page="always">
										<fo:table-cell number-columns-spanned="5" padding="8pt" text-align="right"
											background-color="#F5F5F5" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold" font-size="11pt">Monthly Fee Total:</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="8pt" text-align="right" background-color="#F5F5F5" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold" font-size="11pt">
												<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($recTotal, '#,##0.00','dollar'))"/>
											</fo:block>
										</fo:table-cell>
									</fo:table-row>
								</fo:table-body>
							</fo:table>
						</fo:block>
					</xsl:if>

					<!-- One-Time Fees Section -->
					<xsl:if test="$isNonRecurringPresent">
						<fo:block margin-top="15pt" margin-bottom="10pt">
							<fo:block font-size="14pt" font-weight="bold" color="{$uptime_blue}" margin-bottom="8pt">
								One-Time Charges
							</fo:block>

							<fo:table width="100%" table-layout="fixed" font-family="{$font_family}" font-size="9pt"
								border="0.5pt solid #CCCCCC">
								<fo:table-column column-width="35%"/>
								<fo:table-column column-width="15%"/>
								<fo:table-column column-width="10%"/>
								<fo:table-column column-width="10%"/>
								<fo:table-column column-width="15%"/>
								<fo:table-column column-width="15%"/>

								<fo:table-header>
									<fo:table-row background-color="#F5F5F5" font-weight="bold">
										<fo:table-cell padding="6pt" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Description</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Unit Price</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Qty</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Term</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Discount</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #CCCCCC">
											<fo:block>Total</fo:block>
										</fo:table-cell>
									</fo:table-row>
								</fo:table-header>

								<fo:table-body>
									<!-- One-Time Line Items -->
									<xsl:for-each select="/quote/quoteLineItems/quoteChargeDetails[eventType='ONE_TIME']">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell padding="6pt" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="../invoiceDescription">
															<fo:block font-weight="bold"><xsl:value-of select="../invoiceDescription"/></fo:block>
														</xsl:when>
														<xsl:otherwise>
															<fo:block font-weight="bold"><xsl:value-of select="../productName"/></fo:block>
															<fo:block font-size="8pt" color="#666666"><xsl:value-of select="../pricePlanName"/></fo:block>
														</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number(unitGrossAmount, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="format-number(../quantity,'#')"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="../term"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="not(discountAmount>=0)">
															<xsl:call-template name="removeMinusSymbol">
																<xsl:with-param name="amount"><xsl:value-of select="discountAmount"/></xsl:with-param>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>-</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:variable name="a" select="grossAmount"/>
													<xsl:variable name="b" select="discountAmount"/>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number($a + $b, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- One-Time Add-ons -->
									<xsl:for-each select="/quote/quoteLineItems/quoteAddOnLineItems/quoteChargeDetails[eventType='ONE_TIME']">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell padding="6pt" border-bottom="0.5pt solid #F0F0F0">
												<fo:block font-weight="bold"><xsl:value-of select="../productName"/></fo:block>
												<fo:block font-size="8pt" color="#666666"><xsl:value-of select="../pricePlanName"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number(unitGrossAmount, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="format-number(../quantity,'#')"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block><xsl:value-of select="../term"/></fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:choose>
														<xsl:when test="not(discountAmount>=0)">
															<xsl:call-template name="removeMinusSymbol">
																<xsl:with-param name="amount"><xsl:value-of select="discountAmount"/></xsl:with-param>
															</xsl:call-template>
														</xsl:when>
														<xsl:otherwise>-</xsl:otherwise>
													</xsl:choose>
												</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right" border-bottom="0.5pt solid #F0F0F0">
												<fo:block>
													<xsl:variable name="aa" select="grossAmount"/>
													<xsl:variable name="bb" select="discountAmount"/>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol, format-number($aa + $bb, '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- Subtotal and Taxes -->
									<fo:table-row keep-together.within-page="always">
										<fo:table-cell number-columns-spanned="5" padding="6pt" text-align="right" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold">Subtotal:</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="6pt" text-align="right" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold">
												<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($nonRecSubTotal, '#,##0.00','dollar'))"/>
											</fo:block>
										</fo:table-cell>
									</fo:table-row>

									<!-- Tax Line Items -->
									<xsl:for-each select=".//quoteChargeDetails/taxLineItem/lineItems[generate-id()=generate-id(key('quoteOneTimeLineItems-by-description', description)[1])]">
										<fo:table-row keep-together.within-page="always">
											<fo:table-cell number-columns-spanned="5" padding="6pt" text-align="right">
												<fo:block><xsl:value-of select="description"/>:</fo:block>
											</fo:table-cell>
											<fo:table-cell padding="6pt" text-align="right">
												<fo:block>
													<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number(sum(key('quoteOneTimeLineItems-by-description',description)/taxAmount), '#,##0.00','dollar'))"/>
												</fo:block>
											</fo:table-cell>
										</fo:table-row>
									</xsl:for-each>

									<!-- One-Time Total -->
									<fo:table-row keep-together.within-page="always">
										<fo:table-cell number-columns-spanned="5" padding="8pt" text-align="right"
											background-color="#F5F5F5" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold" font-size="11pt">One-Time Total:</fo:block>
										</fo:table-cell>
										<fo:table-cell padding="8pt" text-align="right" background-color="#F5F5F5" border-top="1pt solid #CCCCCC">
											<fo:block font-weight="bold" font-size="11pt">
												<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($nonRecTotal, '#,##0.00','dollar'))"/>
											</fo:block>
										</fo:table-cell>
									</fo:table-row>
								</fo:table-body>
							</fo:table>
						</fo:block>
					</xsl:if>

					<!-- Summary Totals Box -->
					<fo:block margin-top="20pt" keep-together.within-page="always">
						<fo:table width="100%" table-layout="fixed" font-family="{$font_family}"
							border="2pt solid {$uptime_blue}">
							<fo:table-column column-width="33.33%"/>
							<fo:table-column column-width="33.33%"/>
							<fo:table-column column-width="33.34%"/>
							<fo:table-body>
								<fo:table-row background-color="{$uptime_blue}">
									<fo:table-cell padding="8pt" text-align="center" border-right="1pt solid white">
										<fo:block font-weight="bold" color="white" font-size="10pt">One-Time Charges</fo:block>
									</fo:table-cell>
									<fo:table-cell padding="8pt" text-align="center" border-right="1pt solid white">
										<fo:block font-weight="bold" color="white" font-size="10pt">Monthly Fees</fo:block>
									</fo:table-cell>
									<fo:table-cell padding="8pt" text-align="center">
										<fo:block font-weight="bold" color="white" font-size="10pt">Total Due at Signup</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row>
									<fo:table-cell padding="10pt" text-align="center" border-right="0.5pt solid #CCCCCC">
										<fo:block font-size="16pt" font-weight="bold">
											<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($nonRecTotal, '#,##0.00','dollar'))"/>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell padding="10pt" text-align="center" border-right="0.5pt solid #CCCCCC">
										<fo:block font-size="16pt" font-weight="bold">
											<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($recTotal, '#,##0.00','dollar'))"/>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell padding="10pt" text-align="center" background-color="#F5F5F5">
										<fo:block font-size="18pt" font-weight="bold" color="{$uptime_blue}">
											<xsl:value-of select="concat(/quote/quoteBusinsessProfile/currencySymbol,format-number($total, '#,##0.00','dollar'))"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
					</fo:block>

					<!-- Notes Section -->
					<xsl:if test="/quote/note !=''">
						<fo:block margin-top="15pt" font-family="{$font_family}" font-size="9pt"
							background-color="#FFFACD" border="1pt solid #F0E68C" padding="8pt">
							<fo:block font-weight="bold" margin-bottom="4pt">Notes:</fo:block>
							<fo:block><xsl:value-of select="/quote/note"/></fo:block>
						</fo:block>
					</xsl:if>

					<!-- Terms and Conditions -->
					<fo:block margin-top="20pt" font-family="{$font_family}" font-size="7pt"
						border-top="1pt solid #CCCCCC" padding-top="10pt" keep-together.within-page="auto">
						<fo:block font-weight="bold" font-size="9pt" margin-bottom="8pt" color="{$uptime_blue}">
							Terms and Conditions
						</fo:block>
						<fo:block space-after="4pt">
							Orders are subject to the terms of your signed agreement with Uptime VoIP. All quotes must be paid in full by the electronic payment method on file before equipment can be ordered.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">1. Term And Termination Of Agreement</fo:block>
						<fo:block space-after="4pt">
							This Agreement is effective upon the date signed. Unless otherwise amended, this Agreement shall remain in force for the duration specified in your signed agreement beginning from the Activation Date. This Agreement may only be terminated by Client upon sixty (60) days written notice if UPTIME SERVICES CORPORATION (a) fails to fulfill in any material respect its obligations under this Agreement and does not cure such failure within thirty (30) days of receipt of such written notice, or (b) terminates or suspends its business operations, unless it is succeeded by a permitted assignee under this Agreement. This Agreement may be terminated by UPTIME SERVICES CORPORATION upon sixty (60) days written notice to Client. If either party terminates this Agreement, UPTIME SERVICES CORPORATION will assist Client in the orderly termination of services, including timely transfer of the services to another designated provider. Client agrees to pay UPTIME SERVICES CORPORATION the actual costs of rendering such assistance.
						</fo:block>
						<fo:block space-after="4pt">
							1.1 Activation Date shall be defined as the date your services are available for use with either a temporary or ported number. This does not require the installation of equipment or registration of any telephony devices. Billing of subscribed services will commence on the Activation Date. Use of the services by Client is not a requirement for services to considered active or billable.
						</fo:block>
						<fo:block space-after="4pt">
							1.2 Upon maturation of this agreement Client shall continue services on a month-to-month basis. Client may terminate services at any time with sixty (60) days written notice and without any penalty.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">2. Statements Of Service; Fees And Payments; Taxes</fo:block>
						<fo:block space-after="4pt">
							2.1 Statements of Service shall describe in detail the services to be performed by UPTIME SERVICES CORPORATION, and this Agreement hereby incorporates all attached and subsequent Statements of Service that refer specifically to this Agreement by name and date of execution, or the MSA Number.
						</fo:block>
						<fo:block space-after="4pt">
							2.2 Client will receive an invoice on a monthly basis, and it will become due and payable on the date of the invoice. Client shall have 15 calendar days until a late fee is assessed. Unless otherwise agreed in writing, Client is required to maintain an automated method of payment on file. This may be credit card or ACH. All services will be suspended if payment is not received within 30 days following the due date. Client will be billed a charge of $50 to re-establish service if payment or payment arrangements had not been arranged and agreed upon in writing prior to the service interruption.
						</fo:block>
						<fo:block space-after="4pt">
							2.3 It is understood that any applicable federal, state or local taxes shall be added to each invoice for services or materials rendered under this Agreement. Client shall pay all such taxes unless a valid exemption state certificate is furnished to UPTIME SERVICES CORPORATION.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">2.4 Early Termination Fee &amp; Minimum Commitment Fee</fo:block>
						<fo:block space-after="4pt">
							Client may reduce or augment services at any time during the Agreement. Client agrees that they shall not be liable for less than 50% of the original contracted service amount. If, for any reason, this Agreement is terminated prematurely by Client, UPTIME SERVICES CORPORATION reserves the right to assess an Early Termination Fee equal to 50% of the originally contracted services multiplied by the amount of remaining months in the original Agreement.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">3. Coverage</fo:block>
						<fo:block space-after="4pt">
							Unless modified by a Statement of Service associated with this agreement, all contracted services will be provided to Client by UPTIME SERVICES CORPORATION during working hours. UPTIME SERVICES CORPORATION will make reasonable efforts to respond to emergency requests. The hours of operation will be published at https://www.uptimevoip.co or other websites.
						</fo:block>
						<fo:block space-after="4pt">
							3.1 E911. UPTIME SERVICES CORPORATION is subject to FCC requirements to provide notifications of any E911 limitations that may be associated with UPTIME SERVICES CORPORATION's service. Such limitations and notices are made publicly available at https://www.uptimevoip.co/e911. Client agrees that they have reviewed and accept such limitations.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">4. Nondisclosure</fo:block>
						<fo:block space-after="4pt">
							4.1 Confidential Information. Except as provided in Section 4.2, as used in this Agreement, "Confidential Information" means any information furnished or disclosed, in whatever form or medium, by UPTIME SERVICES CORPORATION to Client relating to the business of UPTIME SERVICES CORPORATION, and includes, without limitation, contract terms, financial information, business procedures, processes, techniques, methods, ideas, discoveries, inventions, developments, records, product designs, source codes, product planning, trade secrets, customer lists, material samples, and the fact that UPTIME SERVICES CORPORATION and Client are negotiating or are parties to this Agreement, all of which is deemed confidential and proprietary.
						</fo:block>
						<fo:block space-after="4pt">
							4.2 Use of Confidential Information. UPTIME SERVICES CORPORATION and Client shall only use Confidential Information for the purpose of performing services under this Agreement, and shall make no use of the Confidential Information, in whole or in part, for any other purpose. Both parties agree to refrain from disclosing the Confidential Information to third parties, unless one of the parties has given its prior written authorization to the other. The parties further agree to take all reasonable steps to preserve the confidential and proprietary nature of the Confidential Information. However, if the parties are required by subpoena or other court order to disclose any of the Confidential Information, the party shall provide immediate notice of such request to the other party and shall use reasonable efforts to resist disclosure. If, in the absence of a protective order or the receipt of a waiver under this Agreement, the parties are legally required to disclose any Confidential Information, then the parties may disclose such information without liability under this Agreement.
						</fo:block>
						<fo:block space-after="4pt">
							4.3 Remedies for Breach of Nondisclosure. The Confidential Information protected by this Agreement is of a special character, such that money damages, although available, would not be sufficient to award or compensate for any unauthorized use or disclosure of the Confidential Information. The parties agree that injunctive and other equitable relief would be appropriate to prevent any such actual or threatened unauthorized use or disclosure.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">5. Ownership Of Work Product</fo:block>
						<fo:block space-after="4pt">
							5.1 General. All intellectual property rights associated with any ideas, concepts, techniques, processes or other work product created by UPTIME SERVICES CORPORATION during the course of performing the services shall belong exclusively to UPTIME SERVICES CORPORATION, and Client shall have no right or interest therein.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">6. Indemnity</fo:block>
						<fo:block space-after="4pt">
							6.1 Third Party Indemnification of UPTIME SERVICES CORPORATION. Client acknowledges that by entering into and performing its obligations under this Agreement and each Statement of Service, UPTIME SERVICES CORPORATION will not assume and shall not be exposed to the business and operational risks associated with Client's business, and Client therefore agrees to indemnify, defend and hold UPTIME SERVICES CORPORATION harmless from any and all third party claims, actions, damages, liabilities, costs and expenses (including attorneys' fees and expenses) arising out of or related to the conduct of Client's business except as a result of gross negligence on the part of UPTIME SERVICES CORPORATION.
						</fo:block>
						<fo:block space-after="4pt">
							6.2 Procedures. All indemnification obligations under this Section 6 shall be subject to the following requirements: (a) the indemnified party shall provide the indemnifying party with prompt written notice of any claim; (b) the indemnified party shall permit the indemnifying party to assume and control the defense of any action upon the indemnifying party's written acknowledgment of the obligation to indemnify (unless, in the opinion of counsel of the indemnified party, such assumption would result in a material conflict of interest); and (c) the indemnifying party shall not enter into any settlement or compromise of any claim without the indemnified party's prior written consent, which shall not be unreasonably withheld. In addition, the indemnified party may, at its own expense, participate in its defense of any claim. In the event that the indemnifying party assumes the defense of any such claim, the indemnifying party is not liable for attorney's fees and costs incurred by the indemnified party.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">7. Representation And Warranties</fo:block>
						<fo:block space-after="4pt">
							7.1 UPTIME SERVICES CORPORATION represents and warrants that it (a) has the right, power and authority to enter into the Agreement and to fully perform all of the obligations hereunder, (b) will use commercially reasonable efforts to provide all services required of it under the Agreement in accordance with prevailing industry standards, and (c) owns or has acquired the requisite rights from third parties to the UPTIME SERVICES CORPORATION property.
						</fo:block>
						<fo:block space-after="4pt">
							7.2 UPTIME SERVICES CORPORATION does not manufacture hardware or commercial off-the-shelf (COTS) software covered under this Agreement. Any warranty provisions are passed through from the manufacturer and are subject to the manufacturer's limitations. Any labor supplied by UPTIME SERVICES CORPORATION is not covered under the terms of the manufacturer's warranty.
						</fo:block>
						<fo:block space-after="4pt">
							7.3 UPTIME SERVICES CORPORATION may provide equipment owned by UPTIME SERVICES CORPORATION and housed at Client's premises. Such equipment may include, but is not limited to routers, desktops, servers, software, and remote backup devices. Such equipment shall be treated with the same care and security as similar equipment owned by Client. Client shall be held liable for any damage or loss not covered by the manufacturer's warranty. If such loss or damage occurs, Client will be invoiced the current replacement cost of the equipment plus shipping and handling and related installation charges.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">8. Disclaimer Of Warranties; Limitation Of Damages</fo:block>
						<fo:block space-after="4pt">
							8.1 THE EXPRESS, BUT LIMITED, WARRANTY IN SECTION 7 ABOVE IS IN LIEU OF ALL OTHER WARRANTIES, EXPRESS, IMPLIED OR STATUTORY, REGARDING UPTIME SERVICES CORPORATION SERVICES. UPTIME SERVICES CORPORATION AND ITS AFFILIATES SPECIFICALLY DISCLAIM ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO ALL WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT AND ANY WARRANTIES ARISING FROM COURSE OF DEALING, COURSE OF PERFORMANCE OR TRADE USAGE.
						</fo:block>
						<fo:block space-after="4pt">
							8.2 UPTIME SERVICES CORPORATION AND ITS AFFILIATES SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, PUNITIVE OR CONSEQUENTIAL DAMAGES, OR FOR ANY LOST DATA, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOST PROFITS, COSTS OF PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION ARISING FROM OR RELATING TO THIS AGREEMENT OR ARISING FROM OR RELATING TO THE USE OF THE SOFTWARE WHICH HAS BEEN MODIFIED BY ANYONE OTHER THAN UPTIME SERVICES CORPORATION, LOSS OF PROGRAMS, AND THE LIKE, THAT RESULT FROM THE USE OR INABILITY TO USE THE SERVICES OR FROM MISTAKES, OMISSIONS, INTERRUPTIONS, DELETION OF FILES OR DIRECTORIES, LOSS OF DATA, ERRORS, DEFECTS, DELAYS IN OPERATION, OR TRANSMISSION, OR ANY FAILURE OF PERFORMANCE, HOWEVER CAUSED AND UNDER ANY THEORY OF LIABILITY (INCLUDING NEGLIGENCE OR OTHER TORTS), TO THE EXTENT ALLOWED BY LAW, EVEN IF UPTIME SERVICES CORPORATION HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
						</fo:block>
						<fo:block space-after="4pt">
							8.3 CLIENT ACKNOWLEDGES AND AGREES THAT CLIENT HAS RELIED ON NO WARRANTIES EXCEPT THE LIMITED EXPRESS WARRANTY IN SECTION 7.
						</fo:block>
						<fo:block space-after="4pt">
							8.4 Client agrees that the total liability of UPTIME SERVICES CORPORATION and its affiliates and the sole remedy of Client and any End User for any claims regarding UPTIME SERVICES CORPORATION services is limited to Client's right to terminate this Agreement. Further, should a court nonetheless find that remedy is not exclusive or that UPTIME SERVICES CORPORATION is for any reason nonetheless liable for money damages, the cumulative liability in connection with this Agreement, whether in contract, tort or otherwise, shall not exceed the amount paid to UPTIME SERVICES CORPORATION under this Agreement during the three months preceding the events giving rise to such liability. The existence of more than one claim shall not enlarge that limitation of liability.
						</fo:block>
						<fo:block space-after="4pt">
							8.5 Except as expressly provided in the Agreement, Client acknowledges that (a) UPTIME SERVICES CORPORATION is in no manner responsible for any action or inaction of any third party; (b) UPTIME SERVICES CORPORATION has not represented that the services shall be uninterrupted, error free, or without delay; and (c) UPTIME SERVICES CORPORATION does not and cannot control the flow of data through the Internet, and such flow depends in large part on the performance of third parties whose actions or inaction can, at times, produce situations in which connections to the Internet (or portions thereof) may be impaired or disrupted. ACCORDINGLY, CLIENT ACKNOWLEDGES THAT UPTIME SERVICES CORPORATION DISCLAIMS ALL LIABILITY RELATED TO EVENTS OUTSIDE OF OUR CONTROL AND/OR IN THE CONTROL OF THIRD PARTIES, AND CLIENT SHALL HAVE NO RIGHT TO RELY UPON ANY REPRESENTATION OR WARRANTY OF ANY THIRD PARTY IN RESPECT TO THE SERVICES. Further, Client acknowledges that, in providing the services, UPTIME SERVICES CORPORATION shall necessarily rely upon information, instructions, and services from Client, its administrator, employees and agents, and other third parties providing computer and communications hardware, software, and Internet services. Except as expressly provided in the Agreement, Client fully assumes the risk associated with errors in such information, instructions, and services.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">9. Non Solicitation Of Employees</fo:block>
						<fo:block space-after="4pt">
							Client acknowledges that UPTIME SERVICES CORPORATION has a substantial investment in its employees that provide services to Client under this Agreement and that such employees are subject to UPTIME SERVICES CORPORATION's control and supervision. In consideration of this investment, Client agrees not to solicit, hire, employ, retain, or contract with any employee of UPTIME SERVICES CORPORATION, without first receiving UPTIME SERVICES CORPORATION's written consent. If any employee involved with the delivering of these services terminates his or her employment with UPTIME SERVICES CORPORATION (regardless of the reason for termination), and is employed by Client (or any affiliate or subsidiary of Client) in any capacity either during the term of this agreement or within a 6 month period thereafter, Client shall immediately pay UPTIME SERVICES CORPORATION an amount equal to 50% of the then current yearly salary or wage paid by UPTIME SERVICES CORPORATION to such employee.
						</fo:block>
						<fo:block font-weight="bold" space-after="2pt">10. General Provisions</fo:block>
						<fo:block space-after="4pt">
							10.1 Entire Agreement. This Agreement constitutes the entire agreement between the parties with respect to the subject hereof and supersedes all prior proposals, agreements, negotiations, correspondence, demonstrations, and other communications, whether written or oral, between UPTIME SERVICES CORPORATION and Client. No modification or waiver of any provision hereof shall be effective unless made in writing signed by both UPTIME SERVICES CORPORATION and Client.
						</fo:block>
						<fo:block space-after="4pt">
							10.5 Severability. If any provision hereof is determined in any proceeding binding upon the parties hereto to be invalid or unenforceable, that provision shall be deemed severed from the remainder of the Agreement, and the remaining provisions of the Agreement shall continue in full force and effect.
						</fo:block>
						<fo:block space-after="4pt">
							10.6 Force Majeure. Neither party shall be liable hereunder by reason of any failure or delay in the performance of its obligations hereunder (except for the obligation for the payment of money) on account of any cause that is beyond the reasonable control of such party.
						</fo:block>
						<fo:block space-after="4pt">
							10.7 Applicable Law and Venue. This Agreement shall be governed and construed in all respects in accordance with the laws of the State of Michigan. Client agrees it is subject to personal jurisdiction of the courts in Midland County, Michigan, and any dispute arising out of this Agreement requiring adjudication by a court of law shall be filed and heard in the venue of Midland County, Michigan.
						</fo:block>
						<fo:block space-after="4pt">
							10.8 Notices. Except where provided otherwise, notices hereunder shall be in writing and shall be deemed to have been fully given and received when mailed by registered or certified mail, return receipt requested, postage prepaid, and properly addressed to the offices of the respective parties as specified in the first paragraph of this Agreement, or at such address as the parties may later specify in writing for such purposes. The foregoing shall apply regardless of whether such mail is accepted or unclaimed.
						</fo:block>
						<fo:block space-after="4pt">
							10.9 Assignment. This Agreement shall inure to the benefit of, and be binding upon, any successor to or purchaser of UPTIME SERVICES CORPORATION whether by contract, merger or operation of law. Except for this limited right of assignment, neither party shall assign this Agreement or any right or interest under this Agreement, nor delegate any work or obligation to be performed under this Agreement, without the other party's prior written consent. Any attempted assignment or delegation in contravention of this provision shall be void and ineffective.
						</fo:block>
						<fo:block space-after="4pt">
							10.10 Arbitration. Except for the right of either party to apply to a court of competent jurisdiction for a Temporary Restraining Order, Preliminary Injunction, or other equitable relief to preserve the status quo or prevent irreparable harm pending the selection and confirmation of the arbitrator, any and all disputes, controversies, or claims arising out of or relating to this Agreement or a breach thereof shall be submitted to and finally resolved by arbitration under the rules of the American Arbitration Association (AAA) then in effect. There shall be one arbitrator, and such arbitrator shall be chosen by mutual agreement of the parties or in accordance with AAA rules. The findings of the arbitrator shall be final and binding on the parties, and may be entered in any court of competent jurisdiction for enforcement. Legal fees shall be awarded to the prevailing party in the arbitration.
						</fo:block>
						<fo:block space-after="4pt">
							10.11 Liquidated Damages. Client acknowledges that UPTIME SERVICES CORPORATION is relying on Client to perform as promised under this agreement and therefore makes significant investments in time, equipment, and personnel accordingly. To protect this investment, UPTIME SERVICES CORPORATION has the right to collect liquidated damages in case of breach by Client. If Client fails to perform as promised under this agreement, Client agrees to pay liquidated damages in an amount equal to the remainder of contract term.
						</fo:block>
					</fo:block>

					<!-- Signature Section -->
					<fo:block margin-top="30pt" margin-bottom="20pt" font-family="{$font_family}" font-size="9pt">
						<fo:block font-weight="bold" font-size="11pt" margin-bottom="15pt" color="{$uptime_blue}">
							Customer Acceptance
						</fo:block>
						<fo:table width="100%" table-layout="fixed">
							<fo:table-column column-width="50%"/>
							<fo:table-column column-width="50%"/>
							<fo:table-body>
								<fo:table-row>
									<fo:table-cell padding-right="10pt">
										<fo:block margin-bottom="25pt">Signature: _________________________________________</fo:block>
										<fo:block margin-bottom="25pt">Printed Name: _________________________________________</fo:block>
									</fo:table-cell>
									<fo:table-cell padding-left="10pt">
										<fo:block margin-bottom="25pt">Title: _________________________________________</fo:block>
										<fo:block margin-bottom="25pt">Date: _________________________________________</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
					</fo:block>

					<!-- Last page marker for page numbering -->
					<fo:block id="last-page"/>

				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>

</xsl:stylesheet>
