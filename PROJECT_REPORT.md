# MauriGuide project notes

## Objective
Help tourists discover Mauritius and plan a stay from a single mobile/web interface, with personalised suggestions and sustainable travel guidance.

## Architecture
Flutter presentation and device services → curated catalogue and deterministic recommendation engine → optional HTTPS AI proxy → OpenAI. Map tiles use OpenStreetMap; weather uses Open-Meteo. Device preferences remain local. Location is requested only by the location action and is used locally for distance calculations. Directions and external search links share the selected destination with the chosen external provider.

## Recommendation method
Filter places by maximum activity budget; rank matches to selected interests ahead of other entries, then group by region. Construct up to two stops per day, preferring the first remaining region and enforcing each day's total activity cost. Never repeat a stop. Empty later days are marked as free days rather than inventing destinations. The method is transparent and deterministic; it is not a trained machine learning model.

## Scope against the brief

| Requirement | Implementation |
|---|---|
| Mobile/web guide | Flutter web, Android and iOS source |
| AI chatbot | Local curated replies plus optional server-side LLM |
| Personalised attractions | Interest and budget ranking |
| Restaurants/hotels/activities | Curated activities; external restaurant and hotel search |
| Itinerary | Duration, budget and interests; grouping by region |
| Current location | Nearby discovery; not yet a planner origin |
| Interactive map/GPS | OSM map, location marker and external navigation |
| Real-time information | Current Port Louis weather; external information links |
| Events, transport and hours | External sources/advice; no live ingestion |
| Languages | Core navigation and guide replies in EN/FR/Kreol; partial UI coverage |
| Profile/feedback | Local preferences, favourites and rating |
| Evaluation | Automated checks plus proposed user study below |
| Web scraping | Not implemented; curated data avoids unverified scraping |

## Evaluation plan
Automated tests check budget constraints, stop uniqueness, interest ranking, and generation through the UI. A release web compilation checks the deployable target. Browser smoke checks should cover desktop/mobile layouts and navigation. Native GPS, iOS permissions and release builds need physical-device or simulator validation.

For an academic study, recruit consenting participants and define travel scenarios before testing. Measure task completion, time to generate a suitable itinerary, usefulness ratings, language clarity and satisfaction. Have Mauritius tourism reviewers independently score recommendation relevance and factual accuracy. Record median/p95 recommendation and chatbot latency, network failures and fallback rate. Do not claim results before collecting them. Scraping, comprehensive translation, live tourism feeds and geospatial routing are future work.
