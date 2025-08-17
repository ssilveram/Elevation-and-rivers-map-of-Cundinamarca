################################################################################
##                                                                            ##
##                    ELEVATION MAP AND RIVERS IN COLOMBIA                    ##
##                                                                            ##
## The associated R script was produced as part of an independent consulting  ##
## study in 2024, which aimed to determine the optimal railway route          ##
## connecting Bogotá and the Magdalena River in Colombia. The elevation data  ##
## was processed by an algorithm to navigate the ~2,200-meter descent between ##
## the two locations while adhering to strict constraints on slope, height,   ##
## and track radius. The map produced by this script was for illustrative     ##
## purposes only.                                                             ##
##                                                                            ##
## The processed elevation data was then used by a separate path-finding      ##
## algorithm (not included in this script) to calculate the optimal route.    ##
##                                                                            ##
## ©2024. Santiago Silvera. Berlin, Germany.                                  ##
##                                                                            ##
################################################################################

# --- 1. Load necessary libraries ---

# I recommend installing the PacMan library:
#install.packages("pacman")

# Load necessary libraries:
pacman::p_load(
  terra,
  elevatr,
  sf,
  geodata,
  rayshader,
  rayrender,
  magick,
  glue,
  tidyverse
)

# --- 2. Import the elevation data for Colombia ---

# We establish the route where we will save the data:
path <- file.path(getwd(), "shp2")

# Get the elevation data:
elevacion_municipio_sf <- geodata::gadm(
  country = "COL",
  level = 2, # Level 2 for municipalities
  path = path
  ) |>
  sf::st_as_sf()

# Filter by Cundinamarca
shape_area_filtrada <- elevacion_municipio_sf |>
  dplyr::filter(NAME_1 %in% c("Bogotá D.C.", "Cundinamarca"))

# Create an union to get a sfc:
shape_area_unida <- sf::st_union(shape_area_filtrada)

# Extract the coordinates:
Coordinates_CRS <- st_crs(shape_area_unida)

# --- 3. Import the rivers data for Colombia ---

# Set the URL for rivers data (in this case is all South America):
url_del_archivo <- "https://data.hydrosheds.org/file/HydroRIVERS/HydroRIVERS_v10_sa_shp.zip"

# Set the path and filename before download:
ruta_destino <- file.path(path, "rivers")
nombre_del_archivo <- "rivers_data_downloaded.zip"
ruta_completa_archivo <- file.path(ruta_destino, nombre_del_archivo)

# If path doesn't exist, create it:
if (!dir.exists(ruta_destino)) {
  dir.create(ruta_destino)
}

# Check if the rivers data already exists in our computer:
if (!file.exists(ruta_completa_archivo)) {
  # Download the rivers data for Colombia from HydroRIVERS:
  download.file(url = url_del_archivo, destfile = ruta_completa_archivo, mode = "wb")
  
  # Unzip the downloaded file:
  unzip(ruta_completa_archivo, exdir = ruta_destino_rios)
  print(paste("File downloaded and unziped sucessful in:", ruta_destino))
} else {
  print("Data rivers already exists. Download skiped.")
}

# Set the bounding box for Cundinamarca:
BB <- sf::st_bbox(shape_area_unida)

# Get coordinates for the BB, and create a geometry (box) to use as filter later:
bbox_wkt<- glue::glue(
  "POLYGON((",
  BB[["xmin"]]," ",BB[["ymin"]],",",
  BB[["xmin"]]," ",BB[["ymax"]],",",
  BB[["xmax"]]," ",BB[["ymax"]],",",
  BB[["xmax"]]," ",BB[["ymin"]],",",
  BB[["xmin"]]," ",BB[["ymin"]],"))"
)

# Get the rivers loading the shape and filter it by the geometry (box), and intersects with Cundinamarca:
rivers <- sf::st_read(
  paste0(path, "/rivers/HydroRIVERS_v10_sa_shp/HydroRIVERS_v10_sa.shp"),
  wkt_filter = bbox_wkt
) |>
  sf::st_collection_extract("LINESTRING") |>
  sf::st_intersection(shape_area_unida)

# Check the rivers in a quick plot:
plot(sf::st_geometry(rivers))

# --- 4. Set values for the width of the rivers ---

# Set a new CRS system for the rivers:
CRS <- "+proj=tmerc +lat_0=4.59620041666667 +lon_0=-74.0775079166667 +k=1 +x_0=1000000 +y_0=1000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs"

# Change the width of the rivers:
rivers_width <- rivers |>
  dplyr::mutate(
    width = as.numeric(
      ORD_FLOW
    ),
    width = dplyr::case_when(
      width == 2 ~ 18,
      width == 3 ~ 16,
      width == 4 ~ 14,
      width == 5 ~ 12,
      width == 6 ~ 10,
      width == 7 ~ 6,
      width == 8 ~ 3,
      TRUE ~ 0
    )
  ) |>
  sf::st_as_sf() |>
  sf::st_transform(crs = CRS)

# --- 5. DEM ---

shape_area_filtrada
st_union(shape_area_filtrada)
?elevatr::get_elev_raster()

# Set DEM - Get the Raster Elevation
dem <- elevatr::get_elev_raster(
  locations = st_as_sf(shape_area_filtrada |> st_union()),
#  locations = shape_area_filtrada |> sf::st_transform(crs = CRS),
  z = 9,
  clip = "locations",
  verbose = FALSE
)
dem

# Set the dem area using terra library:
dem_area <- dem |>
  terra::rast() |>
  terra::project(CRS)
dem_area

# Set the dem matrix:
dem_matrix <- rayshader::raster_to_matrix(
  dem_area
)
dem_matrix

# Guardamos hasta aquí:
save(
  dem,
  rivers_width,
  dem_area,
  dem_matrix,
  file = file.path(path, "Dem_data.RData")
)
load(file.path(path, "Dem_data.RData"))

file.path(path, "Dem_data.RData")

# --- 6. Render the scene map ---

# Render the scene:
dem_matrix |>
  rayshader::height_shade(
    texture = colorRampPalette(
      c(
        "#fcc69f",
        "#c67847"
      )
    )(128)
  ) |>
  rayshader::add_overlay(
    rayshader::generate_line_overlay(
      geometry = rivers_width,
      extent = dem_area,
      heightmap = dem_matrix,
      color = "#387B9C",
      linewidth = rivers_width$width,
      data_column_width = "width"
    ), alphalayer = 1
  ) |>
  rayshader::plot_3d(
    dem_matrix,
    zscale = 20,
    solid = FALSE,
    shadow = TRUE,
    shadow_darkness = 1,
    background = "white",
    windowsize = c(1080, 1080),
    zoom = .5,
    phi = 89,
    theta = 0
  )

# Set the zoom in the camera:
rayshader::render_camera(
  zoom = .75
)

# --- 7. Render the object in high quality ray tracing and save as image ---

# Download the HDR file:
url_hdr_file <- "https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/4k/photo_studio_loft_hall_4k.hdr"
hdr_file <- file.path(path, basename(url_hdr_file))

# Check if the HDR file already exists in our computer:
if (!file.exists(ruta_completa_archivo)) {
  # Download the HDR file:
  download.file(
    url = url_hdr_file,
    destfile = hdr_file,
    mode = "wb"
  )
  print(paste("File downloaded sucessful in:", hdr_file))
} else {
  print("HDR file already exists. Download skiped.")
}

# Render the object in high quality image using ray tracing:
file_name <- "Full-size_map_of_Cundinamarca.png"
rayshader::render_highquality(
  filename = file_name,
  preview = TRUE,
  light = FALSE,
  environment_light = hdr_file,
  intensity_env = 1,
  interactive = FALSE,
  width = 1200,
  height = 1200
)

# --- 8. Load the image and add the text ---

Map_Image_Original <- image_read(file_name)
Map_Image_Original

Final_Map <- Map_Image_Original |>
  image_scale("800") |>
  image_annotate(
    "Cundinamarca",
    size = 50,
    color = "#996633",
    location = "+440+598",
    font = 'Times'
    ) |>
  image_annotate(
    "___________",
    size = 53,
    color = "#996633",
    location = "+440+593",
    font = 'Times'
  ) |>
  image_annotate(
    "River and elevation map",
    size = 30,
    color = "#996633",
    location = "+440+650",
    font = 'Times'
  ) |>
  image_annotate(
    "©2024 Santiago Silvera. Created using R+Rayshader.",
    size = 11,
    color = "#336666",
    location = "+465+685",
    font = 'Times'
  ) |>
  image_annotate(
    "Data: HydroSHEDS + Elevation: Amazon Web Services Terrain",
    size = 11,
    color = "#336666",
    location = "+440+700",
    font = 'Times'
  ) |>
  image_annotate(
    "Tiles and the Open Topography via elevatr R package.",
    size = 11,
    color = "#336666",
    location = "+463+715",
    font = 'Times'
  )

# Save the final image map:
image_write(Final_Map, path = "Elevation_and_Rivers_Map.png", format = "png")

# Delete the full-size map:
if (file.exists(file_name)) {
  file.remove(file_name)
  cat("Full-size map file deleted.")
} else {
  cat("Full-size map file not found, Deletion skiped.")
}

# Show the final map:
Final_Map <- image_read("Elevation_and_Rivers_Map.png")
print(Final_Map)

# --- End of the Script ---
