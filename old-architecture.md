# Old Project Architecture

This document describes the "pre-AJAX" architecture of the jGoethe-app, a digital edition application built for the eXist-db XML database.

## 1. Data Storage in XML

The application organizes its data across several collections and XML files, optimized for structured browsing and full-text searching.

*   **Source of Truth (`jgoethe/jgoethe.xml`):**
    *   A single, comprehensive 31MB TEI XML file containing the complete transcribed text of the edition.
    *   All other XML content in the `pages/` and `toc/` collections is derived from this file.
*   **Structural Metadata (`jgoethe/configuration.xml`):**
    *   Defines the hierarchical structure of the edition.
    *   Maps logical sections (e.g., "Dramatische Schriften") to specific XPath expressions (e.g., `id('DRAMA')/ancestor::div2`) that point into the main `jgoethe.xml`.
    *   [Link to configuration.xml](jgoethe/configuration.xml)
*   **Segmented Content (`jgoethe/pages/`):**
    *   **Generated Collection:** Contains small XML "page" fragments (e.g., `ERINNERUNGEN-1.xml`) extracted from `jgoethe.xml`.
    *   Optimized for performance: `load.xql` queries these pre-sliced segments instead of parsing the 31MB source file for every request.
*   **Table of Contents (`jgoethe/toc/`):**
    *   **Generated Collection:** Stores simplified XML maps for each edition part (e.g., `WERKE.xml`).
    *   Provides the hierarchical metadata used by `scripts/edition.js` and the YUI TreeView for navigation.
*   **Static Assets:**
    *   Binary files (facsimiles, illustrations) are stored in directories like `jgoethe/handschr/`, `jgoethe/hederich/`, and `jgoethe/physfrag/`. These are referenced by the XML but are independent of the generation workflow.

## 2. Extraction & Generation Workflow

The application uses a "preprocessing" pattern to transform the monolithic source into an interactive web experience.

1.  **Scope Resolution:** The workflow starts with `configuration.xml`, which defines how the main text should be sliced using XPath.
2.  **Text Segmentation (`prepare.xq`):**
    *   Evaluates the XPaths against `jgoethe.xml`.
    *   Subdivides the resulting fragments into manageable chunks.
    *   Stores these chunks in the `/pages` collection.
    *   [Link to prepare.xq](prepare.xq)
3.  **TOC Mapping (`toc-prepare.xq`):**
    *   Traverses the TEI structure (`div1`, `div2`, etc.) in `jgoethe.xml`.
    *   Extracts titles and IDs to create a lightweight structural index.
    *   Stores these indexes as XML files in the `/toc` collection.
    *   [Link to toc-prepare.xq](toc-prepare.xq)

## 2. Information Extraction Queries

Information is extracted and transformed using XQuery modules that interface with eXist-db's indexing and transformation engines.

*   **Content Loading (`load.xql`):**
    *   Handles requests for specific sections (`part`) or specific elements (`id`).
    *   Uses `ed:load-by-id` and `ed:display` to fetch XML fragments.
    *   Triggers the XSLT transformation via `utils:transform`.
    *   [Link to load.xql](load.xql)
*   **Full-Text Search (`query-new.xql`):**
    *   Executes full-text queries using eXist-db's `ft:query()`.
    *   Provides different display modes: `single` (one-line), `multi` (multi-line), or `work` (overview by work).
    *   Uses `kwic:summarize` to generate "Key Word In Context" snippets for the search results.
    *   [Link to query-new.xql](query-new.xql)
*   **Core Utilities (`util.xqm`):**
    *   `utils:ftquery($divs, $simple)`: The central function for executing the search across a set of XML nodes.
    *   `utils:transform($sect, $params)`: Streams the XML through `tei2html.xsl` and sets appropriate HTTP headers.
    *   [Link to util.xqm](util.xqm)

## 3. Search Scope Management

The application allows users to restrict their search to specific parts or sections of the edition. This is managed through a combination of client-side selection and server-side resolution.

### Selection Mechanism
*   **UI Selection:** In `edition.xql`, the edition's structure is rendered as a table of checkboxes.
*   **Client-Side Gathering:** `scripts/edition.js` contains functions like `getPartsURL(form)` and `getSectionsURL(form)` that serialize the checked checkboxes into URL parameters (`part=...` or `section=...`).
*   **State Coordination:** The selection also updates the TOC (via `updateToC()`) to reflect what's currently active.

### Server-Side Resolution
*   **Parameter Processing:** `query-new.xql` reads the `part` and `section` parameters.
*   **Resolving to XML Nodes:**
    *   If `section` is provided, it uses `collection($col)/id($s)` to find specific nodes.
    *   If `part` is provided, it calls `ed:load-section($col, $p)`, which looks up the corresponding `xpath` in `configuration.xml` and evaluates it using `util:eval()`.
    *   [Link to query-new.xql resolution logic](query-new.xql#L151)
*   **Restricted Query Execution:** The resulting `$divs` sequence is passed to `utils:ftquery()`, ensuring that `ft:query()` only operates within the user-selected scope.
