#' Helper functions to generate the RMD file
#' 
#' @description 
#' These functions help to generate the output rmarkdown file containing the filled out
#' CARE as a string without a template on the fly.
#'
#' @name render_document
#' @aliases NULL
NULL

#' @rdname render_document
composeRmd <- function(answers = NULL, sectionsList = NULL, headList = NULL, answerList = NULL, language_code = NULL, save_as = "pdf"){
  # Get subtitle
  subtitle <- "Checklist for responsible AI usage in research - Checklist Report"
  # Description of CARE
  description <- "The aim of this checklist is to provide a framework for researchers, publishers, and institutions to prepare and assess a responsible use of AI in research."
  # First, we create the YAML header of the rmd file (be carefully about indentation, can automatically generate another header which screws everything)
  headYaml <- stringr::str_glue(
"---
title: '{study_title}'
subtitle: '{sub_title}'
author: '{author_names}'
date: '{format(Sys.time(), '%d/%m/%Y')}'
header-includes:
  - \\usepackage{{ctex}}
  - \\setCJKmainfont{{Noto Serif CJK SC}}
  - \\usepackage{{fontspec}}
  - \\setmainfont{{FreeSerif}}
  - \\newfontfamily\\arabicfont{{FreeSerif}}
  - \\newfontfamily\\cyrillicfont{{FreeSerif}}
  - \\newfontfamily\\hebrewfont{{FreeSerif}}
  - \\newfontfamily\\greekfont{{FreeSerif}}
  - \\newfontfamily\\hangulfont{{Noto Serif CJK KR}}
lang: {language_code}
output: 
  {paste0(save_as, '_document')}:
    {ifelse(save_as == 'pdf', 'latex_engine: xelatex', 'default')}
babel-lang: chinese-simplified
---

{corr_author_label}: [{corresponding_email}]({corresponding_email})
  
{link_label}: [{link_to_rep}]({link_to_rep})
",
save_as = save_as,
study_title = ifelse(is.null(answers$studyTitle) || answers$studyTitle == "", 
                     server_translate("Untitled", language_code), answers$studyTitle),
sub_title = server_translate(subtitle, language_code),
author_names =  ifelse(is.null(answers$authorNames) || answers$authorNames == "", 
                       server_translate("Anonymous", language_code), answers$authorNames),
corresponding_email =  ifelse(is.null(answers$correspondingEmail) || answers$correspondingEmail == "", 
                              "noemail@example.com", answers$correspondingEmail),
link_to_rep = ifelse(is.null(answers$linkToRepository) || answers$linkToRepository == "", 
                    "#", answers$linkToRepository),
language_code = ifelse(is.null(language_code), "en", language_code),
corr_author_label = server_translate("Corresponding author's email address", language_code),
link_label = server_translate("Link to Project Repository", language_code)
)
  
  # fill in answers with "not answered" - important for generating the files
  bundleQuestions <- getItemList(sectionsList)
  not.answered <- !bundleQuestions %in% names(answers)
  notAnsweredLabel <- server_translate("Not answered", language_code)
  answers[bundleQuestions[not.answered]] <- notAnsweredLabel
  
  # We create sections of the rmd file
  sections <- sapply(sectionsList, composeSections, answers = answers, language_code = language_code, save_as = save_as)
  
  references <- renderReferences(language_code = language_code)
  
  # combine everything together
  rmd <- paste(c(headYaml, "\n", description, "\n---\n", sections, references), collapse = "\n")
  
  # print created document for testing purposes
  print(rmd)
  
  rmd
}

#' @rdname render_document
composeSections <- function(section, answers = NULL, language_code = NULL, save_as){
  # Creating a section
  # First, we sketch the outline of the section
  # TODO: changed \\newpage to \\n check if it working and check why I had to modify it
  body <- stringr::str_glue(
"

**&SectionLabel**


&Questions

{ifelse(save_as == 'pdf', '\\n', '***')}
",
save_as = save_as
)
  # Generate the individual questions and their answers
  questions <- sapply(section$Questions, composeQuestions, answers = answers, language_code = language_code, save_as)
  
  # Fill in the section Name, the text, and the generated questions
  # body <- gsub("&SectionName", server_translate(section$Name, language_code), body)
  if(is.null(section$Label) || section$Label == ""){
    body <- gsub("\\*\\*&SectionLabel\\*\\*", "", body)
  } else{
    body <- gsub("&SectionLabel", server_translate(section$Label, language_code), body)
  }
  body <- gsub("&Questions", paste(questions, collapse = " \n"), body)
  
  # Escape latex backslashes from the question generation
  body <- gsub("&escape&", "\\", body, fixed = TRUE) # double escaping screws latex code

  body
}

#' @rdname render_document
composeQuestions <- function(question, answers = answers, language_code = NULL, save_as){
  # This function takes a question (from the .json file), checks whether it is supposed to be shown
  # (based on the answers and the conditional statements from .json)
  # If it is supposed to be shown, the question and its answer is printed


  show <- TRUE
  
  # check whether the section is supposed to be shown
  # Current dependency arsing does not work come up with a new method if gets picked up
  if(!is.null(question$Depends)){
    show <- gsub(".ind_", "answers$ind_", question$Depends)
    show <- eval(parse(text = show))
  }
  
  # if the question is not shown, return empty space (will screw up the appearance of the rmd file, but not the pdf)
  if(!show){
    return("")
  }
  
  body <- 
"
&Label &Answer
"
  
  # if the AnswerType is "Explain" -- additional comment following some question, render it as a comment
  # make answers bold, but if it is a comment, show it as a quote
  if(!is.null(question$AnswerType) && !(question$AnswerType %in% c("Explain", "OptionalComments")) ){
    # If the response is NA we do not translate it
    resp <- ifelse(
      answers[[question$Name]] == "NA",
      answers[[question$Name]],
      server_translate(answers[[question$Name]], language_code)
    )
    
    # Change syntax based on output format
    answer <- stringr::str_glue(" {ifelse(save_as == 'pdf', '&escape&textbf{', '**')}{resp}{ifelse(save_as == 'pdf', '}', '**')} ")
  } else if(!is.null(question$AnswerType) && question$AnswerType %in% c("Explain", "OptionalComments") ){
    answer <- ifelse(answers[[question$Name]] == "", server_translate("No comments.", language_code), answers[[question$Name]]) # If the comment box is empty
    answer <- paste0("\n\n> ", answer)
  } else{
    answer <- ""
  }
  

  # layout Labels
  if( !is.null(question$href) ){
    question$Label <- paste0(question$Label, "[", question$href, "](", question$href, ")")
  }
  if( !is.null(question$LabelEnd) ){
    question$Label <- paste0(question$Label, question$LabelEnd)
  }
  
  if( !is.null(question$AnswerType) && !(question$AnswerType %in% c("Explain", "OptionalComments")) ){
    label <- stringr::str_glue(" {server_translate(question$Label, language_code)} {ifelse(save_as == 'pdf', '&escape&hfill', '')}")
  } else if(!is.null(question$AnswerType) &&  question$AnswerType %in% c("Explain", "OptionalComments") ){
    if(question$Label == ""){
      label <- paste0("\n")
    } else{
      label <- paste0("**", server_translate(question$Label, language_code), "**")
    }
  } else{
    label <- ""
  }
  
  body <- gsub("&Label", label, body)
  body <- gsub("&Answer", answer, body)

  return(body)
}

#' @rdname render_document
renderReferences <- function(language_code = NULL){
out <- "
## &Refs
 
REFERENCE GOES HERE
"

  gsub("&Refs", server_translate("Source", language_code), out)
}