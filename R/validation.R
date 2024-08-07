#' Validate email input
isValidEmail <- function(x, empty.valid) {
  # code from Felix Schönbrodt
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case = TRUE)
}

#' Validate all responses
isComplete <- function(answers = NULL, sectionsList = NULL, headList = NULL){
  # First, check whether the answers to the header questions are:
  # complete and valid
  
  # If yes, then check all sections
  # This function escapes early, so that whenever even one question is not filled in, it returns FALSE
  # (does not loop over everything, unless everything is valid)
  
  # When the app is being initialized, do not test anything
  # if(length(answers) == 8){
  #   return(FALSE)
  # }
  
  # Check the head and return FALSE if not filled in correctly (check only the name project name and authors)
  # completeHead <- sapply(headList[1:2], function(question){
  #   gsub(" ", "", answers[[question$Name]]) != ""
  # })
  # 
  # if(!all(completeHead)){
  #   return(FALSE)
  # }
  
  # do not require e-mail anymore
  #validEmail <- isValidEmail(answers$correspondingEmail)
  
  #if(!validEmail){
  #  return(FALSE)
  #}
  
  # Check questions and return TRUE if filled in sufficiently
  completeSection <- sapply(sectionsList, function(section){
    # we need to for loop (not lapply) across the questions so that we are able to break early
    # if we encounter a single question that has not been answered
    
    complete <- TRUE
    for(i in seq_along(section$Questions)){
      
      complete <- isCompleteQuestion(section$Questions[[i]], answers)
      
      # if a question is not complete, escape with stored FALSE
      if(!complete){
        break
      }
    }
    
    complete
  })
  
  # Check whether all sections are complete
  #if(!all(completeSection)){
  return(completeSection)
  #}
  
  
  # the report is complete if and only if all shown questions are filled in appropriately
  #return(TRUE)
}

#' Validate responses to questions
isCompleteQuestion <- function(question, answers){
  # if it's not mandatory to respond, skip to another question
  if(!is.null(question$Mandatory) && !question$Mandatory){
    return(TRUE)
  }
  
  # if the question is a comment or some guidance text skip
  if (question$Type == "text") {
    return(TRUE)
  }
  
  # Check whether the question is supposed to be even shown;
  # If not, skip to another question
  if(!is.null(question$Depends)){
    shown <- gsub(".ind_", "answers$ind_", question$Depends)
    shown <- eval(parse(text = shown))
    
    # Depending on the status of the predicate questions, the above logical statement can result in logical(0) or NA,
    # which is caused by predicate questions not being answered yet
    # In that case, the question is not to be shown
    shown <- ifelse(length(shown) == 0 || is.na(shown), FALSE, shown)
    
    # if the question is not shown, we do not require any answers, and thus the question is complete regardless of the answer
    if(!shown){
      return(TRUE)
    }
  }
  
  # the current question is supposed to be shown, and so it needs to be in answers; otherwise, the question is not completed
  if(is.null(answers[[question$Name]])){
    return(FALSE)
  } 
  
  # and the answer should not be an empty string
  if(gsub(" ", "", answers[[question$Name]]) == ""){
    return(FALSE)
  }
  
  # if all checks out (question is shown and answered), then it is complete
  return(TRUE)
}