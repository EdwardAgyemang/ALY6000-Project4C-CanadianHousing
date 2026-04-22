# =============================================================================
# ALY 6000 – Project 4C: Canadian Housing Market Analysis
# Dataset : HouseListings-Top45Cities.csv (35,768 rows × 10 columns)
# Author  : Edward Agyemang
# School  : Northeastern University – Vancouver Campus
# Date    : April 2026
# =============================================================================


# -----------------------------------------------------------------------------
# SECTION 1: SETUP
# -----------------------------------------------------------------------------

# Reset environment — clears all previous variables
rm(list = ls())

# Set working directory
setwd("C:/Users/elitebook folio/Documents/EDWARD PROJECTS/ALY6000/Project 4/Project 4C")

# Load required packages
library(pacman)
p_load(tidyverse, janitor, ggplot2, scales, dplyr, corrplot)


# -----------------------------------------------------------------------------
# SECTION 2: IMPORT DATA
# -----------------------------------------------------------------------------

housing_raw <- read_csv(
  "HouseListings-Top45Cities.csv",
  locale = locale(encoding = "latin1")  # handles French city names (e.g. e with accent)
)

# Quick first look
glimpse(housing_raw)
head(housing_raw, 10)
dim(housing_raw)   # 35,768 rows x 10 columns


# -----------------------------------------------------------------------------
# SECTION 3: DATA CLEANING
# -----------------------------------------------------------------------------

# --- 3A. Standardize column names to snake_case ---
housing <- housing_raw %>%
  clean_names()

# Confirm names
names(housing)
# city, price, address, number_beds, number_baths,
# province, population, latitude, longitude, median_family_income

# --- 3B. Check for missing values ---
colSums(is.na(housing))
# Result: no missing values — dataset is complete

# --- 3C. Inspect value ranges to identify potential outliers ---
summary(housing$price)
# Min: $21,500  |  Max: $37,000,000  — extreme values present

range(housing$number_beds)    # 0 – 109  — data entry errors present
range(housing$number_baths)   # 0 – 20   — data entry errors present

# --- 3D. Remove outliers and data entry errors ---
# Rationale:
#   Price < $50,000   — likely land-only parcels or uninhabitable listings
#   Price > $5,000,000 — ultra-luxury outliers that skew national averages (<1%)
#   Beds = 0          — not a residential listing
#   Beds > 8          — commercial or data entry error (e.g. 109 beds)
#   Baths = 0         — not a residential listing
#   Baths > 8         — same logic as beds

housing_clean <- housing %>%
  filter(
    price        >= 50000  & price        <= 5000000,
    number_beds  >= 1      & number_beds  <= 8,
    number_baths >= 1      & number_baths <= 8
  )

# Rows removed
nrow(housing_raw) - nrow(housing_clean)  # 1,387 rows removed

# --- 3E. Correct data types ---
housing_clean <- housing_clean %>%
  mutate(
    city                 = as.factor(city),
    province             = as.factor(province),
    number_beds          = as.integer(number_beds),
    number_baths         = as.integer(number_baths),
    median_family_income = as.numeric(median_family_income)
  )

# --- 3F. Final verification ---
glimpse(housing_clean)
summary(housing_clean)
# 34,381 clean rows ready for analysis


# -----------------------------------------------------------------------------
# SECTION 4: FEATURE ENGINEERING (NEW VARIABLES)
# -----------------------------------------------------------------------------

housing_clean <- housing_clean %>%
  mutate(
    
    # Price tier segmentation
    price_category = case_when(
      price <  500000               ~ "Under $500K",
      price >= 500000 & price < 1e6 ~ "$500K - $1M",
      price >= 1e6                  ~ "Over $1M"
    ),
    price_category = factor(
      price_category,
      levels = c("Under $500K", "$500K - $1M", "Over $1M")
    ),
    
    # Price per bedroom — normalizes for property size
    price_per_bed = round(price / number_beds, 0),
    
    # Affordability ratio — years of median income needed to buy the home
    affordability_ratio = round(price / median_family_income, 2),
    
    # Total rooms proxy (beds + baths) — basic size indicator
    total_rooms = number_beds + number_baths
  )

# Preview new columns
housing_clean %>%
  select(city, price, price_category, price_per_bed,
         affordability_ratio, total_rooms) %>%
  head(10)


# -----------------------------------------------------------------------------
# SECTION 5: DESCRIPTIVE STATISTICS
# -----------------------------------------------------------------------------

# --- 5A. National summary ---
housing_clean %>%
  summarise(
    total_listings = n(),
    median_price   = median(price),
    mean_price     = round(mean(price), 0),
    sd_price       = round(sd(price), 0),
    min_price      = min(price),
    max_price      = max(price),
    pct_under_500k = round(mean(price < 500000) * 100, 1),
    pct_500k_1m    = round(mean(price >= 500000 & price < 1e6) * 100, 1),
    pct_over_1m    = round(mean(price >= 1e6) * 100, 1)
  )

# --- 5B. By province ---
province_stats <- housing_clean %>%
  group_by(province) %>%
  summarise(
    listings     = n(),
    median_price = median(price),
    mean_price   = round(mean(price), 0),
    min_price    = min(price),
    max_price    = max(price),
    pct_over_1m  = round(mean(price >= 1e6) * 100, 1)
  ) %>%
  arrange(desc(median_price))

print(province_stats)

# --- 5C. By city — cities with 50+ listings only ---
city_stats <- housing_clean %>%
  group_by(city, province) %>%
  summarise(
    listings     = n(),
    median_price = median(price),
    mean_price   = round(mean(price), 0),
    .groups      = "drop"
  ) %>%
  filter(listings >= 50) %>%
  arrange(desc(median_price))

print(city_stats, n = 20)

# --- 5D. Affordability ratio by city ---
affordability_stats <- housing_clean %>%
  group_by(city, province) %>%
  summarise(
    listings            = n(),
    median_price        = median(price),
    median_income       = first(median_family_income),
    affordability_ratio = round(median_price / median_income, 2),
    .groups             = "drop"
  ) %>%
  filter(listings >= 50) %>%
  arrange(desc(affordability_ratio))

print(affordability_stats, n = 20)

# --- 5E. Median price by bedroom count ---
beds_stats <- housing_clean %>%
  filter(number_beds <= 6) %>%
  group_by(number_beds) %>%
  summarise(
    listings     = n(),
    median_price = median(price),
    mean_price   = round(mean(price), 0)
  )

print(beds_stats)

# --- 5F. Price category distribution ---
housing_clean %>%
  count(price_category) %>%
  mutate(pct = round(n / sum(n) * 100, 1))


# -----------------------------------------------------------------------------
# SECTION 6: VISUALIZATIONS
# -----------------------------------------------------------------------------

# Consistent province color palette used across all charts
province_colors <- c(
  "British Columbia"          = "#0D3B66",
  "Ontario"                   = "#1A7DC4",
  "Alberta"                   = "#2E8B57",
  "Saskatchewan"              = "#D4A017",
  "Quebec"                    = "#8B2FC9",
  "New Brunswick"             = "#C75000",
  "Nova Scotia"               = "#0A9396",
  "Manitoba"                  = "#AE2012",
  "Newfoundland and Labrador" = "#606C38"
)

# Shared clean minimal theme
theme_housing <- theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15, color = "#1E293B"),
    plot.subtitle    = element_text(size = 11, color = "#475569",
                                    margin = margin(b = 10)),
    axis.title       = element_text(size = 11, color = "#64748B"),
    axis.text        = element_text(size = 10, color = "#64748B"),
    panel.grid.major = element_line(color = "#E2E8F0", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    legend.title     = element_text(face = "bold", color = "#1E293B"),
    legend.text      = element_text(color = "#475569"),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.caption     = element_text(size = 9, color = "#94A3B8",
                                    margin = margin(t = 10)),
    plot.margin      = margin(15, 20, 15, 15)
  )


# ---- VIZ 1: Median Listing Price by Province --------------------------------
# Research Q1: How do listing prices vary across Canadian provinces?

viz1 <- province_stats %>%
  mutate(province = fct_reorder(province, median_price)) %>%
  ggplot(aes(x = median_price, y = province, fill = province)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(
    aes(label = dollar(median_price, scale = 0.001, suffix = "K")),
    hjust    = -0.12,
    size     = 3.8,
    fontface = "bold",
    color    = "#1E293B"
  ) +
  scale_fill_manual(values = province_colors) +
  scale_x_continuous(
    labels = dollar_format(scale = 0.001, suffix = "K"),
    expand = expansion(mult = c(0, 0.18))
  ) +
  labs(
    title    = "Median Listing Price by Province",
    subtitle = "BC median ($950K) is 2.7x higher than Saskatchewan and New Brunswick ($350K) | As of October 29, 2023",
    x        = "Median Listing Price (CAD)",
    y        = NULL,
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023"
  ) +
  theme_housing

viz1

ggsave(
  "viz1_province_median_price.png",
  plot   = viz1,
  width  = 11,
  height = 6,
  dpi    = 300,
  bg     = "white"
)


# ---- VIZ 2: Top 15 Cities by Median Listing Price --------------------------
# Research Q2: Which cities are the most expensive?

viz2 <- city_stats %>%
  slice_max(median_price, n = 15) %>%
  mutate(city = fct_reorder(city, median_price)) %>%
  ggplot(aes(x = city, y = median_price, fill = province)) +
  geom_col(width = 0.68, show.legend = TRUE) +
  geom_text(
    aes(label = dollar(median_price, scale = 0.001, suffix = "K")),
    vjust    = -0.45,
    size     = 3.2,
    fontface = "bold",
    color    = "#1E293B"
  ) +
  scale_fill_manual(values = province_colors) +
  scale_y_continuous(
    labels = dollar_format(scale = 0.001, suffix = "K"),
    expand = expansion(mult = c(0, 0.13))
  ) +
  labs(
    title    = "Top 15 Canadian Cities by Median Listing Price",
    subtitle = "Only cities with 50+ listings | White Rock, BC leads at $1.638M median | As of October 29, 2023",
    x        = NULL,
    y        = "Median Listing Price (CAD)",
    fill     = "Province",
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023"
  ) +
  theme_housing +
  theme(axis.text.x = element_text(angle = 38, hjust = 1, size = 9.5))

viz2

ggsave(
  "viz2_top15_cities_price.png",
  plot   = viz2,
  width  = 13,
  height = 6.5,
  dpi    = 300,
  bg     = "white"
)


# ---- VIZ 3: Income vs. Price Scatter — City-Level Risk Map ------------------
# Research Q3: Do cities with higher incomes have proportionally higher prices?
# Cities ABOVE the regression line are overpriced relative to income — a key
# mortgage risk signal for banks and financial analysts.

city_scatter <- housing_clean %>%
  group_by(city, province) %>%
  summarise(
    listings      = n(),
    median_price  = median(price),
    median_income = first(median_family_income),
    .groups       = "drop"
  ) %>%
  filter(listings >= 50)

# Cities to label — the outliers that tell the most important story
cities_to_label <- c(
  "White Rock", "Vancouver", "Abbotsford", "Victoria",
  "Regina", "Saint John", "Edmonton", "Toronto", "Calgary"
)

viz3 <- city_scatter %>%
  ggplot(aes(x = median_income, y = median_price)) +
  # Regression band first (background layer)
  geom_smooth(
    method    = "lm",
    se        = TRUE,
    color     = "#E74C3C",
    fill      = "#FADBD8",
    linewidth = 1.2,
    alpha     = 0.25
  ) +
  # All city points
  geom_point(
    aes(color = province, size = listings),
    alpha = 0.85
  ) +
  # Labels for key outlier cities only
  geom_text(
    data     = city_scatter %>% filter(city %in% cities_to_label),
    aes(label = city),
    size     = 3.0,
    vjust    = -0.9,
    fontface = "bold",
    color    = "#1E293B"
  ) +
  # Annotate the "overpriced zone" above the line
  annotate(
    "text",
    x        = 108000,
    y        = 1550000,
    label    = "Overpriced relative\nto income",
    size     = 3.2,
    color    = "#C0392B",
    fontface = "italic",
    hjust    = 0
  ) +
  annotate(
    "text",
    x        = 108000,
    y        = 310000,
    label    = "Underpriced relative\nto income",
    size     = 3.2,
    color    = "#2E8B57",
    fontface = "italic",
    hjust    = 0
  ) +
  scale_color_manual(values = province_colors) +
  scale_size_continuous(range = c(3, 9), guide = "none") +
  scale_x_continuous(
    labels = dollar_format(),
    breaks = seq(60000, 140000, by = 20000)
  ) +
  scale_y_continuous(
    labels = dollar_format(scale = 0.001, suffix = "K"),
    breaks = seq(0, 1800000, by = 300000)
  ) +
  labs(
    title    = "Median Family Income vs. Median Listing Price by City",
    subtitle = "Cities above the red trend line are overpriced relative to local incomes — a key mortgage risk indicator | As of October 29, 2023",
    x        = "Median Family Income (CAD)",
    y        = "Median Listing Price (CAD)",
    color    = "Province",
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023 | Point size = number of listings"
  ) +
  theme_housing

viz3

ggsave(
  "viz3_income_vs_price_scatter.png",
  plot   = viz3,
  width  = 12,
  height = 7,
  dpi    = 300,
  bg     = "white"
)


# ---- VIZ 4: Housing Affordability Ratio ------------------------------------
# Research Q4: Which cities are the least affordable relative to family income?

viz4 <- affordability_stats %>%
  slice_max(affordability_ratio, n = 20) %>%
  mutate(city = fct_reorder(city, affordability_ratio)) %>%
  ggplot(aes(x = city, y = affordability_ratio, fill = province)) +
  geom_col(width = 0.68, show.legend = TRUE) +
  geom_hline(
    yintercept = 5,
    linetype   = "dashed",
    color      = "#E74C3C",
    linewidth  = 1.2
  ) +
  annotate(
    "text",
    x        = 2.8,
    y        = 5.7,
    label    = "Affordability Threshold (5x)",
    size     = 3.5,
    color    = "#E74C3C",
    hjust    = 0,
    fontface = "italic"
  ) +
  scale_fill_manual(values = province_colors) +
  scale_y_continuous(
    breaks = seq(0, 22, by = 2),
    expand = expansion(mult = c(0, 0.08))
  ) +
  labs(
    title    = "Housing Affordability Ratio: Top 20 Least Affordable Cities",
    subtitle = "Ratio = Median Listing Price / Median Family Income | Red dashed line = standard threshold of 5x | As of October 29, 2023",
    x        = NULL,
    y        = "Price-to-Income Ratio",
    fill     = "Province",
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023"
  ) +
  theme_housing +
  theme(axis.text.x = element_text(angle = 40, hjust = 1, size = 9))

viz4

ggsave(
  "viz4_affordability_ratio.png",
  plot   = viz4,
  width  = 14,
  height = 6.5,
  dpi    = 300,
  bg     = "white"
)


# ---- VIZ 5: Price Tier Composition by Province (100% Stacked Bar) ----------
# Shows the STRUCTURE of each provincial market — not just the median price.
# Which provinces are dominated by luxury listings vs. affordable stock?

viz5 <- housing_clean %>%
  group_by(province, price_category) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(province) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup() %>%
  # Order provinces by their share of Over $1M listings (most luxury at top)
  mutate(
    province = fct_reorder(
      province,
      pct * (price_category == "Over $1M"),
      .fun = sum
    )
  ) %>%
  ggplot(aes(x = province, y = pct, fill = price_category)) +
  geom_col(width = 0.70, position = "stack") +
  geom_text(
    aes(label = paste0(round(pct, 0), "%")),
    position = position_stack(vjust = 0.5),
    size     = 3.5,
    color    = "white",
    fontface = "bold"
  ) +
  scale_fill_manual(
    values = c(
      "Under $500K"  = "#AED6F1",
      "$500K - $1M"  = "#1A7DC4",
      "Over $1M"     = "#0D3B66"
    )
  ) +
  scale_y_continuous(
    labels = function(x) paste0(x, "%"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  coord_flip() +
  labs(
    title    = "Housing Market Composition by Province",
    subtitle = "What share of each provincial market falls under $500K, between $500K-$1M, or over $1M? | As of October 29, 2023",
    x        = NULL,
    y        = "Share of Listings (%)",
    fill     = "Price Tier",
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023"
  ) +
  theme_housing +
  theme(legend.position = "bottom")

viz5

ggsave(
  "viz5_price_tier_by_province.png",
  plot   = viz5,
  width  = 12,
  height = 6.5,
  dpi    = 300,
  bg     = "white"
)


# ---- VIZ 6: Most vs. Least Affordable Cities — Side-by-Side ----------------
# Tells the complete affordability story in a single chart.
# Top 5 most affordable vs. Top 5 least affordable cities — stark contrast.

most_affordable  <- affordability_stats %>%
  slice_min(affordability_ratio, n = 5) %>%
  mutate(group = "5 Most Affordable Cities")

least_affordable <- affordability_stats %>%
  slice_max(affordability_ratio, n = 5) %>%
  mutate(group = "5 Least Affordable Cities")

afford_compare <- bind_rows(most_affordable, least_affordable) %>%
  mutate(
    group = factor(group,
                   levels = c("5 Most Affordable Cities",
                              "5 Least Affordable Cities")),
    city  = fct_reorder(city, affordability_ratio)
  )

viz6 <- afford_compare %>%
  ggplot(aes(x = city, y = affordability_ratio, fill = group)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(
    aes(
      label = paste0(affordability_ratio, "x\n$",
                     round(median_price / 1000), "K")
    ),
    hjust    = -0.08,
    size     = 3.2,
    fontface = "bold",
    color    = "#1E293B"
  ) +
  geom_hline(
    yintercept = 5,
    linetype   = "dashed",
    color      = "#E74C3C",
    linewidth  = 1.0
  ) +
  coord_flip() +
  facet_wrap(
    ~ group,
    scales = "free_y",
    ncol   = 2
  ) +
  scale_fill_manual(
    values = c(
      "5 Most Affordable Cities"  = "#2E8B57",
      "5 Least Affordable Cities" = "#0D3B66"
    )
  ) +
  scale_x_discrete(expand = expansion(add = 0.6)) +
  scale_y_continuous(
    breaks = seq(0, 24, by = 4),
    expand = expansion(mult = c(0, 0.22))
  ) +
  labs(
    title    = "Canada's Most vs. Least Affordable Housing Markets",
    subtitle = "Price-to-Income Ratio | Red dashed line = 5x affordability threshold | Labels show ratio and median price | As of October 29, 2023",
    x        = NULL,
    y        = "Price-to-Income Ratio",
    caption  = "Source: HouseListings-Top45Cities.csv | Kaggle — Prices as of October 29, 2023"
  ) +
  theme_housing +
  theme(
    strip.text       = element_text(face = "bold", size = 12, color = "#1E293B"),
    strip.background = element_rect(fill = "#F1F5F9", color = NA),
    panel.spacing    = unit(1.5, "cm")
  )

viz6

ggsave(
  "viz6_most_vs_least_affordable.png",
  plot   = viz6,
  width  = 13,
  height = 6,
  dpi    = 300,
  bg     = "white"
)


# -----------------------------------------------------------------------------
# SECTION 7: KEY FINDINGS SUMMARY
# -----------------------------------------------------------------------------

cat("
=============================================================
  PROJECT 4C: KEY FINDINGS — CANADIAN HOUSING MARKET
=============================================================
 
1. PROVINCIAL DISPARITY
   BC has the highest median at $950K — 2.7x higher than
   Saskatchewan and New Brunswick (both ~$350K).
   Ontario ranks second at $774K.
 
2. MOST EXPENSIVE CITIES
   White Rock, BC leads at a $1,638,000 median.
   The top 5 most expensive cities are ALL in British Columbia.
   Toronto ($899K) is the only Ontario city in the top 10.
 
3. INCOME VS. PRICE RISK MAP
   There is only a moderate correlation between city income and price.
   BC cities (White Rock, Vancouver, Abbotsford) sit far above
   the regression line — overpriced relative to local incomes.
   Regina and Edmonton sit below the line — underpriced relative
   to income — signaling lower mortgage default risk for lenders.
 
4. MARKET COMPOSITION BY PROVINCE
   BC has the highest share of Over $1M listings (~50%).
   Saskatchewan and New Brunswick are dominated by Under $500K stock.
   Ontario is split: ~33% under $500K, ~33% mid-tier, ~33% over $1M.
 
5. AFFORDABILITY CRISIS — STARK CONTRAST
   Least affordable: White Rock (21x), Vancouver (13x), Abbotsford (12x).
   Most affordable: Regina (3.3x), Saint John (3.5x), Edmonton (3.6x).
   Every city in BC exceeds the 5x threshold. Prairie cities remain
   the only genuinely accessible markets in Canada.
 
FUTURE RESEARCH QUESTIONS:
   - How have prices trended year-over-year by province?
   - What is the impact of proximity to employment hubs on price?
   - Can income-to-price deviation predict mortgage default rates?
   - Are there seasonal patterns in listing volume by city?
=============================================================
")