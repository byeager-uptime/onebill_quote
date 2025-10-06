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
									<fo:block font-size="28pt" font-weight="bold" text-align="right" margin-bottom="8pt">
										ESTIMATE
									</fo:block>
									<fo:block font-weight="bold" font-size="11pt" text-align="right" margin-bottom="4pt">
										<xsl:value-of select="/quote/quoteSubscriberProfile/subscriberName"/>
									</fo:block>
									<fo:block font-size="9pt" text-align="right" margin-bottom="2pt">
										<xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/addLine1"/>
										<xsl:if test="/quote/quoteSubscriberProfile/billingAddress/addLine2 !=''">, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/addLine2"/></xsl:if>
										, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/city"/>, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/state"/>
										<xsl:text> </xsl:text>
										<xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/zip"/>
									</fo:block>
									<fo:block font-size="9pt" text-align="right" margin-bottom="8pt">
										<xsl:value-of select="/quote/createdByEmail"/>
									</fo:block>
									<fo:block font-size="10pt" font-weight="bold" text-align="right">
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
										<fo:block>855.402.VOIP (8647)</fo:block>
										<fo:block>help@uptimevoip.co</fo:block>
										<fo:block>uptimevoip.co</fo:block>
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

					<!-- Master Services Agreement -->
					<fo:block margin-top="20pt" font-family="{$font_family}" font-size="7pt"
						border-top="1pt solid #CCCCCC" padding-top="10pt" keep-together.within-page="auto">
						<fo:block font-weight="bold" font-size="11pt" margin-bottom="8pt" color="{$uptime_blue}" text-align="center">
							MASTER SERVICES AGREEMENT
						</fo:block>
						<fo:block space-after="8pt" font-size="8pt">
							By signing this quote, Customer ("<fo:inline font-weight="bold">Client</fo:inline>") agrees to be bound by this Master Services Agreement with Uptime Services Corporation ("<fo:inline font-weight="bold">Provider</fo:inline>"). This quote serves as a Statement of Service under this Agreement. All quotes must be paid in full by the electronic payment method on file before equipment can be ordered.
						</fo:block>
						<fo:block space-after="8pt" font-weight="bold" font-size="8pt">
							Contract Term: <xsl:value-of select="/quote/contractTerm"/> from Activation Date
						</fo:block>

						<!-- Section 1: Definitions -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							1. DEFINITIONS
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">"Activation Date"</fo:inline> means the earlier of (a) the date the Services are provisioned and capable of originating and/or receiving calls using a temporary or ported number, or (b) the date any Service goes into production. Billing starts on the Activation Date whether or not Client has begun use.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">"Services"</fo:inline> means the hosted VoIP, SIP, UCaaS, related features, support, and any professional services that Provider supplies to Client as described in this quote or a Statement of Service.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">"MRC"</fo:inline> means monthly recurring charges for the applicable Service(s), excluding usage, pass-through surcharges, taxes, one-time fees, and third-party charges.
						</fo:block>
						<fo:block space-after="6pt">
							<fo:inline font-weight="bold">"Statement of Service" or "SoS"</fo:inline> means an order, quote, proposal, or statement of work executed by both parties that references this MSA, specifies the Services, quantities, term and pricing.
						</fo:block>

						<!-- Section 2: Term; Renewal; Termination; Suspension -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							2. TERM; RENEWAL; TERMINATION; SUSPENSION
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">2.1 Term.</fo:inline> This Agreement begins on the date signed and continues for <xsl:value-of select="/quote/contractTerm"/> from the Activation Date for each Service.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">2.2 Renewal.</fo:inline> Following the initial term, the Agreement renews month-to-month unless either party gives 60 days' written notice of non-renewal.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">2.3 Termination for Cause.</fo:inline> Either party may terminate for material breach that remains uncured 30 days after written notice (or 10 days for undisputed nonpayment).
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">2.4 Early Termination Fee (ETF).</fo:inline> Client may terminate for convenience before the end of the term by giving 60 days' written notice and paying an Early Termination Fee equal to 50% of the then-current MRC for the terminated Services multiplied by the number of months remaining in the term.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">2.5 Suspension.</fo:inline> Provider may suspend Services immediately if: (a) an invoice is more than 30 days past due; (b) Provider suspects fraud or abuse; (c) Client violates the Acceptable Use Policy; or (d) suspension is required by law. Reconnection fee: $50 per event.
						</fo:block>

						<!-- Section 3: Statements of Service; Ordering; Changes -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							3. STATEMENTS OF SERVICE; ORDERING; CHANGES
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">3.1 Ordering.</fo:inline> This quote serves as a Statement of Service and is governed by this MSA.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">3.2 Changes.</fo:inline> Client may request increases or decreases to quantities. Decreases take effect on the next billing cycle. If quantities are reduced to zero, the ETF in Section 2.4 applies.
						</fo:block>

						<!-- Section 4: Fees; Invoicing; Taxes; Disputes -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							4. FEES; INVOICING; TAXES; DISPUTES
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">4.1 Invoicing.</fo:inline> Provider invoices MRCs monthly in advance and usage/one-time fees in arrears. Unless otherwise stated, invoices are due Net 15 from the invoice date. Client must maintain an automated payment method (ACH or credit card) on file.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">4.2 Late Fees.</fo:inline> Undisputed past-due amounts accrue a late charge of 1.5% per month (or the maximum allowed by law). Provider may suspend Services per Section 2.5. Reconnection fee: $50.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">4.3 Billing Disputes.</fo:inline> Client must submit any invoice dispute in writing within 30 days of invoice receipt. Client must pay all undisputed amounts when due.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">4.4 Taxes.</fo:inline> Client is responsible for all applicable taxes, regulatory fees, assessments, and pass-through surcharges, including USF, E911/988, and similar assessments, except for taxes on Provider's net income. Valid exemption certificates must be provided prior to the invoice date.
						</fo:block>

						<!-- Section 5: Service Levels; Support; Maintenance -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							5. SERVICE LEVELS; SUPPORT; MAINTENANCE
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">5.1 Support.</fo:inline> Provider offers support during Business Hours (Monday-Friday, 8 AM - 6 PM Eastern, excluding holidays) via channels listed at uptimevoip.co/support.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">5.2 SLA.</fo:inline> The Service Level Agreement at uptimevoip.co/sla applies to covered Services. Service credits are the sole monetary remedy for SLA claims.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">5.3 Maintenance.</fo:inline> Provider may perform routine maintenance and upgrades. Provider will use reasonable efforts to schedule planned maintenance outside Business Hours and to provide prior notice.
						</fo:block>

						<!-- Section 6: E911 and MLTS Requirements -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							6. E911 AND MLTS REQUIREMENTS
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">6.1 Limitations.</fo:inline> VoIP 911 has inherent limitations, including dependence on power and broadband. VoIP 911 may be unavailable during power or Internet outages. Full E911 Policy available at uptimevoip.co/policies/e911.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">6.2 Client Duties.</fo:inline> Client must: (a) provide and maintain a dispatchable location for each endpoint and update within 1 business day of changes; (b) ensure direct 911 dialing is available; (c) place E911 warning labels on/near devices; (d) train users on VoIP 911 limitations; (e) test routing using 933 before go-live.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">6.3 Allocation of Risk.</fo:inline> Client assumes the risk of inaccurate location information and power/broadband failures not caused by Provider's willful misconduct.
						</fo:block>

						<!-- Section 7: Acceptable Use; Robocall Mitigation -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							7. ACCEPTABLE USE; ROBOCALL MITIGATION; STIR/SHAKEN
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">7.1 Acceptable Use.</fo:inline> Client will comply with all applicable laws relating to outbound calling and messaging, including caller ID rules, Do-Not-Call, and anti-spam policies. Prohibited uses include unlawful robocalls, illegal spoofing, traffic pumping, and fraudulent traffic. Full policy at uptimevoip.co/policies/aup.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">7.2 Robocall Mitigation.</fo:inline> Provider implements call authentication (STIR/SHAKEN) and robocall mitigation. Client will cooperate, including providing accurate caller ID and KYC documentation upon request.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">7.3 Enforcement.</fo:inline> Provider may block, rate-limit, or suspend traffic reasonably believed to be unlawful, fraudulent, or network-threatening.
						</fo:block>

						<!-- Section 8: Numbering; Porting (LNP) -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							8. NUMBERING; PORTING (LNP)
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">8.1 Number License.</fo:inline> Provider-assigned numbers are licensed, not sold. Client may port them out if permitted by law and the carrier. Full policy at uptimevoip.co/policies/porting.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">8.2 Port-In/Out.</fo:inline> Porting requires valid LOA and CSR/BTN information. Provider will not unreasonably delay valid port-out requests. Client is responsible for charges until port completes.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">8.3 After Termination.</fo:inline> Provider may reclaim numbers not ported within 30 days after termination.
						</fo:block>

						<!-- Section 9: Fraud Prevention; Security -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							9. FRAUD PREVENTION; SECURITY; ABNORMAL USAGE
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">9.1 Client Security.</fo:inline> Client must secure credentials, endpoints, and network elements (strong passwords, firmware updates, firewall rules, 2FA).
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">9.2 Fraud/Abuse.</fo:inline> Client is responsible for all use of Services, authorized or not, including fraudulent or unauthorized usage, unless caused by Provider's willful misconduct. Provider may set spend limits or call destination blocks and may suspend abnormal usage.
						</fo:block>

						<!-- Section 10: Equipment; Title; Risk of Loss -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							10. EQUIPMENT; TITLE; RISK OF LOSS
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">10.1 Title.</fo:inline> Title to purchased Equipment passes to Client upon full payment. Rented/loaned Equipment remains Provider's property.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">10.2 Risk of Loss.</fo:inline> Risk of loss transfers to Client upon delivery. Client must return rented Equipment within 30 days of termination in good condition or pay a non-return fee.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">10.3 Warranties.</fo:inline> Provider does not manufacture Equipment and passes through manufacturer warranties to the extent permitted. Labor provided by Provider is not covered by manufacturer warranties.
						</fo:block>

						<!-- Section 11: Confidentiality -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							11. CONFIDENTIALITY
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">11.1 Obligations.</fo:inline> Each party will use the other's Confidential Information only to perform under this Agreement and will protect it with at least the same care used for its own similar information (but not less than reasonable care).
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">11.2 Compelled Disclosure.</fo:inline> If legally compelled to disclose, the receiving party will give prompt notice and reasonable cooperation to seek protective treatment.
						</fo:block>

						<!-- Section 12: Intellectual Property; License -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							12. INTELLECTUAL PROPERTY; LICENSE
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">12.1 Ownership.</fo:inline> Provider owns all right, title, and interest in the Services, underlying software, configurations, and any work product developed while performing the Services.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">12.2 License to Client.</fo:inline> Provider grants Client a non-exclusive, non-transferable license during the term to use Provider materials solely to receive and use the Services.
						</fo:block>

						<!-- Section 13: Data; Privacy; CPNI; Call Recording -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							13. DATA; PRIVACY; CPNI; CALL RECORDING
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">13.1 Data Use.</fo:inline> Provider may process Client data (including CDRs and diagnostic logs) to deliver, support, secure, and improve Services. Provider will implement reasonable measures to protect such data.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">13.2 CPNI.</fo:inline> To the extent Provider is subject to CPNI rules, Provider will handle CPNI in accordance with applicable law.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">13.3 Call Recording.</fo:inline> If Client enables recording or transcription, Client is solely responsible for compliance with all applicable consent and notification laws.
						</fo:block>

						<!-- Section 14: Representations and Warranties -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							14. REPRESENTATIONS AND WARRANTIES
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">14.1 Mutual.</fo:inline> Each party represents it has the power and authority to enter into and perform under this Agreement.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">14.2 Provider.</fo:inline> Provider will perform Services in a workmanlike manner consistent with prevailing industry standards.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">14.3 Disclaimer.</fo:inline> EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE SERVICES AND EQUIPMENT ARE PROVIDED "AS IS" AND PROVIDER DISCLAIMS ALL OTHER WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.
						</fo:block>

						<!-- Section 15: Indemnification -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							15. INDEMNIFICATION
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">15.1 Client Indemnity.</fo:inline> Client will defend, indemnify, and hold harmless Provider from third-party claims, damages, fines, and costs (including attorneys' fees) arising from (a) Client's business operations or use of Services in violation of this Agreement or law, or (b) Client's failure to meet obligations in Sections 6, 7, 8, 9, or 13, except to the extent caused by Provider's gross negligence or willful misconduct.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">15.2 Provider IP Indemnity.</fo:inline> Provider will defend and indemnify Client from third-party claims that the Services infringe a U.S. patent, copyright, or trade secret, provided the claim does not arise from combinations, modifications, or use not provided by Provider.
						</fo:block>

						<!-- Section 16: Limitation of Liability -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							16. LIMITATION OF LIABILITY
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">16.1 Exclusions.</fo:inline> NEITHER PARTY IS LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, PUNITIVE, EXEMPLARY, OR CONSEQUENTIAL DAMAGES, OR FOR LOST PROFITS/REVENUE, LOSS OF DATA, OR BUSINESS INTERRUPTION, EVEN IF ADVISED OF THE POSSIBILITY.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">16.2 Cap.</fo:inline> EXCEPT FOR (i) CLIENT'S PAYMENT OBLIGATIONS; (ii) BREACH OF CONFIDENTIALITY; (iii) IP INDEMNITY; AND (iv) GROSS NEGLIGENCE OR WILLFUL MISCONDUCT, EACH PARTY'S TOTAL LIABILITY WILL NOT EXCEED THE FEES PAID OR PAYABLE FOR THE AFFECTED SERVICES IN THE TWELVE (12) MONTHS PRECEDING THE EVENT.
						</fo:block>

						<!-- Section 17: Non-Solicitation -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							17. NON-SOLICITATION
						</fo:block>
						<fo:block space-after="4pt">
							During the term and for twelve (12) months thereafter, Client will not solicit or hire any Provider employee who materially participated in the delivery of Services without Provider's written consent. If violated, Client will pay a placement fee equal to 50% of the employee's then-current annual base salary.
						</fo:block>

						<!-- Section 18: General Provisions -->
						<fo:block font-weight="bold" font-size="9pt" space-after="4pt" color="{$uptime_blue}">
							18. GENERAL PROVISIONS
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.1 Governing Law.</fo:inline> This Agreement is governed by the laws of the State of Michigan, without regard to conflicts of laws principles.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.2 Dispute Resolution.</fo:inline> Any dispute arising out of or relating to this Agreement will be resolved by binding arbitration administered by the American Arbitration Association (AAA) under its Commercial Arbitration Rules by a single arbitrator. The seat is Midland County, Michigan. Either party may seek temporary injunctive relief in court to preserve the status quo pending arbitration. Class actions and class arbitrations are not permitted.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.3 Venue.</fo:inline> For actions to enforce arbitration awards or for temporary relief, the parties consent to exclusive jurisdiction and venue of state or federal courts in Midland County, Michigan.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.4 Notices.</fo:inline> Notices must be in writing to: Provider at billing@uptimevoip.co and 5444 N Coleman RD, STE D, Coleman MI 48618; Client at <xsl:value-of select="/quote/createdByEmail"/> and <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/addLine1"/>, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/city"/>, <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/state"/> <xsl:value-of select="/quote/quoteSubscriberProfile/billingAddress/zip"/>.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.5 Assignment.</fo:inline> Client may not assign without Provider's consent. Provider may assign to an affiliate or in connection with a merger or sale of assets.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.6 Force Majeure.</fo:inline> Neither party is liable for delay or failure to perform (other than payment obligations) due to events beyond its reasonable control.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.7 Entire Agreement.</fo:inline> This Agreement with its Statements of Service constitutes the entire agreement and supersedes prior discussions. Amendments must be in writing signed by both parties.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.8 Severability.</fo:inline> If any provision is unenforceable, the remainder remains in effect.
						</fo:block>
						<fo:block space-after="4pt">
							<fo:inline font-weight="bold">18.9 Independent Contractors.</fo:inline> The parties are independent contractors; no agency, partnership, or joint venture is created.
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
