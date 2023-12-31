# TODO: "All Authors [Given name(s) Surname;]" not translated if used as a key I guess it is because special characters are used
# have to find a robust way for taking out special characters from keys  and referencing them in the app.

# Load packages
library(rjson)
library(purrr)
library(stringr)
library(tibble)
library(rlang)

# Load translations and language ISO codes
translations <- rjson::fromJSON(file = "./inst/app/www/translations.json")
language_codes <- rjson::fromJSON(file = "./inst/app/www/language_codes.json")

# Show the names of the lists
names(language_codes)
names(translations)

# Assign ISO codes to translated lanugage names
# TODO: Right now they are connected by order but it would be safer to connect through lookup
# English should be the first language then the rest
english_index <- which(translations[["languages"]] == "English")
language_order_by <- c("English", sort(translations[["languages"]][-english_index]))

# Drop languages list from translations
translations[["languages"]] <- NULL

language_translation <- purrr::pluck(translations, 1, 1) %>% .[language_order_by]
  
language_list <- language_codes %>%
  .[language_order_by] %>% 
  rlang::set_names(language_translation)

language_list_json <- jsonlite::toJSON(language_list, pretty = TRUE, auto_unbox = TRUE)

write(language_list_json, "inst/app/www/language_list.json")

# Process translations to be formatted as gemstones wants it

translations <- purrr::flatten(translations)

i18n_codes <- purrr::map(translations, "English")
i18n_codes

# semi-colon in the key breaks i18n, we should replace those keys with a version without the semi-colon
# it is important to remember to replace these keys in the app UI as well
# since the keys are automatically generated I will take them out in the with_i18n function
special_keys <- i18n_codes %>% 
  keep(., .p = stringr::str_detect(., ";"))
special_keys

i18n_codes <-
  i18n_codes %>% 
  map_if(
    .p = stringr::str_detect(., ";"),
     ~ stringr::str_remove_all(., ";")
  )

transpose_translations <- 
  purrr::transpose(translations) %>% 
  purrr::map(set_names, nm = i18n_codes) %>%
  # This should be done by match
  rlang::set_names(language_codes) %>% 
  map(
    ~ list(.) %>% 
      set_names("translation")
    )

# i18n_translations <- rjson::toJSON(transpose_translations, indent = 1)
i18n_translations <- jsonlite::toJSON(transpose_translations, pretty = TRUE, auto_unbox = TRUE)

write(i18n_translations, "inst/app/www/i18n_locales.json")

# usethis::use_data(transform_json, overwrite = TRUE)

