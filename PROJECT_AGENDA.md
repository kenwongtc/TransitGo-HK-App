# TransitGo HK Project Agenda

## Current implementation order

1. Fix route-line and stop-coordinate alignment on Journey Map. *(Completed)*
2. Complete a localization audit for remaining English text. *(Completed)*
3. Improve ETA loading and error indicators on favorite-stop route rows. *(Completed)*
4. Review sectional and joint-operator fare accuracy with sample routes. *(Completed)*
5. Run a complete smoke test across Favorites, Nearby, Search, Route Details, Stop Details, and Settings. *(Completed)*

## Later

- Add stop-area grouping for nearby boarding points, including bus-bus interchanges (BBIs). Nearby should use GPS to select a stop area, then show a combined ETA list while preserving each physical stop name and code. Group conservatively using distance, name similarity, and manual interchange overrides. *(Completed)*

## Upcoming

1. Rename “More Operators” to “More Transport,” since the section includes transport and service categories rather than operators only.
2. Complete Theme Park route testing with Disneyland and Ocean Park sample routes.
3. Build the Cross-Boundary flow: port selection followed by suggested bus and minibus routes.
4. Continue Smart Search by improving district and location selection and route matching.
5. Audit hard-coded interface titles and move them into the String Catalog.
6. Later, review grouped nearby-stop and BBI ETA presentation, the home-screen ETA widget and optional support purchase, and an iPad-specific interface redesign.
