`getJSON` <-
function(tmp.data,
	state,
	content_area,
	year,
	years.for.percentile.trajectories,
	data.type,
	baseline=FALSE,
	data.year.span.default=5) {

	CONTENT_AREA <- GRADE <- YEAR <- CUTLEVEL <- NULL

	if (data.type=="studentGrowthPlot") {

		### Utility functions

		interpolate.extend.data <- function(tmp.data, grades.content_areas.reported.in.state) {

			tmp.list <- NULL

			last.number <- function (x) {
				if (sum(!is.na(x)) > 0) return(max(which(!is.na(x)))) else return (0)
			}
	
			first.number <- function (x) {
				if (sum(!is.na(x)) > 0 ) return(min(which(!is.na(x)))) else return (0)
			}

			convert.grades <- function(grades, content_areas, to="GRADE_NUMERIC", lookup=grades.content_areas.reported.in.state) {
				if (to=="GRADE_NUMERIC") {
					return(as.numeric(lookup$GRADE_NUMERIC[match(paste(grades, content_areas), paste(lookup$GRADE, lookup$CONTENT_AREA))]))
				}
				if (to=="GRADE") {
					return(as.character(lookup$GRADE[match(grades, lookup$GRADE_NUMERIC)]))
				}
			}

			first.scale.score <- first.number(tmp.data$Grades)
			last.scale.score <- last.number(tmp.data$Grades)
			tmp.grades <- tmp.data$Grades[seq(first.scale.score, last.scale.score)]
			tmp.content_areas <- tmp.data$Content_Areas[seq(first.scale.score, last.scale.score)]
			tmp.grades <- convert.grades(tmp.grades, tmp.content_areas)
			tmp.years <- tmp.data$Years[seq(first.scale.score, last.scale.score)]
			tmp.scale_scores <- tmp.data$Scale_Scores[seq(first.scale.score, last.scale.score)]
			tmp.plotting_scale_scores <- tmp.data$Plotting_Scale_Scores[seq(first.scale.score, last.scale.score)]
			tmp.achievement_levels <- tmp.data$Achievement_Levels[seq(first.scale.score, last.scale.score)]
			tmp.sgp <- tmp.data$SGP[seq(first.scale.score, last.scale.score)]
			tmp.sgp_levels <- tmp.data$SGP_Levels[seq(first.scale.score, last.scale.score)]

			tmp.index.high <- match(tmp.grades[1], grades.content_areas.reported.in.state$GRADE_NUMERIC)
			if (tmp.index.high < dim(grades.content_areas.reported.in.state)[1]) {
				tmp.additional.high <- seq(tmp.index.high+1, dim(grades.content_areas.reported.in.state)[1])
				tmp.grades.extended <- c(rev(grades.content_areas.reported.in.state$GRADE_NUMERIC[tmp.additional.high]), tmp.grades)
				tmp.content_areas.extended <- c(rev(grades.content_areas.reported.in.state$CONTENT_AREA[tmp.additional.high]), tmp.content_areas)
				tmp.years.extended <- c(rev(year.extend(year, cumsum(grades.content_areas.reported.in.state$YEAR_LAG[tmp.additional.high]))), tmp.years)
				tmp.scale_scores.extended <- c(rep(NA, length(tmp.additional.high)), tmp.scale_scores)
				tmp.plotting_scale_scores.extended <- c(rep(NA, length(tmp.additional.high)), tmp.plotting_scale_scores)
				tmp.achievement_levels.extended <- c(rep(NA, length(tmp.additional.high)), tmp.achievement_levels)
				tmp.sgp.extended <- c(rep(NA, length(tmp.additional.high)), tmp.sgp)
				tmp.sgp_levels.extended <- c(rep(NA, length(tmp.additional.high)), tmp.sgp_levels)
			}

			tmp.index.low <- match(tail(tmp.grades, 1), grades.content_areas.reported.in.state$GRADE_NUMERIC)
			if (tmp.index.low > 1) {
				tmp.additional.low <- seq(tmp.index.low-1)
				tmp.additional.low.length <- length(tmp.additional.low)
				tmp.grades.extended <- c(tmp.grades.extended, rev(grades.content_areas.reported.in.state$GRADE_NUMERIC[tmp.additional.low]))
				tmp.content_areas.extended <- c(tmp.content_areas.extended, rev(grades.content_areas.reported.in.state$CONTENT_AREA[tmp.additional.low]))
				tmp.years.extended <- c(tmp.years.extended, rev(year.extend(tail(tmp.years.extended, 1), -cumsum(grades.content_areas.reported.in.state$YEAR_LAG[rev(tmp.additional.low)]))))
				tmp.scale_scores.extended <- c(tmp.scale_scores.extended, rep(NA, length(tmp.additional.low)))
				tmp.plotting_scale_scores.extended <- c(tmp.plotting_scale_scores.extended, rep(NA, length(tmp.additional.low)))
				tmp.achievement_levels.extended <- c(tmp.achievement_levels.extended, rep(NA, length(tmp.additional.low)))
				tmp.sgp.extended <- c(tmp.sgp.extended, rep(NA, length(tmp.additional.low)))
				tmp.sgp_levels.extended <- c(tmp.sgp_levels.extended, rep(NA, length(tmp.additional.low)))
			} else {
				tmp.additional.low.length <- 0 
			}

			if (any(is.na(tmp.grades.extended))) {
				tmp.na <- which(is.na(tmp.grades.extended))
				for (i in tmp.na) {
					tmp.grades.extended[i] <- grades.content_areas.reported.in.state$GRADE_NUMERIC[
						match(tmp.grades.extended[i-1], grades.content_areas.reported.in.state$GRADE_NUMERIC)]
				}
				if (length(intersect(tmp.na, which(!is.na(suppressWarnings(as.numeric(tmp.grades.extended)))))) > 0) {
					tmp.indices <- intersect(tmp.na, which(!is.na(suppressWarnings(as.numeric(tmp.grades.extended)))))
					tmp.grades.extended[tmp.indices] <- NA
					tmp.grades.extended[tmp.indices] <- round(approx(suppressWarnings(as.numeric(tmp.grades.extended)), xout=tmp.indices)$y)
				}
			}

			for (i in seq_along(tmp.grades.extended)) {
				tmp.list[[i]] <- list(
						Grade=rev(convert.grades(tmp.grades.extended, to="GRADE"))[i],
						Scale_Score=rev(tmp.scale_scores.extended)[i],
						Plotting_Scale_Score=rev(tmp.plotting_scale_scores.extended)[i],
						Achievement_Level=rev(tmp.achievement_levels.extended)[i],
						SGP=rev(tmp.sgp.extended)[i],
						SGP_Level=rev(tmp.sgp_levels.extended)[i],
						Content_Area=rev(tmp.content_areas.extended)[i],
						Year=rev(tmp.years.extended)[i])
			}

			tmp.list[['Report_Parameters']] <- list(First_Score_Index=tmp.additional.low.length+1, Last_Score_Index=tmp.additional.low.length+length(tmp.grades))

			return(tmp.list)
		} ### END interpolate.extend.data


		getJSON.percentile_trajectories_Internal <- function(sgPlot.data, percentile.trajectory.values, year, state) {

			.create.path <- function(labels, pieces=c("my.subject", "my.year", "my.extra.label")) {
				sub(' ', '_', toupper(sub('\\.+$', '', paste(unlist(sapply(labels[pieces], as.character)), collapse="."))))
			}

			tmp.indices <- seq(which(year==rev(tmp.data$Years)))
			tmp.df <- data.frame(matrix(c(1, rev(tmp.data$Grades)[tmp.indices], rev(tmp.data$Scale_Scores)[tmp.indices]), nrow=1), stringsAsFactors=FALSE)
			for (j in seq(to=dim(tmp.df)[2], length=(dim(tmp.df)[2]-1)/2)) {
				tmp.df[[j]] <- as.numeric(tmp.df[[j]])
			}
			gaPlot.sgp_object@SGP$Panel_Data <- tmp.df
			gaPlot.sgp_object@SGP$SGProjections <- NULL
			tmp.grades <- as.numeric(tmp.df[1,2:((dim(tmp.df)[2]+1)/2)])
			if (baseline) my.extra.label <- "BASELINE" else my.extra.label <- NULL

			studentGrowthProjections(
				panel.data=gaPlot.sgp_object@SGP,
				sgp.labels=list(my.year=year, my.subject=content_area, my.extra.label=my.extra.label),
#				grade.progression=
#				content_area.progression=
#				year_lags.progression=
				grade.projection.sequence=SGPstateData[[state]][["SGP_Configuration"]][["grade.projection.sequence"]][[content_area]],
				content_area.projection.sequence=SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[content_area]],
				year_lags.projection.sequence=SGPstateData[[state]][["SGP_Configuration"]][["year_lags.projection.sequence"]][[content_area]],
				projcuts.digits=2,
				projection.unit="GRADE",
				percentile.trajectory.values=percentile.trajectory.values,
				grade.progression=tmp.grades,
				max.forward.progression.grade=gaPlot.grade_range[2],
				max.order.for.progression=gaPlot.max.order.for.progression,
				print.time.taken=FALSE)[["SGProjections"]][[.create.path(list(my.subject=content_area, my.year=year, my.extra.label=my.extra.label))]][,-1]
		} ### END getJSON.percentile_trajectories_Internal

		year.extend <- function(year , add.sub) {
			if (length(grep("_", year) > 0)) {
				tmp <- as.numeric(unlist(strsplit(as.character(year), "_"))[2])+add.sub
				return(paste(tmp-1, tmp, sep="_"))
			} else {
				return(as.character(as.numeric(year)+add.sub))
			}
		}

		get.my.cutscores <- function(cutscores, content_area, year, grade) {
			tmp.cutscores <- data.table(cutscores[CONTENT_AREA==content_area & GRADE==grade], key="CUTLEVEL")
			if (!all(is.na(tmp.cutscores$YEAR))) {
				tmp.cutscore.years <- unique(cutscores$YEAR)
				if (year %in% tmp.cutscore.years) {
					tmp.cutscores <- data.table(tmp.cutscores[YEAR==year], key="CUTLEVEL")
				} else {
					if (year==sort(c(year, tmp.cutscore.years))[1]) {
						tmp.cutscores <- data.table(tmp.cutscores[is.na(YEAR)], key="CUTLEVEL")
					} else {
						tmp.year <- sort(tmp.cutscore.years)[which(year==sort(c(year, tmp.cutscore.years)))-1]
						tmp.cutscores <- data.table(tmp.cutscores[YEAR==tmp.year], key="CUTLEVEL")
					}
				}
			}
			return(c(tmp.cutscores[CUTLEVEL=="LOSS"]$CUTSCORE, tmp.cutscores[!CUTLEVEL %in% c("LOSS", "HOSS")]$CUTSCORE, tmp.cutscores[CUTLEVEL=="HOSS"]$CUTSCORE))
		}

		### Create grades.content_areas.reported.in.state
	
		if (!is.null(SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[content_area]])) {
			grades.content_areas.reported.in.state <- data.frame(
						GRADE=SGPstateData[[state]][["SGP_Configuration"]][["grade.projection.sequence"]][[content_area]],
						YEAR_LAG=c(1, SGPstateData[[state]][["SGP_Configuration"]][["year_lags.projection.sequence"]][[content_area]]),
						CONTENT_AREA=SGPstateData[[state]][["SGP_Configuration"]][["content_area.projection.sequence"]][[content_area]], 
						stringsAsFactors=FALSE
						)
		} else {
			grades.content_areas.reported.in.state <- data.frame(
					GRADE=SGPstateData[[state]][["Student_Report_Information"]][["Grades_Reported"]][[content_area]],
					YEAR_LAG=c(1, diff(as.numeric(SGPstateData[[state]][["Student_Report_Information"]][["Grades_Reported"]][[content_area]]))),
					CONTENT_AREA=content_area, 
					stringsAsFactors=FALSE
					)
		}
		grades.content_areas.reported.in.state$GRADE_NUMERIC <- as.numeric(grades.content_areas.reported.in.state$GRADE[1])+c(0, cumsum(tail(grades.content_areas.reported.in.state$YEAR_LAG, -1)))
		grades.content_areas.reported.in.state$GRADE_NUMERIC <- (as.numeric(grades.content_areas.reported.in.state$GRADE[2])-1)+c(0, cumsum(tail(grades.content_areas.reported.in.state$YEAR_LAG, -1)))


		### Create and restructure list to be converted to JSON

		tmp.data.extended <- interpolate.extend.data(tmp.data, grades.content_areas.reported.in.state)

		for (i in which(names(tmp.data.extended)!="Report_Parameters")) {
			tmp.data.extended[[i]][['Cutscores']] <- get.my.cutscores(tmp.data$Cutscores, tmp.data.extended[[i]]$Content_Area, tmp.data.extended[[i]]$Year, tmp.data.extended[[i]]$Grade)
		}
		
		### Add in Percentile_Trajectories, SGP_Targets, SGP_Targets_Scale_Scores 

		for (i in years.for.percentile.trajectories) {

			### Percentile_Trajectories

			tmp.index <- which(i==unlist(sapply(tmp.data.extended, '[[', 'Year')))
			tmp.data.extended[[tmp.index]][['Percentile_Trajectories']] <- getJSON.percentile_trajectories_Internal(
												sgPlot.data=tmp.data, 
												percentile.trajectory.values=1:99, 
												year=i, 
												state=state)

			################################################
			### HACK
			################################################

			tmp.matrix <- matrix(NA, nrow=max(which(names(tmp.data.extended)!="Report_Parameters"))-tmp.index+1, ncol=100)
			tmp.matrix[1,] <- rep(tmp.data.extended[[tmp.index]]$Scale_Score, dim(tmp.matrix)[2])
			for (k in seq(2, max(which(names(tmp.data.extended)!="Report_Parameters"))-tmp.index+1)) {
				tmp.matrix[k,] <- round(seq(tmp.data.extended[[tmp.index]]$Scale_Score-20*(k-1), tmp.data.extended[[tmp.index]]$Scale_Score+20*(k-1), length=100), digits=1)
			}
			tmp.data.extended[[tmp.index]][['Percentile_Trajectories']] <- as.list(as.data.frame(tmp.matrix))

			### SGP_Targets

			tmp.num.targets <- dim(tmp.matrix)[1]-1
			tmp.data.extended[[tmp.index]][['SGP_Targets']] <- list(Catch_Up_Keep_Up=round(seq(70, 50, length=tmp.num.targets)), Move_Up_Stay_Up=round(seq(90, 70, length=tmp.num.targets)))
			if (tmp.data.extended[[tmp.index]][['Achievement_Level']] %in% c("Unsatisfactory", "Partially Proficient")) {
				tmp.data.extended[[tmp.index]][['SGP_Targets']][['Move_Up_Stay_Up']] <- rep(NA, length=tmp.num.targets)
			}

			### SGP_Targets_Scale_Scores

			tmp.cuku.list <- tmp.musu.list <- list()
			for (k in seq_along(tmp.data.extended[[tmp.index]][['SGP_Targets']][['Catch_Up_Keep_Up']])) {
				tmp.cuku.list[[k]] <- round(tmp.matrix[k+1, tmp.data.extended[[tmp.index]][['SGP_Targets']][['Catch_Up_Keep_Up']][k]])
				if (!tmp.data.extended[[tmp.index]][['Achievement_Level']] %in% c("Unsatisfactory", "Partially Proficient")) {
					tmp.musu.list[[k]] <- round(tmp.matrix[k+1, tmp.data.extended[[tmp.index]][['SGP_Targets']][['Move_Up_Stay_Up']][k]])
				} else {
					tmp.musu.list[[k]] <- as.numeric(NA)
				}
				tmp.data.extended[[tmp.index]][['SGP_Targets_Scale_Scores']] <- list(Catch_Up_Keep_Up=unlist(tmp.cuku.list), Move_Up_Stay_Up=unlist(tmp.musu.list))
			}
			##############################################
			### END HACK
			##############################################
		}


		### Add in Report Parameters

		tmp.data.extended[['Report_Parameters']] <- c(tmp.data.extended[['Report_Parameters']], "TEMP")


		### Return list

		return(tmp.data.extended)	

	} ### END if (data.type=="studentGrowthPlot")

} ### END getJSON
