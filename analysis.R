# =============================================================
# Pelna analiza Text Mining: newsy finansowe a indeks Dow Jones
# Wersja .R do uruchamiania w R/RStudio (zaznacz wszystko -> Run / Source)
# Autorzy: Kacper Tarnowski, Aleksander Mistur
# UWAGA: plik data/djia_news.csv musi byc w podfolderze 'data' obok tego skryptu
# =============================================================

# Wymuszenie locale UTF-8 - bez tego polskie znaki na wykresach renderuja sie
# jako kody <U+0119> itp. (problem wystepuje w locale "C").
if (!isTRUE(l10n_info()[["UTF-8"]])) {
  for (loc in c("C.UTF-8", "en_US.UTF-8", "pl_PL.UTF-8", "C.utf8")) {
    ok <- tryCatch({ Sys.setlocale("LC_CTYPE", loc); TRUE },
                   warning = function(w) FALSE, error = function(e) FALSE)
    if (ok) break
  }
}

set.seed(2026)  # dla powtarzalnosci wynikow

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(stringr)
  library(ggplot2); library(forcats); library(scales); library(lubridate)
  library(tidytext)          # tokenizacja, TF-IDF, leksykon Bing
  library(SnowballC)         # stemming (wordStem)
  library(wordcloud)         # chmury slow
  library(reshape2)          # acast() do chmury porownawczej
  library(RColorBrewer)      # palety kolorow
  library(SentimentAnalysis) # slowniki GI, HE, LM, QDAP
  library(ggthemes)          # theme_gdocs
})
theme_set(theme_minimal(base_size = 12))

# Wczytanie dostarczonego pliku. Format szeroki: Date, Label, Top1..Top25.
raw <- read_csv("data/djia_news.csv", show_col_types = FALSE)
cat("Wymiary:", nrow(raw), "dni x", ncol(raw), "kolumn\n")
raw %>% select(Date, Label, Top1, Top2) %>% slice_head(n = 3)

# Format szeroki -> dlugi: 1 naglowek = 1 wiersz. Czyszczenie tekstu:
# normalizacja apostrofow, usuniecie prefiksu b"...", zbednych escape'ow.
news <- raw %>%
  mutate(Date = as.Date(Date), market = if_else(Label == 1, "wzrost", "spadek")) %>%
  pivot_longer(starts_with("Top"), names_to = "rank", values_to = "headline") %>%
  filter(!is.na(headline), headline != "") %>%
  mutate(
    headline = str_replace_all(headline, "[\u2018\u2019]", "'"),   # normalizacja apostrofow
    headline = str_remove(headline, '^b["\']'),                     # prefiks bytestring
    headline = str_replace_all(headline, '\\\\["\']', "")           # zbedne escapy
  )
cat("Liczba naglowkow po przeksztalceniu:", nrow(news), "\n")
raw %>% count(market = if_else(Label == 1, "wzrost", "spadek"), name = "liczba_dni")

# Tokenizacja + usuniecie stopwords i liczb. Krotkie tokeny (<=2 znaki) odrzucamy.
data("stop_words")
tidy_news <- news %>%
  unnest_tokens(word, headline) %>%
  anti_join(stop_words, by = "word") %>%
  filter(!str_detect(word, "^[0-9]+$"), str_length(word) > 2)
cat("Tokeny:", nrow(tidy_news), "| unikalne slowa:", n_distinct(tidy_news$word), "\n")

# Stemming: sprowadzenie slow do rdzenia (np. "markets","market" -> "market").
tidy_news <- tidy_news %>% mutate(stem = wordStem(word))

# Stem completion (typ "prevalent"): kazdemu rdzeniowi przypisujemy jego
# najczestsza forme pierwotna - zeby wyniki byly czytelne mimo stemmingu.
stem_completion <- tidy_news %>%
  count(stem, word, sort = TRUE) %>%
  group_by(stem) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(stem, term = word)

tidy_news <- tidy_news %>% left_join(stem_completion, by = "stem")
tidy_news %>% select(word, stem, term) %>% slice_head(n = 6)

# Czestosc liczymy na uzupelnionych rdzeniach (term) - czytelnie i po stemmingu.
top_words <- tidy_news %>% count(term, sort = TRUE)
top_words %>% slice_head(n = 15)

top_words %>%
  slice_head(n = 20) %>%
  mutate(term = fct_reorder(term, n)) %>%
  ggplot(aes(n, term)) +
  geom_col(fill = "#2c7fb8") +
  scale_x_continuous(labels = label_comma()) +
  labs(title = "20 najczęstszych słów w nagłówkach (po stemmingu, 2000–2016)",
       x = "Liczba wystąpień", y = NULL)

with(top_words %>% slice_head(n = 120),
     wordcloud(words = term, freq = n, max.words = 120, random.order = FALSE,
               rot.per = 0.25, scale = c(4.2, 0.6), colors = brewer.pal(8, "Dark2")))

market_tf_idf <- tidy_news %>%
  count(market, term, sort = TRUE) %>%
  bind_tf_idf(term, market, n) %>%
  arrange(desc(tf_idf))
market_tf_idf %>% select(market, term, n, tf_idf) %>% slice_head(n = 12)

market_tf_idf %>%
  group_by(market) %>%
  slice_max(tf_idf, n = 12, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(term = reorder_within(term, tf_idf, market)) %>%
  ggplot(aes(tf_idf, term, fill = market)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~market, scales = "free") +
  scale_y_reordered() +
  scale_fill_manual(values = c(spadek = "#d7191c", wzrost = "#1a9641")) +
  labs(title = "Słowa charakterystyczne dla dni wzrostowych i spadkowych (TF-IDF)",
       x = "TF-IDF", y = NULL)

bing <- get_sentiments("bing")
tidy_news %>%
  inner_join(bing, by = c("term" = "word")) %>%
  count(term, sentiment, sort = TRUE) %>%
  group_by(sentiment) %>%
  slice_max(n, n = 10, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(term = reorder_within(term, n, sentiment)) %>%
  ggplot(aes(n, term, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  scale_y_reordered() + scale_x_continuous(labels = label_comma()) +
  scale_fill_manual(values = c(negative = "#d7191c", positive = "#1a9641")) +
  labs(title = "Słowa najczęściej wnoszące sentyment (Bing)", x = "Liczba wystąpień", y = NULL)

tidy_news %>%
  inner_join(bing, by = c("term" = "word")) %>%
  count(term, sentiment, sort = TRUE) %>%
  acast(term ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("#d7191c", "#1a9641"),
                   max.words = 120, scale = c(4, 0.6), title.size = 1.4)

daily_text <- news %>%
  group_by(Date, market) %>%
  summarise(text = str_c(headline, collapse = ". "), .groups = "drop")

# Jedno wywolanie liczy wszystkie 4 slowniki naraz.
sent <- analyzeSentiment(daily_text$text)
scores <- daily_text %>%
  mutate(GI = sent$SentimentGI, HE = sent$SentimentHE,
         LM = sent$SentimentLM, QDAP = sent$SentimentQDAP)
head(scores %>% select(Date, GI, HE, LM, QDAP))

# convertToDirection: wartosc ciagla -> kierunek (pozytywny/neutralny/negatywny).
direction <- scores %>%
  pivot_longer(c(GI, HE, LM, QDAP), names_to = "Dictionary", values_to = "value") %>%
  mutate(direction = as.character(convertToDirection(value))) %>%
  filter(!is.na(direction))

ggplot(direction, aes(direction, fill = Dictionary)) +
  geom_bar(alpha = 0.85, show.legend = FALSE) +
  facet_wrap(~Dictionary) +
  scale_fill_manual(values = c(GI="#1a9641", HE="#2c7fb8", LM="#fdae61", QDAP="#d7191c")) +
  theme_gdocs() +
  labs(title = "Skumulowany sentyment kierunkowy według słowników",
       x = "Sentyment", y = "Liczba dni")

scores %>%
  pivot_longer(c(GI, HE, LM, QDAP), names_to = "Dictionary", values_to = "value") %>%
  ggplot(aes(Date, value, color = Dictionary)) +
  geom_smooth(se = FALSE, linewidth = 0.9, method = "loess", span = 0.2, formula = y ~ x) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  scale_color_manual(values = c(GI="#1a9641", HE="#2c7fb8", LM="#fdae61", QDAP="#d7191c")) +
  theme_gdocs() +
  labs(title = "Zmiana sentymentu nagłówków w czasie (porównanie 4 słowników)",
       x = NULL, y = "Sentyment", color = "Słownik")

ggplot(scores, aes(market, LM, fill = market)) +
  geom_boxplot(alpha = 0.85, outlier.alpha = 0.15, show.legend = FALSE) +
  scale_fill_manual(values = c(spadek = "#d7191c", wzrost = "#1a9641")) +
  theme_gdocs() +
  labs(title = "Dzienny sentyment finansowy (LM) a kierunek DJIA",
       x = "Kierunek rynku tego dnia", y = "Sentyment LM")

t_res <- t.test(LM ~ market, data = scores)
cat(sprintf("Srednia LM (spadek) = %.5f | (wzrost) = %.5f | p-value testu t = %.4f\n",
            t_res$estimate[1], t_res$estimate[2], t_res$p.value))

sessionInfo()
