#' @importFrom stats na.omit
#' @import tidytext
# This is a set of functions to generate a package name, given the title of the package

#' Pick word from title
#'
#' picks a single (hopefully informative) word from the provided title or package discription
#'
#' @param title text string to pick word from. Pakage title or discription.
#' @param verb whether you would like to prioritize returning a verb
#'
#' @return a single word from the title
#'
#'
#' @export
pick_word_from_title <- function(title, verb = F) {
  # to lower case
  title <- tolower(title)

  # convert to vector of words

  word_vector <- unlist(strsplit(title, "[[:space:]]+"))
  if (length(word_vector) == 0) {
    return(character())
  }

  # remove R-specific stopwords, things that are commonly in package titles but
  # aren't helpful for telling you what the package is about
  R_stop_words <- c("libr", "analys", "class", "method",
                    "object", "model", "import", "data", "function", "format", "plug-in",
                    "plugin", "api", "client", "access", "interfac", "tool", "comput", "help",
                    "calcul", "tool", "read", "stat", "math", "numer", "file", "plot",
                    "wrap", "read", "writ", "pack", "dist", "algo", "code", "frame", "viz",
                    "vis", "auto", "explor", "funct", "esti", "equa", "bayes", "learn")

  # remove English stop words
  english_stop_words <- tidytext::stop_words$word

  word_vector <- word_vector[!word_vector %in% c(english_stop_words)]

  word_vector <- word_vector[!grepl(glue::collapse(R_stop_words, "|"), word_vector)]

  # remove very long words (> 15 characters)
  # remove very short words (< 5 characters)
  word_vector <- word_vector[nchar(word_vector) < 15 | nchar(word_vector) > 5]

  package_name <- character()

  # pick the first verb (if the user has requested a verb) or the longest edge word (< 15 characters)
  if(length(word_vector) > 1){
    # get the part of speech for every word left in our vector
    POS <- apply(as.matrix(word_vector), 1,
           function(x){tidytext::parts_of_speech$pos[tidytext::parts_of_speech$word == x][1]})
    first <- word_vector[1]
    last <- word_vector[length(word_vector)]
    #print(POS)
    if(sum(grepl("Verb", POS)) > 0 && verb){
      package_name <- word_vector[grepl("Verb", POS)][1]
      #print(word_vector[POS == "Verb"][1])
    }else if(nchar(last) > nchar(first)){
      package_name <- last
    }else{
      package_name <- first
    }
  }

  # make sure we always return a package name
  if(length(word_vector) == 1){
    package_name <- word_vector[1]
  }

  # remove punctuation
  package_name <- gsub("[[:punct:]]", "", package_name)

  # make sure
  if(length(package_name) == 0) {
    stop("Sorry, we couldn't make a good name from your tile. Try using more specific words in your description.")
  }

  package_name
}

# # test: should return "intro.js" & "introjs"
# pick_word_from_title(title = "wrapper for the intro.js library")
# pick_word_from_title("wrapper for the intro.js library", remove_punct = T)



#' Spelling transformations
#'
#' This function takes in a single word and applies spelling transformations to make it more "r-like" 
#' and easier to Google
#'
#' @param word a single word to make more rlike
#'
#' @return a single word with a spelling transformation
#'
#'
#' @export
make_spelling_rlike <- function(word){
  # convert string into vector of lowercase characters
  chars <- unlist(strsplit(tolower(word),""))

  # list of vowels
  vowels <- c("a","e","i","o","u")

  # set a variable that tells us whether we've made a spelling transformation
  spelling_changed <- F

  # remove second to last letter if it's a vowel and the last letter is r
  if(chars[length(chars) -1] %in% vowels & chars[length(chars)] == "r"){
    chars <- chars[-(length(chars) - 1)]
    spelling_changed <- T
  }

  # if the first letter is a vowel and the second letter is an r, remove the first letter
  if(chars[1] %in% vowels & chars[2] == "r" & spelling_changed == F){
    chars <- chars[-1]
    spelling_changed <- T
  }

  # if the word ends with an r but there isn't a vowel in front of it, add an r to the beginning
  if(chars[length(chars) -1] %in% vowels == F & chars[length(chars)] == "r"& spelling_changed == F){
    chars <- c("r", chars)
    spelling_changed <- T
  }

  # if there hasn't been a spelling change, add an "r" to the end
  if(spelling_changed == F){
    chars <- c(chars, "r")
  }

  return(paste(unlist(chars), collapse = ""))
}

# # testing function.
# make_spelling_rlike("tidy") # Should return "tidyr"
# make_spelling_rlike("archive") #should retun rchive
# make_spelling_rlike("reader") # should return readr
# make_spelling_rlike("instr") # should return rinstr


#' Add common suffixes
#'
#' Search a title for common terms (plot, vis..., viz..., markdown) and apply
#' appropriate affixes to a given word as appliable.
#'
#' @param title the package title or discription
#' @param name the single word that will be appended to
#'
#' @return a single word with affix, if applicable
#'
#'
#' @export
# function to add common, informative suffixes
common_suffixes <- function(title, name){
  # add "plot", "viz" or "vis" to the end of the package name if that appears in the title
  if(grepl("\\<tidy",title, ignore.case = T)){
    return(paste(c("tidy",name), collapse = ""))
  }
  if(grepl("\\<viz",title, ignore.case = T)){
    return(paste(c(name, "viz"), collapse = ""))
  }
  if(grepl("\\<vis",title, ignore.case = T)){
    return(paste(c(name, "vis"), collapse = ""))
  }
  if(grepl("\\<plot",title, ignore.case = T)){
    return(paste(c(name, "plot"), collapse = ""))
  }
  if(grepl("\\<markdown",title, ignore.case = T)){
    return(paste(c(name, "down"), collapse = ""))
  }
  return(name)
}

# #testing fuction
# plot_vis_add_to_name("package for plotting things","my") # should return "myplot"
# plot_vis_add_to_name("vizulier 2000 the reboot","my") # should return "myviz"

#' Function that finds and returns the first acronym (all caps) in a text string
#'
#'
#' @param title package title or discription
#'
#' @return a single acronym, if present
#'
#'
#' @export
find_acronym <- function(title){
  # split string
  title_vector <- unlist(strsplit(title, " "))

  # return all
  acronyms <- title_vector[grep("^[[:upper:]]{2,}$", title_vector)]

  # check to make sure it's not already the title
  word <- pick_word_from_title(title)

  # make sure we don't have a name with reduplication
  if(word %in% tolower(acronyms)){
    stop("Title is already acronym.")
  }

  # return the first acronym from the title
  return(acronyms[1])
}

#' Suggest package name
#'
#'  
#'
#' @param title the package title or discription
#' @param acronym whether to include an acronym (if there is one) in the title
#' @param verb whether to prioritize using a verb in the package title
#' 
#' @return a single word to use as a package title
#'
#' @export
namr <- function(title, acronym = F, verb = F, ...){
  name <- pick_word_from_title(title, verb = verb, ...)
  name <- make_spelling_rlike(name)
  if(acronym){
    name <- paste(c(name, find_acronym(title)), collapse = "")
  }
  name <- common_suffixes(title, name)
  return(name)
}


# # some real  test examples
# namr("A Package for Displaying Visual Scenes as They May Appear to an Animal with Lower Acuity")
# namr("Analysis of Ecological Data : Exploratory and Euclidean Methods in Environmental Sciences")
# namr("Population Assignment using Genetic, Non-Genetic or Integrated Data in a Machine Learning Framework")
