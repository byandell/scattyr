#' Shiny Scatter Plot App
#'
#' @param id identifier for shiny reactive
#' @param plot_df reactive data frame containing columns: x, y, and optionally sex, diet, geno
#'
#' @author Brian S Yandell, \email{brian.yandell@@wisc.edu}
#' @keywords utilities
#'
#' @return No return value; called for side effects.
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_smooth theme_minimal scale_color_brewer scale_color_hue facet_wrap labs vars scale_shape_manual
#' @importFrom plotly renderPlotly plotlyOutput ggplotly
#' @importFrom shiny checkboxInput fluidRow column isolate isTruthy moduleServer NS observeEvent plotOutput radioButtons reactive renderPlot renderUI req selectInput sliderInput strong tagList uiOutput updateSelectInput updateSliderInput withProgress
#' @importFrom bslib card layout_sidebar page_sidebar sidebar
source("scatter.R")
source("theme.R")

scatterPlotApp <- function() {
  # Mock data frame creation
  set.seed(42)
  n <- 200
  mock_df <- data.frame(
    subject = paste0("ind_", 1:n),
    x = rnorm(n),
    sex = sample(c("Female", "Male"), n, replace = TRUE),
    diet = sample(c("Chow", "HF"), n, replace = TRUE),
    geno = sample(c("AA", "AB", "BB"), n, replace = TRUE),
    stringsAsFactors = FALSE
  )
  # y is a function of x, sex, diet, and genotype
  mock_df$y <- 2 * mock_df$x +
    ifelse(mock_df$sex == "Male", 1.5, 0) +
    ifelse(mock_df$diet == "HF", -1, 0) +
    ifelse(mock_df$geno == "AB", 0.5, ifelse(mock_df$geno == "BB", 1, 0)) +
    rnorm(n, sd = 0.8)

  rownames(mock_df) <- mock_df$subject

  ui <- bslib::page_sidebar(
    title = "Test Generic Scatter Plot",
    sidebar = bslib::sidebar(
      scatterPlotInput("scatter")
    ),
    bslib::card(scatterPlotOutput("scatter"))
  )

  server <- function(input, output, session) {
    scatterPlotServer("scatter", shiny::reactive(mock_df))
  }

  shiny::shinyApp(ui, server)
}
#' @export
#' @rdname scatterPlotApp
scatterPlotServer <- function(id, plot_df, x_label = shiny::reactive("x"), y_label = shiny::reactive("y")) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Render dynamic UI choices based on columns of plot_df
    output$scatter_inputs <- shiny::renderUI({
      dat <- shiny::req(plot_df())
      cols <- colnames(dat)

      # Exclude x, y, and subject for color/shape/facet variables
      candidate_vars <- cols[!(cols %in% c("x", "y", "subject"))]

      # If sex and diet are present, sex_diet is a candidate
      if (all(c("sex", "diet") %in% cols)) {
        candidate_vars <- c(candidate_vars, "sex_diet")
      }

      # Clean choices
      color_choices <- c("None" = "none")
      for (var in candidate_vars) {
        color_choices[var] <- var
      }

      shape_choices <- c("None" = "none")
      for (var in candidate_vars[candidate_vars != "sex_diet"]) {
        shape_choices[var] <- var
      }

      facet_choices <- c("None" = "none")
      for (var in candidate_vars) {
        facet_choices[var] <- var
      }

      shiny::tagList(
        shiny::radioButtons(ns("static"), "Plot Type:", c("Static", "Interactive"), "Static"),
        shiny::selectInput(ns("color_by"), "Color by:", choices = color_choices, selected = "none"),
        shiny::selectInput(ns("shape_by"), "Shape by:", choices = shape_choices, selected = "none"),
        shiny::selectInput(ns("facet_by"), "Facet by:", choices = facet_choices, selected = "none"),
        shiny::checkboxInput(ns("add_line"), "Add regression line?", TRUE),
        shiny::sliderInput(ns("point_size"), "Point Size:", min = 1, max = 10, value = 3, step = 0.5),
        shiny::sliderInput(ns("point_alpha"), "Transparency (Alpha):", min = 0.1, max = 1, value = 0.7, step = 0.1)
      )
    })

    # Render static ggplot
    output$plot_static <- shiny::renderPlot({
      print(shiny::req(plot_obj()))
    })

    # Render interactive plotly
    output$plot_interactive <- plotly::renderPlotly({
      p <- shiny::req(plot_obj())
      plotly::ggplotly(p)
    })

    # Renders the UI wrapper that switches static/interactive
    output$plot_ui <- shiny::renderUI({
      static_val <- ifelse(is.null(input$static), "Static", input$static)
      switch(static_val,
        Static = shiny::plotOutput(ns("plot_static")),
        Interactive = plotly::plotlyOutput(ns("plot_interactive"))
      )
    })

    # Construct the plot object
    plot_obj <- shiny::reactive({
      scatter_ggplot(
        dat = shiny::req(plot_df()),
        color_by = input$color_by,
        shape_by = input$shape_by,
        facet_by = input$facet_by,
        add_line = input$add_line,
        point_size = input$point_size,
        point_alpha = input$point_alpha,
        x_label = x_label(),
        y_label = y_label()
      )
    })

    # Return the ggplot reactive
    plot_obj
  })
}
#' @export
#' @rdname scatterPlotApp
scatterPlotInput <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("scatter_inputs"))
}
#' @export
#' @rdname scatterPlotApp
scatterPlotOutput <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("plot_ui"))
}
