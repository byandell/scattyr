"""
Scatter plot rendering using plotnine.
"""

import pandas as pd
import numpy as np
from plotnine import (
    ggplot, aes, geom_point, geom_smooth, facet_wrap, labs,
    theme_minimal, scale_shape_manual, scale_color_brewer, scale_color_hue
)
from typing import Optional


def scatter_plotnine(
    dat: pd.DataFrame,
    color_by: str = "none",
    shape_by: str = "none",
    facet_by: str = "none",
    add_line: bool = True,
    point_size: float = 3.0,
    point_alpha: float = 0.7,
    x_label: str = "x",
    y_label: str = "y"
) -> Optional[ggplot]:
    """
    Create a plotnine scatter plot mirroring scatter_ggplot in R.

    Parameters
    ----------
    dat : pd.DataFrame
        DataFrame containing 'x' and 'y' columns, plus metadata variables.
    color_by : str
        Column name to color points by, or "none". Default is "none".
    shape_by : str
        Column name to set point shapes by, or "none". Default is "none".
    facet_by : str
        Column name to facet plot by, or "none". Default is "none".
    add_line : bool
        Whether to add linear regression line(s). Default is True.
    point_size : float
        Scatter point size. Default is 3.0.
    point_alpha : float
        Scatter point transparency (0.0 to 1.0). Default is 0.7.
    x_label : str
        X-axis label. Default is "x".
    y_label : str
        Y-axis label. Default is "y".

    Returns
    -------
    plotnine.ggplot.ggplot or None
        A plotnine ggplot object, or None if required columns are missing.
    """
    if dat is None or not isinstance(dat, pd.DataFrame):
        return None

    if "x" not in dat.columns or "y" not in dat.columns:
        return None

    df = dat.copy()

    # Convert candidates to category if present
    for col in ["sex", "diet", "geno", "Genotype"]:
        if col in df.columns:
            df[col] = df[col].astype("category")

    # Calculate sex_diet combination if both columns exist
    if "sex" in df.columns and "diet" in df.columns:
        df["sex_diet"] = (df["sex"].astype(str) + "_" + df["diet"].astype(str)).astype("category")

    # Ensure subject column exists for labeling
    if "subject" not in df.columns:
        df["subject"] = df.index.astype(str)

    mapping = {"x": "x", "y": "y"}

    col_var = color_by if (color_by and color_by != "none" and color_by in df.columns) else None
    shape_var = shape_by if (shape_by and shape_by != "none" and shape_by in df.columns) else None
    facet_var = facet_by if (facet_by and facet_by != "none" and facet_by in df.columns) else None

    if col_var:
        mapping["color"] = col_var
        mapping["group"] = col_var

    if shape_var:
        mapping["shape"] = shape_var

    p = ggplot(df, aes(**mapping))

    # Add regression lines first (so they are plotted behind/below symbols)
    if add_line:
        if col_var:
            p += geom_smooth(method="lm", se=False, linetype="solid", size=1)
        else:
            p += geom_smooth(aes(group=1), method="lm", se=False, color="black", linetype="solid", size=1)

    # Add scatter points (open symbols / transparent fill matching R ggplot shape=1)
    if not shape_var:
        p += geom_point(shape="o", fill="none", size=point_size, alpha=point_alpha, stroke=1.5)
    else:
        p += geom_point(fill="none", size=point_size, alpha=point_alpha, stroke=1.5)
        shapes = ["o", "s", "^", "D", "v", "p", "*", "+", "x", "h", "8", "H", "d", "|", "_"]
        p += scale_shape_manual(values=shapes)

    # Faceting
    if facet_var:
        p += facet_wrap(f"~ {facet_var}")

    # Theme and custom labels
    p += theme_minimal(base_size=9)
    p += labs(x=x_label, y=y_label)

    if col_var:
        num_levels = df[col_var].nunique()
        if num_levels <= 8:
            p += scale_color_brewer(type="qual", palette="Dark2")
        else:
            p += scale_color_hue()

    return p
