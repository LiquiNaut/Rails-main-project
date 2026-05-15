# FinanceGPT — Inteligentný finančný asistent

Webová aplikácia pre správu faktúr s integrovaným konverzačným asistentom, ktorý využíva veľké jazykové modely (LLM) na spracovanie dotazov v prirodzenom jazyku. Používateľ môže klásť otázky o svojich finančných dátach a dostávať odpovede v podobe textu, tabuliek alebo interaktívnych grafov.

Projekt je výstupom diplomovej práce _„Návrh a implementácia inteligentného finančného asistenta FinanceGPT s využitím LLM pre spracovanie dotazov v prirodzenom jazyku"_ na FEI STU v Bratislave. Aplikácia rozširuje fakturačný systém vytvorený v rámci predchádzajúcej bakalárskej práce.

**Autor:** Bc. Boris Gašparovič  
**Vedúci práce:** Ing. Erich Stark, PhD.  
**Akademický rok:** 2025/2026

---

## Hlavné funkcie

- **Správa faktúr** — vytváranie, editácia a prehľad faktúr s automatickým doplňovaním údajov
- **Konverzačný asistent (FinanceGPT)** — chatové rozhranie pre interakciu s finančnými dátami v prirodzenom jazyku
- **Text-to-SQL** — LLM generuje SQL dotazy nad databázou faktúr (`SqlGeneratorTool`)
- **Sémantické vyhľadávanie** — vyhľadávanie faktúr podľa obsahu pomocou vektorových embeddingov a pgvector (`SemanticSearchTool`)
- **Vizualizácie** — cashflow graf (`CashflowChartTool`) a rozdelenie príjmov podľa klienta (`IncomeBreakdownTool`) renderované cez Chart.js
- **Bezpečnosť** — whitelist iba SELECT dotazov, tenant izolácia dát podľa prihláseného používateľa, Devise autentifikácia

---

## Technológie

| Vrstva          | Technológia                                                |
| --------------- | ---------------------------------------------------------- |
| Backend         | Ruby 3.3.6, Ruby on Rails 8.0                              |
| Frontend        | Hotwire (Turbo + Stimulus), Bootstrap, Chart.js, marked.js |
| Databáza        | PostgreSQL s rozšírením pgvector                           |
| LLM integrácia  | ruby_llm gem v1.13, OpenRouter proxy brána                 |
| Embedding model | OpenAI text-embedding-3-small                              |
| Autentifikácia  | Devise                                                     |
| Asset pipeline  | Sprockets + Importmap                                      |

---

## Predpoklady

Pred spustením projektu je potrebné mať nainštalované:

- **Ruby** verzia `3.3.6` (odporúčame inštaláciu cez [rbenv](https://github.com/rbenv/rbenv) alebo [rvm](https://rvm.io/))
- **PostgreSQL** 14+ s bežiacou lokálnou službou
- **Bundler** (`gem install bundler`)
- API kľúč pre LLM poskytovateľa (OpenRouter alebo OpenAI)

---

## Inštalácia a spustenie

### 1. Klonovanie repozitára

```bash
git clone https://github.com/LiquiNaut/Rails-main-project.git
cd Rails-main-project
```

### 2. Inštalácia závislostí

```bash
bundle install
```

### 3. Konfigurácia premenných prostredia

Vytvorte súbor `.env` v koreňovom adresári projektu:

```bash
touch .env
```

Pridajte do neho nasledujúce premenné:

```
OPENROUTER_API_KEY=váš_openrouter_kľúč
OPENAI_API_KEY=váš_openai_kľúč
```

`OPENROUTER_API_KEY` sa používa na komunikáciu s LLM modelom (chat). `OPENAI_API_KEY` sa používa na generovanie vektorových embeddingov (model `text-embedding-3-small`).

Ak vaša PostgreSQL inštalácia vyžaduje iné prístupové údaje, upravte súbor `config/database.yml` (predvolené: username `postgres`, heslo `admin`, port `5432`).

### 4. Príprava databázy

```bash
rails db:create
rails db:migrate
```

### 5. Načítanie modelov do databázy

Tento krok je **povinný** a je potrebné ho zopakovať vždy po zmazaní alebo resete databázy. Bez neho nefungujú embeddingy ani komunikácia s LLM.

```bash
bundle exec rails ruby_llm:load_models
```

### 6. Naplnenie testovaciho datasetu (voliteľné)

Seed vygeneruje demo používateľa (`demo@financegpt.sk` / `Demo123!`) a ~100 testovacích faktúr s rôznymi kategóriami:

```bash
rails db:seed
```

### 7. Generovanie embeddingov

Po naplnení databázy faktúrami (cez seed alebo manuálne) je potrebné vygenerovať vektorové embeddingy pre sémantické vyhľadávanie:

```bash
bundle exec rake embeddings:backfill
```

Tento príkaz prejde všetky faktúry a cez OpenAI API vygeneruje embedding pre každú z nich. Embeddingy sa ukladajú priamo do stĺpca `embedding` v tabuľke `invoices`. Pri bežnom používaní sa embeddingy generujú automaticky po uložení faktúry (cez `EmbeddingJob`).

### 8. Spustenie servera

```bash
bundle exec rails s
```

Aplikácia bude dostupná na adrese [http://localhost:3000](http://localhost:3000).

---

## Po resete alebo zmazaní databázy

Ak dôjde k resetu databázy (`rails db:reset`, `rails db:drop` a pod.), je **nevyhnutné** vykonať nasledujúce kroky v tomto poradí:

```bash
rails db:create
rails db:migrate
bundle exec rails ruby_llm:load_models    # bez tohto nefunguje ruby_llm gem
rails db:seed                              # voliteľné — demo dáta
bundle exec rake embeddings:backfill       # voliteľné — embeddingy pre demo dáta
```

---

## Štruktúra projektu

```
app/
  controllers/
    chat_controller.rb        — spracovanie konverzácie s LLM
    invoices_controller.rb    — CRUD operácie nad faktúrami
    home_controller.rb        — domovská stránka
    users_controller.rb       — používateľské profily
  models/
    chat.rb                   — model konverzácie (acts_as_chat z ruby_llm)
    message.rb                — model správy (acts_as_message z ruby_llm)
    tool_call.rb              — záznam o volaní nástroja
    invoice.rb                — model faktúry s embeddingom (has_neighbors)
    user.rb                   — model používateľa (Devise)
    entity.rb                 — predávajúci/kupujúci na faktúre
    bank_detail.rb            — bankové údaje faktúry
  services/
    sql_generator_tool.rb     — Text-to-SQL s tenant izoláciou
    semantic_search_tool.rb   — RAG vyhľadávanie cez pgvector
    cashflow_chart_tool.rb    — generovanie dát pre cashflow graf
    income_breakdown_tool.rb  — generovanie dát pre pie chart príjmov
    embedding_service.rb      — wrapper nad RubyLLM.embed()
  jobs/
    embedding_job.rb          — asynchrónne generovanie embeddingov (ActiveJob)
  views/
    chat/index.html.erb       — hlavné chatové rozhranie
  javascript/controllers/
    chat_controller.js        — Stimulus controller pre chat (fetch, Chart.js, marked.js)
config/
  initializers/ruby_llm.rb    — konfigurácia LLM providera a embedding modelu
  routes.rb                   — definícia aplikačných trás
  database.yml                — konfigurácia PostgreSQL
  importmap.rb                — pinning JS závislostí (Chart.js, marked, Stimulus)
db/
  migrate/                    — databázové migrácie
  schema.rb                   — aktuálna schéma databázy
  seeds.rb                    — generovanie testovacích dát
lib/tasks/
  embeddings.rake             — Rake task na hromadné generovanie embeddingov
test/
  services/
    sql_generator_tool_test.rb — testy bezpečnostných kontrol SQL nástroja
```

---

## Spustenie testov

```bash
bundle exec rails test
```

Testy pokrývajú bezpečnostné kontroly `SqlGeneratorTool` (odmietnutie DELETE, UPDATE, DROP, INSERT dotazov).

---

## Licencia

Tento projekt bol vytvorený ako súčasť diplomovej práce na FEI STU v Bratislave. Zdrojový kód je odovzdávaný cez Akademický informačný systém (AIS).
