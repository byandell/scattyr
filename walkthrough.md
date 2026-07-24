# Scatter Walkthrough

## Prompts

- Capture process in `walkthrough.md`.
- Extract the construction of `plot_obj` from `scatterPlotApp.R` into file `scatter.R` as a function `scatter_ggplot`. Document the function. Modify `scatterPlotApp.R` to use this function (including sourcing the file).
- Create a python version of the scatter plot app. Use `plotnine` for plotting.
- Prepare repo to publish to GitHub and GitHub Pages. Update `.gitignore` as needed.
- Create `shinylive` demo 'cards' for the R and Python versions that will be visible on the published page, in a similar manner to <https://byandell.github.io/geyser/docs/demos/> but in root (`/`) not `docs/`. Ensure this is done as serverless WebAssembly (WASM) apps. Link card from top-level `index.qmd` to `README.md`.

## Results

### R Scatter Plot App

1. **Created [`scatter.R`](file:///Users/brianyandell/Documents/GitHub/scattyr/scatter.R)**:
   - Defined the function `scatter_ggplot(dat, color_by, shape_by, facet_by, add_line, point_size, point_alpha, x_label, y_label)` containing the extracted `ggplot2` construction logic.
   - Added complete Roxygen2 documentation (`@param`, `@return`, `@export`, `@importFrom`, etc.) for the function.

2. **Updated [`scatterPlotApp.R`](file:///Users/brianyandell/Documents/GitHub/scattyr/scatterPlotApp.R)**:
   - Sourced `scatter.R` and `theme.R`.
   - Updated `plot_obj` reactive inside `scatterPlotServer` to invoke `scatter_ggplot()`.

3. **Execution Commands**:
   - **From Shell**:

     ```bash
     Rscript -e 'source("scatterPlotApp.R"); scatterPlotApp()'
     ```

   - **From R / Quarto (`.qmd`) code block**:

     ```r
     source("scatterPlotApp.R")
     scatterPlotApp()
     ```

### Python Scatter Plot App

1. **Created [`scatter.py`](file:///Users/brianyandell/Documents/GitHub/scattyr/scatter.py)**:
   - Defined `scatter_plotnine(dat, color_by, shape_by, facet_by, add_line, point_size, point_alpha, x_label, y_label)` using `plotnine` (`ggplot`, `aes`, `geom_point`, `geom_smooth`, `facet_wrap`, `labs`, `theme_minimal`, `scale_shape_manual`, `scale_color_brewer`, `scale_color_hue`).
   - Handles metadata columns (`sex`, `diet`, `geno`, `Genotype`, `sex_diet`), mappings, regression lines, and custom point aesthetics (open symbols with transparent fill via `fill="none"` and `stroke=1.5`).

2. **Created [`scatter_plot_app.py`](file:///Users/brianyandell/Documents/GitHub/scattyr/scatter_plot_app.py)**:
   - Built a Shiny for Python app featuring modular UI (`scatter_plot_input`, `scatter_plot_output`) and server logic (`scatter_plot_server`).
   - Included `make_mock_df()` to mirror the R mock dataset generation.
   - Renders static plots with `plotnine` via `@render.plot` and interactive plots with `plotly` via `shinywidgets.render_widget`.

3. **Execution Commands**:
   - **From Shell**:

     ```bash
     shiny run scatter_plot_app.py
     ```

   - **From Python / Quarto (`.qmd`) code block**:

     ```python
     from scatter_plot_app import app
     app.run()
     ```

### Quarto Site & Demos Gallery (`./demos`)

1. **Quarto Website Configuration ([`_quarto.yml`](file:///Users/brianyandell/Documents/GitHub/scattyr/_quarto.yml)) & [`.gitignore`](file:///Users/brianyandell/Documents/GitHub/scattyr/.gitignore)**:
   - Configured `output-dir: .` and `embed-resources: true` in [`_quarto.yml`](file:///Users/brianyandell/Documents/GitHub/scattyr/_quarto.yml) so Quarto embeds resources and renders standalone HTML outputs (`demos/*.html`, `index.html`) in-place.
   - Pointed rendering targets to `./demos/index.qmd`, `./demos/r_scatter_app.qmd`, and `./demos/python_scatter_app.qmd` using `shinylive` filter (`quarto-ext/shinylive`).
   - Added `site_libs/`, `_site/`, `_extensions/`, and `.quarto/` to [`.gitignore`](file:///Users/brianyandell/Documents/GitHub/scattyr/.gitignore) to ensure support asset directories are not committed or exported to GitHub.

2. **Top-Level Demos Gallery Listing Grid ([`demos/index.qmd`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/index.qmd))**:
   - Moved Demos Gallery to top-level `./demos/index.qmd` displaying Quarto grid listing cards (`listing: type: grid`).

3. **Interactive WebAssembly Demo Pages**:
   - **[`demos/r_scatter_app.qmd`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/r_scatter_app.qmd)**: Interactive serverless R Shinylive app (`{shinylive-r}`) running directly in the browser, with source code tabsets reading `../scatterPlotApp.R`, `../scatter.R`, and `../theme.R`.
   - **[`demos/python_scatter_app.qmd`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/python_scatter_app.qmd)**: Interactive serverless Python Shinylive app (`{shinylive-python}`) running `plotnine` and `scatter_plotnine()` in the browser, with source code tabsets reading `../scatter_plot_app.py` and `../scatter.py`.

4. **Landing Page Integration ([`index.qmd`](file:///Users/brianyandell/Documents/GitHub/scattyr/index.qmd) & [`README.md`](file:///Users/brianyandell/Documents/GitHub/scattyr/README.md))**:
   - `index.qmd` includes `README.md`.
   - Removed `./docs` directory completely.
   - Updated `README.md` demo cards to link to `demos/r_scatter_app.html` and `demos/python_scatter_app.html`.

5. **Rendered HTML Output**:
   - Preserved rendered HTML files ([`demos/index.html`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/index.html), [`demos/r_scatter_app.html`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/r_scatter_app.html), and [`demos/python_scatter_app.html`](file:///Users/brianyandell/Documents/GitHub/scattyr/demos/python_scatter_app.html)) in the `demos/` directory so they are saved and ready to be committed and pushed to GitHub.
