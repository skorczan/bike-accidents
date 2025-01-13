#!/usr/bin/env Rscript


library("rvest")
library("dplyr")
library("curl")
library("data.table")
library("stringr")


curl_handle = new_handle(verbose = F)
handle_setheaders(curl_handle,
  "User-Agent" = "RScript"
)
handle_setopt(curl_handle, timeout = 3600, low_speed_time = 3600)

# Wypadek

## Światło
light <- c("Światło dzienne", "Zmrok, świt", "Noc - droga oświetlona",
           "Noc - droga niedostatecznie oświetlona", "Noc - droga nieoświetlona")

## Geometria drogi
road_geometry <- c("Odcinek prosty", "Zakręt, łuk", "Spadek",
                  "Wzniesienie", "Wierzchołek wzn.", "Brak")

## Nawierzchnia
pavement <- c("Twarda", "Gruntowa")

## Oznakowanie nawierzchni
surface_marking <- c("Jest", "Nie ma")

## Typ drogi
road_type <- c("Autostrada", "Ekspresowa", "Dwie jezdnie jednokierunkowe",
              "Jednokierunkowa", "Jednojezdniowa dwukierunkowa")

## Obszar zabudowany
built_up_area <- c("Obszar zabudowany", "Obszar niezabudowany")

## Rodzaj wypadku
accident_type <- c("Zderzenie pojazdów czołowe", "Zderzenie pojazdów boczne",
                  "Zderzenie pojazdów tylne", "Najechanie na pieszego",
                  "Najechanie na pojazd unieruchomiony",
                  "Najechanie na drzewo, słup, inny obiekt drogowy",
                  "Najechanie na drzewo", "Najechanie na słup, znak",
                  "Najechanie na zapore kolejową", "Najechanie na dziurę, wybój, garb",
                  "Najechanie na zwierzę", "Najechanie na barierę ochronną",
                  "Wywrócenie się pojazdu", "Wypadek z pasażerem", "Inne",
                  "Zdarzenie z osobą UWR")

## Światła drogowe
traffic_lights <- c("Jest, działa", "Jest, nie działa", "Brak")

## Stan nawierzchni
surface_condition <- c("Sucha", "Mokra", "Kałuże, rozlewiska",
                      "Oblodzona, zaśnieżona", "Zanieczyszczona", "Inny",
                      "Koleiny, garby", "Dziury, wyboje")

## Charakterystyka miejsca
site_characteristic <- c("Jezdnia", "Pas dzielący jezdnie", "Pobocze",
                        "Skarpa, rów", "Chodnik, droga dla pieszych", "Droga dla rowerzystów",
                        "Przejście dla pieszych", "Przystanek komunikacji publicznej",
                        "Przystanek tramwajowy", "Torowisko tramwajowe wydzielone",
                        "Torowisko tramwajowe w jezdni", "Przejazd tramwajowy, torowisko",
                        "Przejazd kolejowy strzeżony", "Przejazd kolejowy niestrzeżony",
                        "Most, wiadukt, estakada", "Tunel", "Most, wiadukt, łącznica, tunel",
                        "Przewiązka na drodze dwujezdniowej", "Parking, plac",
                        "Wjazd, wyjazd z posesji, pola", "Inne", "Roboty drogowe, oznakowanie tymczasowe",
                        "Droga, pas ruchu, śluza dla rowerów", "Przejazd dla rowerzystów",
                        "Parking, plac, MOP", "Brak opisu miejsca zdarzenia")

## Przyczyny inne
other_cause <- c("Pożar pojazdu", "Niezawiniona niesprawność techniczna pojazdu",
                "Niewłaściwy stan jezdni", "Nieprawidłowa organizacja ruchu",
                "Nieprawidłowo zabezp. roboty drogowe", "Nieprawidłowo działająca sygn. świetlna",
                "Nieprawidłowo działająca zapora, rogatka", "Obiekty, zwierzęta na drodze",
                "Nagłe zasłabnięcie kierującego", "Oślepienie przez inny pojazd lub słońce",
                "Z winy pasażera: wyskak. z pojazdu w ruchu", "Z winy pasażera: wypadnięcie",
                "Z winy pasażera", "Nieustalone", "Inne, nieustalone",
                "Inne", "Niesprawność techniczna pojazdu",
                "Utrata przytomności, śmierć kierującego", "Brak")

## Pogoda
weather <- c("Dobre warunki atmosferyczne", "Pochmurno", "Oślepiające słońce",
             "Silny wiatr", "Opady deszczu", "Opady śniegu, gradu", "Mgła, dym")

## Typ skrzyżowania
intersection_type <- c("Rejon skrzyżowania", "Równorzędne",
                      "Z drogą z pierwsz.", "O ruchu okrężnym", "Brak")


# Uczestnicy wypadku

participant_fault <- c(
  'Niedostosowanie prędkości do warunków ruchu',
  'Nieudzielenie pierwszeństwa przejazdu',
  'Nieudzielenie pierwszeństwa pieszemu',
  'Nieprawidłowe: wyprzedzanie',
  'Nieprawidłowe: omijanie',
  'Nieprawidłowe: wymijanie',
  'Nieprawidłowe: przejeżdżanie przejścia dla pieszych',
  'Nieprawidłowe: przejeżdżanie przejścia dla rowerów',
  'Nieprawidłowe: skręcanie',
  'Nieprawidłowe: zmienianie pasa ruchu',
  'Nieprawidłowe: Zawracanie',
  'Nieprawidłowe: zatrzymywanie, postój',
  'Nieprawidłowe: cofanie',
  'Jazda po niewłaściwej stronie drogi',
  'Wjazd przy czerwonym świetle',
  'Nieprzestrzeganie innych sygnałów',
  'Niezachowanie bezp. odl. między pojazdami',
  'Gwałtowne hamowanie',
  'Jazda bez wymaganego oświetlenia',
  'Zmęczenie, zaśnięcie',
  'Ograniczenie sprawności psychomotorycznej',
  'Inne'
)

participant_role <- c('Pieszy', 'Kierujący', 'Pasażer', 'Osoba UWR')

participant_driving_licence <- c('Posiada', 'Nie posiada', 'Nie wymagane')

gender <- c('Mężczyzna', 'Kobieta', 'Nie ustalono')

participant_fault <- c(
  'Niedostosowanie prędkości do warunków ruchu',
  'Nieudzielenie pierwszeństwa przejazdu',
  'Nieudzielenie pierwszeństwa pieszemu',
  'Nieprawidłowe: wyprzedzanie',
  'Nieprawidłowe: omijanie',
  'Nieprawidłowe: wymijanie',
  'Nieprawidłowe: przejeżdżanie przejścia dla pieszych',
  'Nieprawidłowe: przejeżdżanie przejścia dla rowerów',
  'Nieprawidłowe: skręcanie',
  'Nieprawidłowe: zmienianie pasa ruchu',
  'Nieprawidłowe: Zawracanie',
  'Nieprawidłowe: zatrzymywanie, postój',
  'Nieprawidłowe: cofanie',
  'Jazda po niewłaściwej stronie drogi',
  'Wjazd przy czerwonym świetle',
  'Nieprzestrzeganie innych sygnałów',
  'Niezachowanie bezp. odl. między pojazdami',
  'Gwałtowne hamowanie',
  'Jazda bez wymaganego oświetlenia',
  'Zmęczenie, zaśnięcie',
  'Ograniczenie sprawności psychomotorycznej',
  'Inne',
  'Nieustąpienie pierwszeństwa pieszemu w innych okolicznościach',
  'Nieprawidłowe przejeżdżanie przejazdu dla rowerzystów',
  'Inne przyczyny',
  'Nieustąpienie pierwszeństwa pieszemu na przejściu dla pieszych',
  'Omijanie pojazdu przed przejściem dla pieszych'
)

participant_pedestrian_fault <- c(
  'Stanie na jezdni, leżenie',
  'Chodzenie nieprawidłową stroną drogi',
  'Wejście na jezdnię przy czerwonym świetle',
  'Nieostrożne wejście na jezdnię: przed jadącym pojazdem',
  'Nieostrożne wejście na jezdnię: zza pojazdu, przeszkody',
  'Zatrzymanie, cofnięcie się',
  'Przebieganie przez jezdnię',
  'Przekraczanie jezdni w miejscu niedozwolonym',
  'Chodzenie po torowisku',
  'Wskakiwanie do pojazdu w ruchu',
  'Dzieci do lat 7: zabawa na jezdni',
  'Dzieci do lat 7: wtargnięcie na jezdnię',
  'Inne'
)

participant_penalty <- c(
  'Dochodzenie', 
  'Wniosek o ukaranie', 
  'Mandat karny', 
  'Pouczenie', 
  'Inny organ', 
  'Inny sposób zakończenia'
)

participant_influence <- c('Alkoholu', 'Innego środka', 'Nie badano', 'Trzeźwy')

participant_injury <- c(
  'Śmierć w ciągu 30 dni', 
  'Smierć na miejscu', 
  'Ranny lekko', 
  'Ranny ciężko', 
  'Brak obrażeń'
)

participant_missing_use <- c('Fotelika', 'Hełmu', 'Pasów', 'Pasów, hełmu')

vehicle_type <- c(
  'Rower',
  'Motorower',
  'Motocykl',
  'Samochód osobowy z przyczepą',
  'Samochód osobowy bez przyczepy',
  'Samochód osobowy TAXI',
  'Autobus komunikacji publicznej',
  'Autobus inny',
  'Samochód ciężarowy do przewozu ładunków z przyczepą',
  'Samochód ciężarowy do przewozu ładunków bez przyczepy',
  'Samochód ciężarowy do przewozu osób',
  'Ciągnik rolniczy z przyczepą',
  'Ciągnik rolniczy bez przyczepy',
  'Pojazd wolnobieżny',
  'Tramwaj',
  'Trolejbus',
  'Pojazd zaprzęgowy',
  'Pociąg',
  'Pojazd uprzywilejowany',
  'Inny pojazd',
  'Samochód osobowy',
  'Ciągnik rolniczy',
  'Tramwaj, trolejbus',
  'Nieustalony',
  'Pojazd przewożący materiały niebezpieczne',
  'Motocykl o poj. do 125 cm3 (do 11 kw/0,1 KW/kg) (od 11.2015)',
  'Motocykl inny (od 11.2015)',
  'Czterokołowiec lekki (od 11.2015)',
  'Czterokołowiec (od 11.2015)',
  'Samochód ciężarowy do 3,5 T (od 11.2015)',
  'Samochód ciężarowy Powyżej 3,5 T (od 11.2015)',
  'Rower',
  'Motorower',
  'Autobus komunikacji publicznej',
  'Autobus inny',
  'Pociąg',
  'Inny',
  'Samochód osobowy',
  'Ciągnik rolniczy',
  'Tramwaj, trolejbus',
  'Pojazd nieustalony',
  'Motocykl o poj. do 125 cm3 (do 11 kw/0,1 KW/kg)',
  'Motocykl inny',
  'Czterokołowiec lekki',
  'Czterokołowiec',
  'Samochód ciężarowy DMC do 3,5 T',
  'Samochód ciężarowy DMC powyżej 3,5 T',
  'Rower',
  'Motorower',
  'Autobus komunikacji publicznej',
  'Autobus inny',
  'Pociąg',
  'Inny',
  'Samochód osobowy',
  'Ciągnik rolniczy',
  'Tramwaj, trolejbus',
  'Pojazd nieustalony',
  'Motocykl o poj. do 125 cm3 (do 11 kw/0,1 KW/kg)',
  'Motocykl inny',
  'Czterokołowiec lekki',
  'Czterokołowiec',
  'Samochód ciężarowy DMC do 3,5 T',
  'Samochód ciężarowy DMC powyżej 3,5 T',
  'Hulajnoga elektryczna (od 2022)',
  'Urządzenie transportu osobistego (od 2022)'
)

vehicle_special_type <- c(
  'Pojazd przewożący towar niebezpieczny',
  'Pojazd uprzywilejowany',
  'Pojazd z kierownicą po prawej stronie',
  'Pojazd uprzywilejowany Policja',
  'Pojazd uprzywilejowany inny',
  'Pojazd bez cech szczególnych'
)

get_accident_ids_by_date_range <- function(city, since, until) {
  data_url <- paste(
    "filter_form[voivodeship]=",
    "filter_form[county]=",
    paste("filter_form[locality]=", city, sep=""),
    "filter_form[streets][0]=",
    "filter_form[streets][1]=",
    "filter_form[streets][2]=",
    "filter_form[streets][3]=",
    paste("filter_form[fromDate]=", since, sep=""),
    paste("filter_form[toDate]=", until, sep=""),
    "filter_form[accidentSite]=",
    "filter_form[roadType]=",
    "filter_form[light]=",
    "filter_form[trafficLights]=",
    "filter_form[intersectionType]=",
    "filter_form[accidentType]=",
    "filter_form[driversCause]=",
    "filter_form[pedestriansCause]=",
    "filter_form[otherCause]=",
    "filter_form[injury]=",
    "filter_form[pedestriansPresence]=",
    "filter_form[accidents]=",
    "filter_form[vehicleType][]=IS201",
    "filter_form[categories]=Czas zdarzeń", sep="&") %>%
    URLencode(., reserved = T) %>%
    gsub("%20", "+", . ) %>%
    gsub("%26", "&", . ) %>%
    gsub("%3D", "=", . ) %>%
    paste("https://sewik.pl/search?", ., sep="")
  
  response <- curl_fetch_memory(data_url, handle = curl_handle)
  
  if (response$status_code != 200) {
    stop("HTTP request failed: ", response$status_code)
  }
  
  html_data <- rawToChar(response$content)
  html_data <- read_html(html_data)
  
  html_data %>%
    html_element("#content > table") %>%
    html_table() %>%
    filter(Id != "Empty table.")
}

get_accident_data <- function(accident_id) {
  id <- data.frame("Id wypadku" = accident_id)
  
  data_url <- paste("https://sewik.pl/accident/", accident_id, sep="")
  response <- curl_fetch_memory(data_url, handle = curl_handle)
  
  if (response$status_code != 200) {
    stop("HTTP request failed: ", response$status_code)
  }
  
  html_data <- rawToChar(response$content)
  html_data <- read_html(html_data)
  
  id <- data.frame(Id = accident_id)
  basic_data <- extract_basic_data(html_data)
  vehicle_data <- extract_vehicles_data(html_data)
  passengers_data <- extract_passengers_data(html_data)
  
  list(id, basic_data, vehicle_data, passengers_data)
}

extract_basic_data <- function(html_tags) {
  basic_data <- html_tags %>% html_elements("#accident-page > ul") %>% html_children() %>% html_text2()
  basic_data_splitted <- strsplit(basic_data, ":")
  basic_data_labels <- sapply(basic_data_splitted, function (row) { trimws(row[1]) })
  basic_data_data <- sapply(basic_data_splitted, function (row) { trimws(row[2]) })
  
  voivodeship_index <- grep("^WOJ\\. ", basic_data_labels)
  basic_data_data[voivodeship_index] <- sub("^WOJ\\. ", "", basic_data_labels[voivodeship_index])
  basic_data_labels[voivodeship_index] <- "Województwo"
  
  all_noname_indices <- which(is.na(basic_data_data))
  noname_indices = all_noname_indices[c(1, length(all_noname_indices))]
  
  basic_data_data <- replace(basic_data_data, noname_indices, basic_data_labels[noname_indices])
  if (is.na(basic_data_data[noname_indices[-1]])) {
    basic_data_data <- replace(basic_data_data, c(noname_indices[-1]), c("Brak"))
  }
  basic_data_labels <- replace(basic_data_labels, noname_indices, c("Rodzaj zdarzenia", "Inne przyczyny zdarzenia"))
  
  basic_data <- as.data.frame(t(basic_data_data), stringsAsFactors = FALSE)
  colnames(basic_data) <- basic_data_labels
  
  basic_data
}

extract_vehicles_data <- function(html_tags) {
  root_tag <- html_tags %>% html_node("#accident-page > ol") 
  vehicle_id <- 0
  
  rbindlist(lapply(html_children(root_tag), function (vehicle_tag) {
    vehicle_id <<- vehicle_id + 1
    type <- vehicle_tag %>% html_node("strong") %>% html_text2()
    details <- vehicle_tag %>% html_nodes("ul:nth-child(1) > li") %>% html_text2() %>% nafill(., "const", NA)
    brand = details[1]
    
    if (length(details) > 2) {
      issues = details[2]
      special_types = details[3]
    } else {
      issues = NA
      special_types = details[2]
    }
    
    data.frame(
      "ID pojazdu" = vehicle_id,
      "Typ" = type,
      "Marka" = brand,
      "Usterki" = issues,
      "Cechy szczególne" = special_types
    )
  }), fill = T) %>% as.data.frame()
}

extract_passengers_data <- function(html_tags) {
  root_tag <- html_tags %>% html_node("#accident-page > ol") 
  vehicle_id <- 0
  
  root_tag %>% html_children() %>% lapply(., function (vehicle_tag) {
    vehicle_id <<- vehicle_id + 1
    passenger_id <<- 0
    
    vehicle_tag %>% html_node("ul:nth-child(3)") %>% html_children() %>% lapply(., function(passenger_tag) {
      passenger_id <<- passenger_id + 1
      role <- passenger_tag %>% html_node("strong") %>% html_text2()
      raw_details <- passenger_tag %>% html_nodes("ul > li") %>% html_text2()
      
      not_na_replace <- function (x, substitution) {
        ifelse(!is.na(x), substitution, NA)
      }
      
      sex_indexes <- match(raw_details, gender) %>% not_na_replace("Płeć")
      fault_indexes <- match(raw_details, participant_fault) %>% not_na_replace("Przyczyna wypadku")
      missing_use_indexes <- match(raw_details, participant_missing_use) %>% not_na_replace("Nieprawidłowe użycie")
      
      missing_names <- sex_indexes
      missing_names[!is.na(fault_indexes)] <- fault_indexes[!is.na(fault_indexes)]
      missing_names[!is.na(missing_use_indexes)] <- missing_use_indexes[!is.na(missing_use_indexes)]
      
      named <- which(is.na(missing_names))
      names <- rep(NA, length(raw_details) + 3)
      values <- rep(NA, length(raw_details) + 3)
      
      names <- names %>% replace(1, "ID pojazdu") %>% replace(2, "ID pasażera") %>% replace(3, "Rola")
      values <- values %>% replace(1, vehicle_id) %>% replace(2, passenger_id)  %>% replace(3, role)
      
      for (i in 1:length(raw_details)) {
        if (i %in% named) {
          entry <- split_by_colon(raw_details[i])
          name <- entry[1]
          value <- entry[2]
        } else {
          name <- missing_names[i]
          value <- trimws(raw_details[i])
        }
        
        names <- replace(names, i + 3, name)
        values <- replace(values, i + 3, value)
      }
      
      result <- data.frame(t(values))
      colnames(result) <- names
      result
    })
  }) %>% unlist(recursive = F) %>% rbindlist(., fill = T) %>% as.data.frame()
}

split_by_colon <- function (x) {
  if (grepl(":", x)) {
    parts <- lapply(strsplit(x, ":"), trimws)[[1]]
    
    if (length(parts) < 2) {
      c(parts[1], NA)
    } else {
      parts
    }
  } else {
    c(NA, x)
  }
}

weeks_between <- function (since, until) {
  step = sign(until - since) * 7
  days <- seq(since, until, step)
  
  if (days[length(days)] != until) {
    days <- c(days, until)
  }
  
  since_days <- days[1:length(days)-1]
  until_days <- c(days[2:(length(days)-1)] - 1, until)
  
  data.frame(since = since_days, until = until_days)
}

main <- function() {
  since = as.Date("2017-01-01")
  until = as.Date("2022-12-31")
  weeks <- weeks_between(since, until)
  
  cities <- c("Gdańsk", "Gdynia")
  
  #cities =  c("Warszawa", "Kraków", "Łódź", "Wrocław",
  #            "Poznań", "Szczecin", "Bydgoszcz", "Lublin", "Białystok",
  #            "Katowice", "Częstochowa", "Radom", "Toruń", "Sosnowiec", "Kielce",
  #            "Rzeszów", "Gliwice", "Olsztyn")
  
  for (city in cities) {
    print(city)
    
    data_by_weeks <- apply(weeks, 1, function (week) {
      since = week[1]
      until = week[2]
      
      print(paste(since, "-", until))
      overview <- get_accident_ids_by_date_range(city, since, until)
      
      all_accident_data <- lapply(overview$Id, get_accident_data)
      all_accidents_basic_data <- lapply(all_accident_data, function (adata) { bind_cols(adata[[1]], adata[[2]]) })
      all_accidents_vehicles_data <- lapply(all_accident_data, function (adata) { bind_cols(list(adata[[1]], adata[[3]])) })
      all_accidents_passengers_data <- lapply(all_accident_data, function (adata) { bind_cols(list(adata[[1]], adata[[4]])) })
    
      list(
        basic_data = rbindlist(all_accidents_basic_data, fill = T),
        vehicles_data = rbindlist(all_accidents_vehicles_data, fill = T),
        passengers_data = rbindlist(all_accidents_passengers_data, fill = T)
      )  
    })
    
    basic_data <- rbindlist(lapply(data_by_weeks, function (data_by_year) { data_by_year$basic_data }), fill = T)
    vehicles_data <- rbindlist(lapply(data_by_weeks, function (data_by_year) { data_by_year$vehicles_data }), fill = T)
    passengers_data <- rbindlist(lapply(data_by_weeks, function (data_by_year) { data_by_year$passengers_data }), fill = T)
    
    dir.create(file.path(city), showWarnings = F)
    write.csv(basic_data, file = paste(city, "basic_data.csv", sep ="/"), row.names = F)
    write.csv(vehicles_data, file = paste(city, "vehicles_data.csv", sep ="/"), row.names = F)
    write.csv(passengers_data, file = paste(city, "passengers_data.csv", sep ="/"), row.names = F)
  }
}

main()