"""
Shiny Scatter Plot Application in Python using plotnine.
"""

import pandas as pd
import numpy as np
from shiny import App, Inputs, Outputs, Session, module, reactive, render, ui
from shinywidgets import output_widget, render_widget
import plotly.express as px

from scatter import scatter_plotnine


def make_mock_df(n: int = 200, seed: int = 42) -> pd.DataFrame:
    """Generate mock dataset for generic scatter plot app."""
    np.random.seed(seed)
    df = pd.DataFrame({
        "subject": [f"ind_{i+1}" for i in range(n)],
        "x": np.random.randn(n),
        "sex": np.random.choice(["Female", "Male"], n),
        "diet": np.random.choice(["Chow", "HF"], n),
        "geno": np.random.choice(["AA", "AB", "BB"], n),
    })
    y = (
        2 * df["x"]
        + np.where(df["sex"] == "Male", 1.5, 0.0)
        + np.where(df["diet"] == "HF", -1.0, 0.0)
        + np.where(df["geno"] == "AB", 0.5, np.where(df["geno"] == "BB", 1.0, 0.0))
        + np.random.randn(n) * 0.8
    )
    df["y"] = y
    df.index = df["subject"]
    return df


@module.ui
def scatter_plot_input():
    return ui.output_ui("scatter_inputs")


@module.ui
def scatter_plot_output():
    return ui.output_ui("plot_ui")


@module.server
def scatter_plot_server(
    input: Inputs,
    output: Outputs,
    session: Session,
    plot_df: reactive.Calc,
    x_label: callable = lambda: "x",
    y_label: callable = lambda: "y"
):
    @output
    @render.ui
    def scatter_inputs():
        dat = plot_df()
        if dat is None or dat.empty:
            return ui.TagList()

        cols = list(dat.columns)
        candidate_vars = [c for c in cols if c not in ["x", "y", "subject"]]

        if "sex" in cols and "diet" in cols:
            candidate_vars.append("sex_diet")

        color_choices = {"none": "None"}
        for v in candidate_vars:
            color_choices[v] = v

        shape_choices = {"none": "None"}
        for v in candidate_vars:
            if v != "sex_diet":
                shape_choices[v] = v

        facet_choices = {"none": "None"}
        for v in candidate_vars:
            facet_choices[v] = v

        return ui.TagList(
            ui.input_radio_buttons("static", "Plot Type:", ["Static", "Interactive"], selected="Static"),
            ui.input_select("color_by", "Color by:", choices=color_choices, selected="none"),
            ui.input_select("shape_by", "Shape by:", choices=shape_choices, selected="none"),
            ui.input_select("facet_by", "Facet by:", choices=facet_choices, selected="none"),
            ui.input_checkbox("add_line", "Add regression line?", value=True),
            ui.input_slider("point_size", "Point Size:", min=1, max=10, value=3, step=0.5),
            ui.input_slider("point_alpha", "Transparency (Alpha):", min=0.1, max=1, value=0.7, step=0.1),
        )

    @reactive.calc
    def plot_obj():
        dat = plot_df()
        if dat is None or "x" not in dat.columns or "y" not in dat.columns:
            return None

        col_by = input.color_by() if "color_by" in input else "none"
        shp_by = input.shape_by() if "shape_by" in input else "none"
        fct_by = input.facet_by() if "facet_by" in input else "none"
        add_l = input.add_line() if "add_line" in input else True
        pt_sz = input.point_size() if "point_size" in input else 3
        pt_al = input.point_alpha() if "point_alpha" in input else 0.7

        x_lbl = x_label() if callable(x_label) else x_label
        y_lbl = y_label() if callable(y_label) else y_label

        return scatter_plotnine(
            dat=dat,
            color_by=col_by,
            shape_by=shp_by,
            facet_by=fct_by,
            add_line=add_l,
            point_size=pt_sz,
            point_alpha=pt_al,
            x_label=x_lbl,
            y_label=y_lbl
        )

    @output
    @render.plot
    def plot_static():
        p = plot_obj()
        return p

    @output
    @render_widget
    def plot_interactive():
        dat = plot_df()
        if dat is None or dat.empty:
            return None
        df = dat.copy()
        if "sex" in df.columns and "diet" in df.columns:
            df["sex_diet"] = df["sex"].astype(str) + "_" + df["diet"].astype(str)

        col_by = input.color_by() if ("color_by" in input and input.color_by() != "none") else None
        shp_by = input.shape_by() if ("shape_by" in input and input.shape_by() != "none") else None
        fct_by = input.facet_by() if ("facet_by" in input and input.facet_by() != "none") else None

        x_lbl = x_label() if callable(x_label) else x_label
        y_lbl = y_label() if callable(y_label) else y_label

        add_l = input.add_line() if "add_line" in input else True

        open_symbols = ["circle-open", "square-open", "diamond-open", "triangle-up-open", "triangle-down-open", "star-open", "cross-open"]
        fig = px.scatter(
            df,
            x="x",
            y="y",
            color=col_by,
            symbol=shp_by,
            symbol_sequence=open_symbols,
            facet_col=fct_by,
            hover_name="subject" if "subject" in df.columns else None,
            labels={"x": x_lbl, "y": y_lbl},
            trendline="ols" if add_l else None
        )
        if not shp_by:
            fig.update_traces(marker_symbol="circle-open")
        fig.update_layout(template="plotly_white")
        return fig

    @output
    @render.ui
    def plot_ui():
        static_val = input.static() if "static" in input else "Static"
        if static_val == "Interactive":
            return output_widget("plot_interactive")
        else:
            return ui.output_plot("plot_static")


def scatter_plot_app():
    """Create and return the Shiny App for scatter plot."""
    mock_df = make_mock_df()

    app_ui = ui.page_sidebar(
        ui.sidebar(
            scatter_plot_input("scatter")
        ),
        ui.card(
            scatter_plot_output("scatter")
        ),
        title="Test Generic Scatter Plot (Python / plotnine)"
    )

    def server(input: Inputs, output: Outputs, session: Session):
        scatter_plot_server("scatter", reactive.calc(lambda: mock_df))

    return App(app_ui, server)


app = scatter_plot_app()
