#' @title Package script
#' @description Reformat script to fit package
#' @param filename name of the file
#' @param chap_num chapter number
#' @param saveOutput if `TRUE`, original is printed and `filename` is overwritten. Defaults to `FALSE`, in which case reformatted file is printed
#' @param tabIndent if `TRUE`, replaces spaced indentation with tabs
#' @return text converted to R, printed to screen or replacing input file
#' @note This function is used to expedite conversion of the original scripts
#' into a package format
#' @author Waldir Leoncio
#' @importFrom utils write.table
reformat <- function(filename, chap_num, saveOutput = FALSE, tabIndent = TRUE) {

	# ======================================================== #
	# Verification                                             #
	# ======================================================== #
	if (!file.exists(filename)) stop("File not found")

	# ======================================================== #
	# Reading file into R                                      #
	# ======================================================== #
	txt <- readLines(filename, warn = FALSE)
	if (substr(txt[1], 1, 9) == "#' @title") {
		stop(
			"I think this File has already been reformatted. ",
			"Please check the file name. Stopping."
		)
	}
	orig <- txt

	# ======================================================== #
	# Converting code                                          #
	# ======================================================== #

	# Function documentation --------------------------------- #
	fun_name <- NA
	l <- 1
	while (is.na(fun_name)) {
		if (nchar(txt[l]) > 1 & substring(txt[l], 1, 1) != "#") {
			fun_name <- gsub("(.+)\\s+=\\s+function\\(.+", "\\1", txt[l])
		}
		l <- l + 1
	}
	chap_line <- which(grepl(".+Chapter (\\d{1,2}) .+", txt))
	if (missing(chap_num)) {
		chap_num <- sub(".+Chapter (\\d{1,2}) .+", "\\1", txt[chap_line])
		print(chap_num)
	}
	if (length(chap_num) == 0) {
		stop("Chapter number not found. Please provide it manually.")
	}
	if (length(chap_line) > 0) {
		for (cl in seq_len(chap_line) - 1) {
			txt[chap_line - cl] <- gsub(
				"#", "#' @description", txt[chap_line - cl]
			)
		}
	}
	txt <- gsub("\\s*#$", "", txt)

	# Function arguments, general ---------------------------- #
	txt <- gsub("# Input arguments", "", txt)
	txt <- gsub("# ---------------", "", txt)
	txt <- gsub("#\\s{2,4}X", "X", txt)

	# Function examples --------------------------------------- #
	# TODO: replace these with gsubs for 1, 2 and 3 args?
	if (chap_num <= 3) {
		txt <- gsub(
			pattern = "X = (\\d+); n = (\\d+).+# Example:",
			replacement = paste0(fun_name, "(X=\\1, n=\\2) #"),
			x = txt
		)
		txt <- gsub(
			pattern = "X = (\\d+); n = (\\d+); pi0 = 0.(\\d+)\\s+# Example:",
			replacement = paste0(fun_name, "(X=\\1, n=\\2, pi0=0.\\3) #"),
			x = txt
		)
		txt <- gsub(
			pattern = "(n|pi0) = (.+)\\s{1,2}# Example:",
			replacement = paste0(fun_name, "(\\1=\\2) #"),
			x = txt
		)
		txt <- gsub(
			pattern = "\\s+if\\s*\\(.+(n|pi0)\\)\\) \\{",
			replacement = paste0("#' @examples load_chapter(", chap_num,")"),
			txt
		)
	} else {
		ex_line_1st <- which(
			grepl(
				pattern = "if \\(missing\\((n|a|direction)\\)\\)",
				x = txt
			)
		)
		ex_line_last <- which(grepl("}", txt))
		ex_line_last <- ex_line_last[ex_line_last > ex_line_1st][1]
		txt[ex_line_1st] <- paste0("#' @examples load_chapter(", chap_num, ")")
		txt[ex_line_last] <- paste0("#' unload_chapter(", chap_num, ")")
		ex_line_mid <- (ex_line_1st + 1):(ex_line_last - 1)
		txt[ex_line_mid] <- replaceInExample(txt, ex_line_mid, "\\s*", "#' ")
		txt[ex_line_mid] <- replaceInExample(txt, ex_line_mid, "#' # ", "#' ")
		txt[ex_line_mid] <- replaceInExample(txt, ex_line_mid, " = ", " <- ")
		rep_fun_ex <- rep(paste0("#' ", fun_name, "(n)"), length(ex_line_mid))
		new_mid <- as.vector(rbind(txt[ex_line_mid], rep_fun_ex))
		txt[ex_line_mid] <- ""
		txt <- append(txt, new_mid, after=ex_line_1st)
	}

	# Function arguments, specific ------------------------- #
	doc_lines <- which(grepl("#'", txt))
	txt[-doc_lines] <- gsub(
		pattern = ".*#\\s([^(E|H)]{,15})(:| =)(\\s?\\w{3,}.+[^;])$",
		replacement = "#' @param \\1\\3",
		x = txt[-doc_lines]
	)
	txt[-doc_lines] <- gsub(
		pattern = paste0(fun_name, "(\\(.+\\)) # (.+)"),
		replacement = paste0("#' # \\2\n#' ", fun_name, "\\1"),
		x = txt[-doc_lines]
	)
	txt <- gsub("\\s+#' (.+)", "#' \\1", txt)
	# TODO: identify arguments from whats inside parenthesis after fun_name

	# Function code, general ---------------------------------- #
	txt <- gsub("printresults=T)", "printresults=TRUE)", txt)
	txt <- gsub("printresults=F)", "printresults=FALSE)", txt)
	txt <- gsub("byrow=T)", "byrow=TRUE)", txt)
	txt <- gsub("byrow=T,", "byrow=TRUE,", txt)
	txt <- gsub("quote=F)", "quote=FALSE)", txt)
	txt <- gsub("F = no, T = yes", "FALSE = no, TRUE = yes", txt)
	txt <- gsub("(\\S)\\+(\\S)", "\\1 + \\2", txt)
	# txt <- gsub("(\\W)\\S\\-\\S(\\W)", "\\1 - \\2", txt) # TODO: reimplement
	txt <- gsub("(\\S)\\*(\\S)", "\\1 * \\2", txt)
	txt <- gsub("(\\S)\\/(\\S)", "\\1 / \\2", txt)
	txt <- gsub("(\\S)\\^(\\S)", "\\1 ^ \\2", txt)
	txt <- gsub("\\[(\\d),(\\d)\\]", "[\\1, \\2]", txt)
	txt <- gsub("source\\(.+\\)", "", txt) # TODO: remove lines containing source()

	# Assignment operator ------------------------------------ #
	txt <- gsub("^(\\s{4,})(\\w+)\\s=\\s", "\\1\\2 <- ", txt)
	txt <- gsub("^(\\s{4,})names\\((\\w+)\\)\\s=\\s", "\\1names(\\2) <- ", txt)
	txt <- gsub("^(.+)\\s=\\sfunction", "\\1 <- function", txt)

	# Indentation -------------------------------------------- #
	if (tabIndent) txt <- tabIndent(txt)

	# ======================================================== #
	# Putting documentation first                              #
	# ======================================================== #
	doc_lines <- which(grepl("#'", txt))
	txt <- c(txt[doc_lines], txt[-doc_lines])
	if (substr(txt[1], 1, 24) == "#' @description function") txt <- txt[-1]
	txt <- c(txt[1], txt)
	txt[1] <- gsub("description", "title", txt[1])

	# ======================================================== #
	# Making sure last line is empty                           #
	# ======================================================== #
	if (txt[length(txt)] == "}") txt <- append(txt, "")

	# ======================================================== #
	# Returning converted code                                 #
	# ======================================================== #
	if (!saveOutput) {
		message("This is what the contents of the file will look like:\n")
		return(cat(txt, sep="\n"))
		message("Rerun with saveOutput=TRUE to overwrite the file.")
	} else {
		message("This is what the original file looked like:\n")
		print(orig, quote=FALSE)
		message("File overwritten. Please compare with original content above.")
		return(
			write.table(
				x         = txt,
				file      = filename,
				quote     = FALSE,
				row.names = FALSE,
				col.names = FALSE
			)
		)
	}
}
# TODO: import diff functionality from rBAPS (extract as separate function 1st)
replaceInExample <- function(x, lines, pattern, new) {
	vapply(
		X = lines,
		FUN = function(l) sub(pattern, new, x[l]),
		FUN.VALUE = character(1)
	)
}
tabIndent <- function(txt) {
	txt <- gsub("^\\s{27,28}", "\t\t\t\t\t\t\t", txt) # indentation level 7
	txt <- gsub("^\\s{24}", "\t\t\t\t\t\t", txt) # indentation level 6
	txt <- gsub("^\\s{20}", "\t\t\t\t\t", txt) # indentation level 5
	txt <- gsub("^\\s{16}", "\t\t\t\t", txt) # indentation level 4
	txt <- gsub("^\\s{12}", "\t\t\t", txt) # indentation level 3
	txt <- gsub("^\\s{7,8}", "\t\t", txt) # indentation level 2
	txt <- gsub("^\\s{4}", "\t", txt) # indentation level 1
	return(txt)
}
