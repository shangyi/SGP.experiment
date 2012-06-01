`testSGP` <- function(TEST_NUMBER) {

	if (missing(TEST_NUMBER)) {
		message("\ttestSGP carries out testing of SGP package. Tests currently included in testSGP:\n")
		message("\t\t1. abcSGP test using all available years.")
		message("\t\t2. abcSGP test using all available years except most recent followed by an updated analysis using the most recent year's data.")
	}

	if (1 %in% TEST_NUMBER) {

	expression.to.evaluate <- 
		"abcSGP(sgpData_LONG,
			sgPlot.demo.report=TRUE,
			save.intermediate.results=TRUE,
			parallel.config=list(BACKEND='PARALLEL', WORKERS=list(PERCENTILES=30, BASELINE_PERCENTILES=30, PROJECTIONS=14, LAGGED_PROJECTIONS=14, SUMMARY=30, GA_PLOTS=10, SG_PLOTS=1)))"


	print("##### Beginning testSGP test number 1 #####")

	eval(parse(text=expression.to.evaluate))

	print("##### End testSGP test number 1 #####")

	} ### End TEST_NUMBER 1

} ### END testSGP Function