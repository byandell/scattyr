#' Create ggplot Scatter Plot
#'
#' @param dat Data frame containing `x` and `y` columns, and optional metadata variables for coloring, shaping, or faceting.
#' @param color_by Character string specifying column name to color points by, or `"none"`. Default is `"none"`.
#' @param shape_by Character string specifying column name to set point shapes by, or `"none"`. Default is `"none"`.
#' @param facet_by Character string specifying column name to facet plot by, or `"none"`. Default is `"none"`.
#' @param add_line Logical indicating whether to add regression line(s). Default is `TRUE`.
#' @param point_size Numeric specifying size of scatter points. Default is `3`.
#' @param point_alpha Numeric specifying transparency (alpha) of scatter points (0 to 1). Default is `0.7`.
#' @param x_label Character string for X-axis label. Default is `"x"`.
#' @param y_label Character string for Y-axis label. Default is `"y"`.
#'
#' @author Brian S Yandell, \email{brian.yandell@@wisc.edu}
#' @keywords utilities
#'
#' @return A `ggplot` object (or null plot object if required columns are missing).
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_point geom_smooth facet_wrap labs scale_shape_manual scale_color_brewer scale_color_hue .data
#' @importFrom shiny isTruthy
scatter_ggplot <- function(dat,
                           color_by = "none",
                           shape_by = "none",
                           facet_by = "none",
                           add_line = TRUE,
                           point_size = 3,
                           point_alpha = 0.7,
                           x_label = "x",
                           y_label = "y") {
  if (!all(c("x", "y") %in% colnames(dat))) {
    return(plot_null("dataframe must contain x and y columns"))
  }

  # Convert candidates to factors if present
  for (col in c("sex", "diet", "geno", "Genotype")) {
    if (col %in% colnames(dat)) {
      dat[[col]] <- factor(dat[[col]])
    }
  }

  # Calculate sex_diet combination
  if (all(c("sex", "diet") %in% colnames(dat))) {
    dat$sex_diet <- factor(paste(dat$sex, dat$diet, sep = "_"))
  }

  # Ensure subject/rownames exists for label
  if (!("subject" %in% colnames(dat))) {
    dat$subject <- rownames(dat)
  }

  # Set up ggplot mapping
  aes_args <- list(x = quote(x), y = quote(y), label = quote(subject))

  # Color grouping
  col_var <- color_by
  if (!is.null(col_var) && col_var != "none" && col_var %in% colnames(dat)) {
    aes_args$col <- as.name(col_var)
    aes_args$group <- as.name(col_var)
  }

  # Shape grouping
  shape_var <- shape_by
  if (!is.null(shape_var) && shape_var != "none" && shape_var %in% colnames(dat)) {
    aes_args$shape <- as.name(shape_var)
  }

  p <- ggplot2::ggplot(dat) +
    do.call(ggplot2::aes, aes_args)

  p_size <- ifelse(is.null(point_size), 3, point_size)
  p_alpha <- ifelse(is.null(point_alpha), 0.7, point_alpha)

  # Add regression lines first (so they are plotted behind/below the symbols)
  if (shiny::isTruthy(add_line)) {
    if (!is.null(col_var) && col_var != "none" && col_var %in% colnames(dat)) {
      p <- p + ggplot2::geom_smooth(ggplot2::aes(label = NULL), method = "lm", formula = y ~ x, se = FALSE, linetype = "solid", linewidth = 1)
    } else {
      p <- p + ggplot2::geom_smooth(ggplot2::aes(group = 1, label = NULL), method = "lm", formula = y ~ x, se = FALSE, col = "black", linetype = "solid", linewidth = 1)
    }
  }

  # Add scatter points on top of regression lines
  if (is.null(shape_var) || shape_var == "none") {
    p <- p + ggplot2::geom_point(shape = 1, size = p_size, alpha = p_alpha, stroke = 1.5)
  } else {
    p <- p + ggplot2::geom_point(size = p_size, alpha = p_alpha, stroke = 1.5)
    p <- p + ggplot2::scale_shape_manual(values = c(1, 2, 5, 0, 6, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14))
  }

  # Faceting
  facet_var <- facet_by
  if (!is.null(facet_var) && facet_var != "none" && facet_var %in% colnames(dat)) {
    p <- p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet_var]]))
  }

  # Apply theme and colors
  p <- p + scattyr_plot_theme()
  # Apply custom axis labels
  p <- p + ggplot2::labs(x = x_label, y = y_label)
  if (!is.null(col_var) && col_var != "none" && col_var %in% colnames(dat)) {
    num_levels <- length(unique(dat[[col_var]]))
    if (num_levels <= 8) {
      p <- p + ggplot2::scale_color_brewer(palette = "Dark2")
    } else {
      p <- p + ggplot2::scale_color_hue()
    }
  }

  p
}
