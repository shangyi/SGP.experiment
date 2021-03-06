`getPanelData` <- 
function(sgp.data,
	sgp.type,
	sgp.iter,
	sgp.csem=NULL,
	sgp.targets=NULL) {

	YEAR <- CONTENT_AREA <- VALID_CASE <- V3 <- V5 <- ID <- GRADE <- SCALE_SCORE <- YEAR_WITHIN <- tmp.timevar <- FIRST_OBSERVATION <- LAST_OBSERVATION <- ACHIEVEMENT_LEVEL <- NULL

	if (sgp.type=="sgp.percentiles") {

		if ("YEAR_WITHIN" %in% names(sgp.data)) {
			tmp.lookup <- data.table(V1="VALID_CASE", tail(sgp.iter[["sgp.content.areas"]], length(sgp.iter[["sgp.grade.sequences"]])),
				tail(sgp.iter[["sgp.panel.years"]], length(sgp.iter[["sgp.grade.sequences"]])), sgp.iter[["sgp.grade.sequences"]],
				tail(sgp.iter[["sgp.panel.years.within"]], length(sgp.iter[["sgp.grade.sequences"]])), FIRST_OBSERVATION=as.integer(NA), LAST_OBSERVATION=as.integer(NA))
			tmp.lookup[grep("FIRST", V5, ignore.case=TRUE), FIRST_OBSERVATION:=1L]; tmp.lookup[grep("LAST", V5, ignore.case=TRUE), LAST_OBSERVATION:=1L]; tmp.lookup[,V5:=NULL]
			setnames(tmp.lookup, paste("V", 1:4, sep=""), c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE"))
			
			tmp.lookup.list <- list()
			for (i in unique(sgp.iter[["sgp.panel.years.within"]])) {
				setkeyv(sgp.data, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				setkeyv(tmp.lookup, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				suppressWarnings(tmp.lookup.list[[i]] <- data.table(sgp.data[tmp.lookup[get(i)==1], nomatch=0][,'tmp.timevar':=paste(YEAR, CONTENT_AREA, i, sep="."), with=FALSE][,
					list(ID, GRADE, SCALE_SCORE, YEAR_WITHIN, tmp.timevar)], key="ID")) ### Could be NULL and result in a warning
			}
			if (tail(sgp.iter[['sgp.panel.years']], 1)==head(tail(sgp.iter[['sgp.panel.years']], 2), 1)) {
				tmp.ids <- intersect(tmp.lookup.list[[1]][['ID']], tmp.lookup.list[[2]][['ID']])
				tmp.ids <- tmp.ids[tmp.lookup.list[[1]][tmp.ids][['YEAR_WITHIN']] < tmp.lookup.list[[2]][tmp.ids][['YEAR_WITHIN']]]
				tmp.lookup.list <- lapply(tmp.lookup.list, function(x) x[tmp.ids])
			}
			return(as.data.frame(reshape(
				rbindlist(tmp.lookup.list),
					idvar="ID", 
					timevar="tmp.timevar", 
					drop=names(sgp.data)[!names(tmp.lookup.list[[1]]) %in% c("ID", "GRADE", "SCALE_SCORE", "YEAR_WITHIN", "tmp.timevar", sgp.csem)], 
					direction="wide")))
		} else {
			tmp.lookup <- SJ("VALID_CASE", tail(sgp.iter[["sgp.content.areas"]], length(sgp.iter[["sgp.grade.sequences"]])),
				tail(sgp.iter[["sgp.panel.years"]], length(sgp.iter[["sgp.grade.sequences"]])), sgp.iter[["sgp.grade.sequences"]])
			# ensure lookup table is ordered by years.  NULL out key after sorted so that it doesn't corrupt the join in reshape.
			setkey(tmp.lookup, V3)
			setkey(tmp.lookup, NULL)

			return(as.data.frame(reshape(
				sgp.data[tmp.lookup, nomatch=0][,'tmp.timevar':=paste(YEAR, CONTENT_AREA, sep="."), with=FALSE],
					idvar="ID",
					timevar="tmp.timevar",
					drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar", sgp.csem)],
					direction="wide")))
		}
	} ### END if (sgp.type=="sgp.percentiles")


	if (sgp.type=="sgp.projections") {
		if ("YEAR_WITHIN" %in% names(sgp.data)) {
			tmp.lookup <- data.table(V1="VALID_CASE", tail(sgp.iter[["sgp.projection.content.areas"]], length(sgp.iter[["sgp.projection.grade.sequences"]])),
				sapply(head(sgp.iter[["sgp.panel.years"]], length(sgp.iter[["sgp.projection.grade.sequences"]])), yearIncrement, tail(sgp.iter$sgp.panel.years.lags, 1)),
				sgp.iter[["sgp.projection.grade.sequences"]], head(sgp.iter[["sgp.panel.years.within"]], length(sgp.iter[["sgp.projection.grade.sequences"]])), 
				FIRST_OBSERVATION=as.integer(NA), LAST_OBSERVATION=as.integer(NA))
			tmp.lookup[grep("FIRST", V5, ignore.case=TRUE), FIRST_OBSERVATION:=1L]; tmp.lookup[grep("LAST", V5, ignore.case=TRUE), LAST_OBSERVATION:=1L]; tmp.lookup[,V5:=NULL]
			setnames(tmp.lookup, paste("V", 1:4, sep=""), c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE"))
			
			tmp.lookup.list <- list()
			for (i in unique(sgp.iter[["sgp.panel.years.within"]])) {
				setkeyv(sgp.data, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				setkeyv(tmp.lookup, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				suppressWarnings(tmp.lookup.list[[i]] <- data.table(sgp.data[tmp.lookup[get(i)==1], nomatch=0][,'tmp.timevar':=paste(YEAR, CONTENT_AREA, i, sep="."), with=FALSE][,
					list(ID, GRADE, SCALE_SCORE, YEAR_WITHIN, tmp.timevar)], key="ID")) ### Could be NULL and result in a warning
			}
			if (tail(sgp.iter[['sgp.panel.years']], 1)==head(tail(sgp.iter[['sgp.panel.years']], 2), 1)) {
				tmp.ids <- intersect(tmp.lookup.list[[1]][['ID']], tmp.lookup.list[[2]][['ID']])
				tmp.ids <- tmp.ids[tmp.lookup.list[[1]][tmp.ids][['YEAR_WITHIN']] < tmp.lookup.list[[2]][tmp.ids][['YEAR_WITHIN']]]
				tmp.lookup.list <- lapply(tmp.lookup.list, function(x) x[tmp.ids])
			}
			if (is.null(sgp.targets)) {
				tmp.data <- reshape(
					rbindlist(tmp.lookup.list),
					idvar= "ID",
					timevar="tmp.timevar",
					drop=names(sgp.data)[!names(tmp.lookup.list[[1]]) %in% c("ID", "GRADE", "SCALE_SCORE", "YEAR_WITHIN", "tmp.timevar")], 
					direction="wide")
				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			} else {
				tmp.data <- data.table(reshape(
					rbindlist(tmp.lookup.list),
					idvar= "ID",
					timevar="tmp.timevar",
					drop=names(sgp.data)[!names(tmp.lookup.list[[1]]) %in% c("ID", "GRADE", "SCALE_SCORE", "YEAR_WITHIN", "tmp.timevar")], 
					direction="wide"), key="ID")[sgp.targets[CONTENT_AREA==tail(sgp.iter[["sgp.projection.content.areas"]], 1) & YEAR==tail(sgp.iter[["sgp.panel.years"]], 1)], nomatch=0][,
						!c("CONTENT_AREA", "YEAR"), with=FALSE]
				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			}
		}
		tmp.lookup <- SJ("VALID_CASE", sgp.iter[["sgp.projection.content.areas"]], 
			tail(sgp.iter[["sgp.panel.years"]], length(sgp.iter[["sgp.projection.grade.sequences"]])), sgp.iter[["sgp.projection.grade.sequences"]])
		# ensure lookup table is ordered by years.  NULL out key after sorted so that it doesn't corrupt the join in reshape.
		setkey(tmp.lookup, V3)
		setkey(tmp.lookup, NULL)
		if (is.null(sgp.targets)) {
			tmp.data <- reshape(
				sgp.data[tmp.lookup, nomatch=0][, 'tmp.timevar' := paste(YEAR, CONTENT_AREA, sep="."), with=FALSE],
				idvar="ID",
				timevar="tmp.timevar",
				drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar")],
				direction="wide")
			if ("STATE" %in% names(sgp.data)) {
				tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
				tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
				tmp.data[, VALID_CASE := "VALID_CASE"]
				setkeyv(tmp.data, getKey(sgp.data))
				tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
				tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
				tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
				setkeyv(sgp.data, tmp.key)
			}
			return(as.data.frame(tmp.data))
		} else {
			tmp.data <- data.table(reshape(
					sgp.data[tmp.lookup, nomatch=0][, 'tmp.timevar' := paste(YEAR, CONTENT_AREA, sep="."), with=FALSE],
				idvar="ID",
				timevar="tmp.timevar",
				drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar")],
				direction="wide"), key="ID")[sgp.targets[CONTENT_AREA==tail(sgp.iter[["sgp.projection.content.areas"]], 1) & YEAR==tail(sgp.iter[["sgp.panel.years"]], 1)], nomatch=0][,
					!c("CONTENT_AREA", "YEAR"), with=FALSE]
			if ("STATE" %in% names(sgp.data)) {
				tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
				tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
				tmp.data[, VALID_CASE := "VALID_CASE"]
				setkeyv(tmp.data, getKey(sgp.data))
				tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
				tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
				tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
				setkeyv(sgp.data, tmp.key)
			}
			return(as.data.frame(tmp.data))
		}
	} ### END if (sgp.type=="sgp.projections")


	if (sgp.type=="sgp.projections.lagged") {
		if ("YEAR_WITHIN" %in% names(sgp.data)) {
			setkeyv(sgp.data, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", tail(sgp.iter[["sgp.panel.years.within"]], 1)))
			tmp.ids <- sgp.data[SJ("VALID_CASE", tail(sgp.iter[["sgp.content.areas"]], 1), tail(sgp.iter[["sgp.panel.years"]], 1), 
				tail(sgp.iter[["sgp.grade.sequences"]], 1), 1)][,"ID", with=FALSE]
			tmp.data <- data.table(sgp.data, key="ID")[tmp.ids]
			tmp.lookup <- data.table(V1="VALID_CASE", tail(sgp.iter[["sgp.projection.content.areas"]], length(sgp.iter[["sgp.projection.grade.sequences"]])),
				head(sgp.iter[["sgp.panel.years"]], length(sgp.iter[["sgp.projection.grade.sequences"]])), sgp.iter[["sgp.projection.grade.sequences"]],
				head(sgp.iter[["sgp.panel.years.within"]], length(sgp.iter[["sgp.projection.grade.sequences"]])), FIRST_OBSERVATION=as.integer(NA), LAST_OBSERVATION=as.integer(NA))
			tmp.lookup[grep("FIRST", V5, ignore.case=TRUE), FIRST_OBSERVATION:=1L]; tmp.lookup[grep("LAST", V5, ignore.case=TRUE), LAST_OBSERVATION:=1L]; tmp.lookup[,V5:=NULL]
			setnames(tmp.lookup, paste("V", 1:4, sep=""), c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE"))
			
			tmp.lookup.list <- list()
			for (i in unique(sgp.iter[["sgp.panel.years.within"]])) {
				setkeyv(tmp.data, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				setkeyv(tmp.lookup, c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE", i))
				suppressWarnings(tmp.lookup.list[[i]] <- data.table(tmp.data[tmp.lookup[get(i)==1], nomatch=0][,'tmp.timevar':=paste(YEAR, CONTENT_AREA, i, sep="."), with=FALSE][,
					list(ID, GRADE, SCALE_SCORE, YEAR_WITHIN, tmp.timevar, ACHIEVEMENT_LEVEL)], key="ID")) ### Could be NULL and result in a warning
			}		
			achievement.level.prior.vname <- paste("ACHIEVEMENT_LEVEL", tail(head(sgp.iter[["sgp.panel.years"]], -1), 1), tail(head(sgp.iter[["sgp.content.areas"]], -1), 1), sep=".")	
			if (is.null(sgp.targets)) {
				tmp.data <- reshape(
					rbindlist(tmp.lookup.list),
					idvar="ID",
					timevar="tmp.timevar",
					drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar", "ACHIEVEMENT_LEVEL")],
					direction="wide")
				setnames(tmp.data, names(tmp.data)[grep(achievement.level.prior.vname, names(tmp.data))], achievement.level.prior.vname)
				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			} else {
				tmp.data <- data.table(reshape(
					rbindlist(tmp.lookup.list),
					idvar="ID",
					timevar="tmp.timevar",
					drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar", "ACHIEVEMENT_LEVEL")],
					direction="wide"), key="ID")[sgp.targets[CONTENT_AREA==tail(sgp.iter[["sgp.content.areas"]], 1) & YEAR==tail(sgp.iter[["sgp.panel.years"]], 1)], nomatch=0][, 
						!c("CONTENT_AREA", "YEAR"), with=FALSE]
				setnames(tmp.data, names(tmp.data)[grep(achievement.level.prior.vname, names(tmp.data))], achievement.level.prior.vname)
				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			}
		} else {
			if (is.null(sgp.targets)) {
				tmp.data <- reshape(
					data.table(
						data.table(sgp.data, key="ID")[
							sgp.data[SJ("VALID_CASE", 
							tail(sgp.iter[["sgp.content.areas"]], 1), 
							tail(sgp.iter[["sgp.panel.years"]], 1), 
							tail(sgp.iter[["sgp.grade.sequences"]], 1))][,"ID", with=FALSE]], 
					key=c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE"))[
					SJ("VALID_CASE", sgp.iter[["sgp.projection.content.areas"]],
						tail(head(sgp.iter[["sgp.panel.years"]], -1), length(sgp.iter[["sgp.projection.grade.sequences"]])),
						sgp.iter[["sgp.projection.grade.sequences"]]), nomatch=0][,
						'tmp.timevar' := paste(YEAR, CONTENT_AREA, sep="."), with=FALSE],
				idvar="ID",
				timevar="tmp.timevar",
				drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar", "ACHIEVEMENT_LEVEL")],
				direction="wide")

				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			} else {
				tmp.data <- data.table(reshape(
					data.table(
						data.table(sgp.data, key="ID")[
							sgp.data[SJ("VALID_CASE", 
							tail(sgp.iter[["sgp.content.areas"]], 1), 
							tail(sgp.iter[["sgp.panel.years"]], 1), 
							tail(sgp.iter[["sgp.grade.sequences"]], 1))][,"ID", with=FALSE]], 
					key=c("VALID_CASE", "CONTENT_AREA", "YEAR", "GRADE"))[
					SJ("VALID_CASE", sgp.iter[["sgp.projection.content.areas"]], 
						tail(head(sgp.iter[["sgp.panel.years"]], -1), length(sgp.iter[["sgp.projection.grade.sequences"]])),
						sgp.iter[["sgp.projection.grade.sequences"]]), nomatch=0][,
						'tmp.timevar' := paste(YEAR, CONTENT_AREA, sep="."), with=FALSE],
				idvar="ID",
				timevar="tmp.timevar",
				drop=names(sgp.data)[!names(sgp.data) %in% c("ID", "GRADE", "SCALE_SCORE", "tmp.timevar", "ACHIEVEMENT_LEVEL")],
				direction="wide"), key="ID")[sgp.targets[CONTENT_AREA==tail(sgp.iter[["sgp.content.areas"]], 1) & YEAR==tail(sgp.iter[["sgp.panel.years"]], 1)], nomatch=0][,
					!c("CONTENT_AREA", "YEAR"), with=FALSE]

				if ("STATE" %in% names(sgp.data)) {
					tmp.data[, YEAR := tail(sgp.iter[['sgp.panel.years']], 1)]
					tmp.data[, CONTENT_AREA := tail(sgp.iter[['sgp.projection.content.areas']], 1)]
					tmp.data[, VALID_CASE := "VALID_CASE"]
					setkeyv(tmp.data, getKey(sgp.data))
					tmp.key <- key(sgp.data); setkeyv(sgp.data, getKey(sgp.data))
					tmp.data <- sgp.data[, c(getKey(sgp.data), "STATE"), with=FALSE][tmp.data]
					tmp.data[, c("YEAR", "CONTENT_AREA", "VALID_CASE") := NULL]
					setkeyv(sgp.data, tmp.key)
				}
				return(as.data.frame(tmp.data))
			}
		}
	} ### END if (sgp.type=="sgp.projections.lagged")
} ## END getPanelData
