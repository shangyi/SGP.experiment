`getSGPConfig` <- 
function(sgp_object,
	state,
	tmp_sgp_object,
	content_areas, 
	years, 
	grades,
	sgp.config,
	sgp.percentiles,
	sgp.projections,
	sgp.projections.lagged,
	sgp.percentiles.baseline,
	sgp.projections.baseline,
	sgp.projections.lagged.baseline,
	sgp.config.drop.nonsequential.grade.progression.variables,
	sgp.minimum.default.panel.years) {

	YEAR <- CONTENT_AREA <- VALID_CASE <- NULL

	### Define variables

	sgp.config.list <- list()

	### Check arguments

	if (is.null(sgp.config) & !is.null(grades)) {
		grades <- type.convert(as.character(grades), as.is=TRUE)
		if (!is.numeric(grades)) {
			stop("\tNOTE: Automatic configuration of analyses is currently only available for integer grade levels. Manual specification of 'sgp.config' is required for non-traditional End of Course grade and course progressions.")
		} 
	}

	### get.config function

	get.config <- function(content_area, year, grades) {
		
		### Data for Years & Grades
		tmp.unique.data <- lapply(sgp_object@Data[SJ("VALID_CASE", content_area), nomatch=0][, c("YEAR", "GRADE"), with=FALSE], function(x) sort(type.convert(unique(x), as.is=TRUE)))

		### Years (sgp.panel.years)
		sgp.panel.years <- as.character(tmp.unique.data$YEAR[1:which(tmp.unique.data$YEAR==year)])

		### Content Areas (sgp.content.areas)
		sgp.content.areas <- rep(content_area, length(sgp.panel.years))

		### Grades (sgp.grade.sequences)
		tmp.last.year.grades <- sort(type.convert(unique(subset(sgp_object@Data, YEAR==tail(sgp.panel.years, 1) & CONTENT_AREA==content_area & VALID_CASE=="VALID_CASE")[['GRADE']]), as.is=TRUE))
		if (!is.numeric(tmp.last.year.grades) | !is.numeric(tmp.unique.data[['GRADE']])) {
			stop("\tNOTE: Automatic 'sgp.config' calculation is only available for integer grade levels. Manual specification of 'sgp.config' is required for non-traditional grade and course progressions.")
		}
		tmp.sgp.grade.sequences <- lapply(tmp.last.year.grades, function(x) tail(tmp.unique.data$GRADE[tmp.unique.data$GRADE <= x], length(tmp.unique.data$YEAR)))
		if (!is.null(grades)) {
			tmp.sgp.grade.sequences <- tmp.sgp.grade.sequences[sapply(tmp.sgp.grade.sequences, function(x) tail(x,1)) %in% grades]
		}
		sgp.grade.sequences <- lapply(tmp.sgp.grade.sequences, function(x) if (length(x) > 1) x[(tail(x,1)-x) <= length(sgp.panel.years)-1])
		sgp.grade.sequences <- sgp.grade.sequences[!unlist(lapply(sgp.grade.sequences, function(x) !length(x) > 1))]
		sgp.grade.sequences <- lapply(sgp.grade.sequences, as.character)

		### Create and return sgp.config
		if ("YEAR_WITHIN" %in% names(sgp_object@Data)) {
			sgp.panel.years.within <- rep("LAST_OBSERVATION", length(sgp.content.areas))
			return(list(
				sgp.content.areas=sgp.content.areas,
				sgp.panel.years=sgp.panel.years,
				sgp.grade.sequences=sgp.grade.sequences,
				sgp.panel.years.within=sgp.panel.years.within))
		} else {
			return(list(
				sgp.content.areas=sgp.content.areas,
				sgp.panel.years=sgp.panel.years,
				sgp.grade.sequences=sgp.grade.sequences
				))
		}
	} ### END get.config 

	
	### get.par.sgp.config function

	get.par.sgp.config <- function(sgp.config) {

		### Utility functions

		split.location <- function(years) sapply(strsplit(years, '_'), length)[1]

		### Set-up

		par.sgp.config <- list()

		### Loop over each element of sgp.config
		for (a in seq_along(sgp.config)) { # now seq_along names so that sgp.config lists can have same names for some elements

			### Convert sgp.grade.sequences to a list if supplied as a vector
			if (is.numeric(sgp.config[[a]][['sgp.grade.sequences']])) sgp.config[[a]][['sgp.grade.sequences']] <- list(sgp.config[[a]][['sgp.grade.sequences']])

			### Loop over grade distinct grade sequences
			b.iter <- seq(from=length(par.sgp.config)+1, length.out=length(sgp.config[[a]][['sgp.grade.sequences']]))
			for (b in seq_along(b.iter)) {

				### Create a per sgp.grade.sequence branch in par.sgp.config list
				par.sgp.config[[b.iter[b]]] <- sgp.config[[a]]
				par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']] <- as.character(sgp.config[[a]][['sgp.grade.sequences']][[b]])

				### Create sgp.exact.grade.progression
				if (!is.null(sgp.config[[a]][['sgp.exact.grade.progression']])) {
					par.sgp.config[[b.iter[b]]][['sgp.exact.grade.progression']] <- sgp.config[[a]][['sgp.exact.grade.progression']][b]
				} else {
					par.sgp.config[[b.iter[b]]][['sgp.exact.grade.progression']] <- FALSE
				}
				
				###  Set sgp.exact.grade.progression=TRUE if using multiple content areas in a single year as priors.
				if (any(duplicated(paste(par.sgp.config[[b]][['sgp.panel.years']], par.sgp.config[[b]][['sgp.grade.sequences']], sep=".")))) {  
					par.sgp.config[[b.iter[b]]][['sgp.exact.grade.progression']] <- TRUE
				} else {
					if (is.null(par.sgp.config[[b]][['sgp.exact.grade.progression']])) {
						par.sgp.config[[b.iter[b]]][['sgp.exact.grade.progression']] <- FALSE
					}
				}

				### Create index and re-specify years and content areas from sgp.panel.years and sgp.content.areas
				if (is.numeric(type.convert(par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']]))) {
					tmp.numeric.grades <- sort(type.convert(par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']]))
					grade.span <- seq(min(tmp.numeric.grades), max(tmp.numeric.grades))
					index <- match(tmp.numeric.grades, grade.span)
					if (!sgp.config.drop.nonsequential.grade.progression.variables)  index <- seq_along(index) 
					par.sgp.config[[b.iter[b]]][['sgp.panel.years']] <- tail(par.sgp.config[[b.iter[b]]][['sgp.panel.years']], max(index))[index]
					par.sgp.config[[b.iter[b]]][['sgp.content.areas']] <- tail(par.sgp.config[[b.iter[b]]][['sgp.content.areas']], max(index))[index]
					if ('sgp.panel.years.within' %in% names(sgp.config[[a]])) {
						par.sgp.config[[b.iter[b]]][['sgp.panel.years.within']] <- tail(par.sgp.config[[b.iter[b]]][['sgp.panel.years.within']], max(index))[index]
					} 
				}

				### Create sgp.panel.years.lags (if NULL)
				if (is.null(sgp.config[[a]][['sgp.panel.years.lags']])) {
					par.sgp.config[[b.iter[b]]][['sgp.panel.years.lags']] <- 
						diff(as.numeric(sapply(strsplit(par.sgp.config[[b.iter[b]]][['sgp.panel.years']], '_'), '[', split.location(par.sgp.config[[b.iter[b]]][['sgp.panel.years']]))))
				}

				### Create sgp.projection.grade.sequences (if NULL)
				if (is.null(sgp.config[[a]][['sgp.projection.grade.sequences']]) & (sgp.projections|sgp.projections.lagged|sgp.projections.baseline|sgp.projections.lagged.baseline)) {
					par.sgp.config[[b.iter[b]]][['sgp.projection.grade.sequences']] <- head(par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']], -1)
				} else {
					par.sgp.config[[b.iter[b]]][['sgp.projection.grade.sequences']] <- as.character(sgp.config[[a]][['sgp.projection.grade.sequences']][[b]])
				}

				### Create sgp.projection.content.areas (if NULL)
				if (sgp.projections|sgp.projections.lagged|sgp.projections.baseline|sgp.projections.lagged.baseline) {
					if (is.null(sgp.config[[a]][['sgp.projection.content.areas']])) {
						par.sgp.config[[b.iter[b]]][['sgp.projection.content.areas']] <- head(par.sgp.config[[b.iter[b]]][['sgp.content.areas']], -1)
					} else {
						if (identical(par.sgp.config[[b.iter[b]]][['sgp.projection.grade.sequences']], "NO_PROJECTIONS")) {
							par.sgp.config[[b.iter[b]]][['sgp.projection.content.areas']] <- as.character(sgp.config[[a]][['sgp.projection.content.areas']])
						}
					}
				}

				### Create sgp.projection.panel.years.lags (if NULL)
				if (sgp.projections|sgp.projections.lagged|sgp.projections.baseline|sgp.projections.lagged.baseline) {
					if (is.null(sgp.config[[a]][['sgp.projection.panel.years']])) {
						tmp.panel.years <- head(par.sgp.config[[b.iter[b]]][['sgp.panel.years']], -1)
						par.sgp.config[[b.iter[b]]][['sgp.projection.panel.years']] <- 
							as.character(sapply(tmp.panel.years, yearIncrement, tail(par.sgp.config[[b.iter[b]]][['sgp.panel.years.lags']], 1)))
						par.sgp.config[[b.iter[b]]][['sgp.projection.panel.years.lags']] <- head(par.sgp.config[[b.iter[b]]][['sgp.panel.years.lags']], -1)
					} else {
						if (!identical(par.sgp.config[[b.iter[b]]][['sgp.projection.grade.sequences']], "NO_PROJECTIONS")) {
							par.sgp.config[[b.iter[b]]][['sgp.projection.panel.years.lags']] <- 
								diff(as.numeric(sapply(strsplit(par.sgp.config[[b.iter[b]]][['sgp.projection.panel.years']], '_'), '[', split.location(par.sgp.config[[b.iter[b]]][['sgp.projection.panel.years']]))))
						}
					}
				}

				### Create sgp.projection.sequence (if NULL)
				if (sgp.projections|sgp.projections.lagged|sgp.projections.baseline|sgp.projections.lagged.baseline) {
					if (is.null(sgp.config[[a]][['sgp.projection.sequence']])) {
						par.sgp.config[[b.iter[b]]][['sgp.projection.sequence']] <- tail(par.sgp.config[[b.iter[b]]][['sgp.content.areas']], 1)
					}
				}

				### Create baseline specific arguments
				if (sgp.percentiles.baseline | sgp.projections.baseline | sgp.projections.lagged.baseline) {
					tmp.matrix.label <- paste(strsplit(names(sgp.config)[a], "\\.")[[1]][1], ".BASELINE", sep="")
 					if (tmp.matrix.label %in% names(tmp_sgp_object[["Coefficient_Matrices"]])) {
						tmp.matrices <- tmp_sgp_object[['Coefficient_Matrices']][[tmp.matrix.label]]
						tmp.orders <- getsplineMatrices(
							my.matrices=tmp.matrices, 
							my.matrix.content_area.progression=par.sgp.config[[b.iter[b]]][['sgp.content.areas']], 
							my.matrix.grade.progression=par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']], 
							my.matrix.time.progression=rep("BASELINE", length(par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']])),
							my.matrix.time.progression.lags=par.sgp.config[[b.iter[b]]][['sgp.panel.years.lags']],
							what.to.return="ORDERS")

						if (length(tmp.orders) > 0) {
							tmp.matrices.tf <- TRUE
							tmp.max.order <- max(tmp.orders)
						} else {
							tmp.matrices.tf <- FALSE
						}
					} else tmp.matrices.tf <- FALSE

					if (!tmp.matrices.tf) {
						par.sgp.config[[b.iter[b]]][['sgp.baseline.grade.sequences']] <- "NO_BASELINE_COEFFICIENT_MATRICES"
						par.sgp.config[[b.iter[b]]][['sgp.baseline.max.order']] <- "NO_BASELINE_COEFFICIENT_MATRICES"
					} else {
						par.sgp.config[[b.iter[b]]][['sgp.baseline.grade.sequences']] <- as.character(tail(par.sgp.config[[b.iter[b]]][['sgp.grade.sequences']], tmp.max.order+1))
						par.sgp.config[[b.iter[b]]][['sgp.baseline.content.areas']] <- as.character(tail(par.sgp.config[[b.iter[b]]][['sgp.content.areas']], tmp.max.order+1))
						par.sgp.config[[b.iter[b]]][['sgp.baseline.max.order']] <- tmp.max.order
						par.sgp.config[[b.iter[b]]][['sgp.baseline.panel.years.lags']] <- tail(par.sgp.config[[b.iter[b]]][['sgp.panel.years.lags']], tmp.max.order) 
					}
				} ### END if (sgp.percentiles.baseline | sgp.projections.baseline | sgp.projections.lagged.baseline

			} ### END b loop
		} ### END a loop
		return(par.sgp.config)
	} ## END get.par.sgp.config


	## test.projection.iter function
	
	test.projection.iter <- function(sgp.iter) {
		if (identical(sgp.iter[['sgp.projection.grade.sequences']], "NO_PROJECTIONS")) return(FALSE)
		if (!is.null(SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]])) {
			if (tail(sgp.iter[["sgp.grade.sequences"]], 1) == "EOCT") { # Only check EOCT configs/iters
				if (is.null(SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[tail(sgp.iter[["sgp.content.areas"]], 1)]])) return(FALSE)
				tmp.index <- match(tail(sgp.iter[["sgp.content.areas"]], 1), 
					SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[tail(sgp.iter[["sgp.content.areas"]], 1)]])
				tmp.content_area.projection.sequence <-
					SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[tail(sgp.iter[["sgp.content.areas"]], 1)]][1:tmp.index]
				tmp.grade.projection.sequence <-
					SGPstateData[[state]][["SGP_Configuration"]][["grade.projection.sequence"]][[tail(sgp.iter[["sgp.content.areas"]], 1)]][1:tmp.index]
				tmp.year_lags.projection.sequence <-
					SGPstateData[[state]][["SGP_Configuration"]][["year_lags.projection.sequence"]][[tail(sgp.iter[["sgp.content.areas"]], 1)]][1:(tmp.index-1)]
				if (!all(sgp.iter[["sgp.content.areas"]] == tmp.content_area.projection.sequence & 
					sgp.iter[["sgp.grade.sequences"]] == tmp.grade.projection.sequence & 
					sgp.iter[["sgp.panel.years.lags"]] == tmp.year_lags.projection.sequence)) iter.test <- FALSE else iter.test <- TRUE
			}	else iter.test <- TRUE
		}	else iter.test <- TRUE
		return(iter.test)
	} 


	###
	### Construct sgp.config/par.sgp.config
	###

	if (is.null(sgp.config)) {
		tmp.sgp.config <- tmp.years <- list()
		if (is.null(content_areas)) {
			content_areas <- unique(sgp_object@Data["VALID_CASE"][['CONTENT_AREA']])
		}
		if (is.null(years)) {
			for (i in content_areas) {
				tmp.years[[i]] <- sort(tail(unique(sgp_object@Data[SJ("VALID_CASE", i)][['YEAR']]), - (sgp.minimum.default.panel.years-1)), decreasing=TRUE)
			}
		} else {
			for (i in content_areas) {
				tmp.years[[i]] <- years
			}
		}
		for (i in content_areas) {
			for (j in tmp.years[[i]]) {
				tmp.sgp.config[[paste(i,j,sep=".")]] <- get.config(i,j,grades)
			}
		}
		par.sgp.config <- checkConfig(get.par.sgp.config(tmp.sgp.config), "Standard")
	} else {
		par.sgp.config <- checkConfig(get.par.sgp.config(sgp.config), "Standard")
	}


	### 
	### Extend sgp.config.list
	###

	if (sgp.percentiles) sgp.config.list[['sgp.percentiles']] <- par.sgp.config

	if (sgp.projections | sgp.projections.lagged) {
		tmp.config <- par.sgp.config[sapply(par.sgp.config, test.projection.iter)]
		if (length(tmp.config) > 0) for (f in 1:length(tmp.config)) tmp.config[[f]]$sgp.exact.grade.progression <- FALSE
		if (sgp.projections) sgp.config.list[['sgp.projections']] <- tmp.config
		if (sgp.projections.lagged) sgp.config.list[['sgp.projections.lagged']] <- tmp.config
	}

	if (sgp.percentiles.baseline | sgp.projections.baseline | sgp.projections.lagged.baseline) {
		if (any(sapply(par.sgp.config, function(x) identical(x[['sgp.baseline.grade.sequences']], "NO_BASELINE_COEFFICIENT_MATRICES")))) {
			baseline.missings <- which(sapply(par.sgp.config, function(x) identical(x[['sgp.baseline.grade.sequences']], "NO_BASELINE_COEFFICIENT_MATRICES")))
			baseline.missings <- paste(unlist(sapply(baseline.missings, function(x) 
				paste(tail(par.sgp.config[[x]]$sgp.content.areas, 1), paste(par.sgp.config[[x]]$sgp.grade.sequences, collapse=", "), sep=": "))), collapse=";\n\t\t")
			message("\tNOTE: Baseline coefficient matrices are not available for:\n\t\t", baseline.missings, ".", sep="")
		}

		sgp.config.list[['sgp.percentiles.baseline']] <- 
			par.sgp.config[which(sapply(par.sgp.config, function(x) !identical(x[['sgp.baseline.grade.sequences']], "NO_BASELINE_COEFFICIENT_MATRICES")))]

		tmp.config <- sgp.config.list[['sgp.percentiles.baseline']][sapply(sgp.config.list[['sgp.percentiles.baseline']], test.projection.iter)]
		if (length(tmp.config) > 0) for (f in 1:length(tmp.config)) tmp.config[[f]]$sgp.exact.grade.progression <- FALSE
		if (!sgp.percentiles.baseline) sgp.config.list[['sgp.percentiles.baseline']] <- NULL
		if (sgp.projections.baseline) sgp.config.list[['sgp.projections.baseline']] <- tmp.config
		if (sgp.projections.lagged.baseline) sgp.config.list[['sgp.projections.lagged.baseline']] <- tmp.config
	}

	return(sgp.config.list)
} ## END getSGPConfig
