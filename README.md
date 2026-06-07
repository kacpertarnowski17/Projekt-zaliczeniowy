# Newsy finansowe a indeks Dow Jones — analiza sentymentu w R

Projekt zaliczeniowy z eksploracji danych tekstowych (Reproducible Research).
System bada, czy **wydźwięk codziennych nagłówków informacyjnych** wiąże się z
**kierunkiem amerykańskiego indeksu Dow Jones (DJIA)**, przy użyciu trzech technik
text miningu: **częstości słów**, **TF-IDF** oraz **analizy sentymentu**
(leksykon Bing + finansowy słownik Loughran-McDonald), wraz z badaniem trendu
sentymentu w czasie i jego związku z rynkiem.

Dane: publiczny zbiór „Daily News for Stock Market Prediction" — dla każdego dnia
sesyjnego 2000–2016 zebrano 25 najważniejszych nagłówków oraz etykietę
(1 = DJIA wzrósł, 0 = spadł).

## Struktura repozytorium

```
us-stock-news/
├── README.md
├── analysis.Rmd                  # główny skrypt analizy (R Markdown)
├── analysis.html                 # wygenerowany raport HTML (self-contained)
├── data/
│   └── djia_news.csv             # dostarczony zbiór danych (Date, Label, Top1..Top25)
└── docs/
    └── SRS_Documentation.docx    # Dokumentacja Specyfikacji Wymagań (SRS)
```

## Wymagania

- R >= 4.x
- Pakiety: `rmarkdown`, `knitr`, `readr`, `dplyr`, `tidyr`, `stringr`, `ggplot2`,
  `forcats`, `scales`, `lubridate`, `tidytext`, `wordcloud`, `reshape2`,
  `RColorBrewer`, `SentimentAnalysis`, `ggthemes`

```r
install.packages(c("rmarkdown","knitr","readr","dplyr","tidyr","stringr","ggplot2",
                   "forcats","scales","lubridate","tidytext","wordcloud","reshape2",
                   "RColorBrewer","SentimentAnalysis","ggthemes"))
```

> Sentyment liczony jest leksykonem **Bing** (wbudowany w `tidytext`) oraz
> finansowym słownikiem **Loughran-McDonald** z pakietu `SentimentAnalysis`
> — bez dostępu do internetu.

## Uruchomienie

```r
# w katalogu projektu
rmarkdown::render("analysis.Rmd")
```

Wynik: `analysis.html` z pełnym kodem, tabelami i wykresami.

## Odtwarzalność (Reproducible Research)

- dane wejściowe zapisane jako plik CSV w repozytorium,
- ustalone ziarno losowości (`set.seed(2026)`),
- raport HTML generowany w całości ze skryptu,
- sekcja `sessionInfo()` dokumentuje wersje R i pakietów.

## Dokumentacja

Pełna Specyfikacja Wymagań (SRS) znajduje się w `docs/SRS_Documentation.docx`.

## Autorzy i podział pracy

Projekt zespołowy:

- **Kacper Tarnowski** — implementacja skryptu R, analizy (częstość słów, TF-IDF,
  sentyment), wizualizacje, raport HTML.
- **Aleksander Mistur** — przygotowanie i opis danych, dokumentacja SRS,
  interpretacja wyników i wnioski.

> Podział roboczy — do dostosowania zgodnie z faktycznym wkładem.

