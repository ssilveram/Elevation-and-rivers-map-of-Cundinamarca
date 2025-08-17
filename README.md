# Elevation map and rivers in Cundinamarca, Colombia

The associated R script was produced as part of an independent consulting study in 2024, which aimed to determine the optimal railway route connecting Bogotá and the Magdalena River in Colombia. The elevation data was processed by an algorithm to navigate the ~2,200-meter descent between the two locations while adhering to strict constraints for slope, height, and track radius. The resulting map was for illustrative purposes only.

The processed elevation data was then used by a separate path-finding algorithm (not included in this script) to calculate the optimal route.

![Elevation and rivers map of Cundinamarca, Colombia.png](assets/Elevation_and_Rivers_Map.png)


## 🚀 How to use this script

It's recommended to install the `pacman` package, which installs the libraries needed to run the script. All step-by-step details are included as comments within the code.

Have fun!

## 🛠️ Technologies used

**[R](https://cran.rstudio.com/)**: Version 4.3.3.

**[RStudio](https://posit.co/download/rstudio-desktop/)**: Version 2025.05.0.

R Packages: `pacman`, `sf`, `terra`, `elevatr`, `geodata`, `rayshader`, `rayrender`, `magick`, `glue` and `tidyverse`.

Data sources: [HydroSHEDS](https://www.hydrosheds.org/products/hydrorivers) + Elevation: [Amazon Web Services Terrain Tiles](https://registry.opendata.aws/terrain-tiles/) and [Open Topography](https://opentopography.org/) via `elevatr` package.

©2024, **[Santiago Silvera](https://github.com/ssilveram)**. Berlin, Germany.
