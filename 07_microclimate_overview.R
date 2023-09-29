# set system locale to english for data handling
Sys.setlocale("LC_ALL", "English")
######################################################
################LOAD TEMPERATURE DATA#################
######################################################
load(here::here("data", "temperature", "oref_temperatures_2019_2023.RData"))
load(here::here("data", "temperature", "temperatures_WS2022.RData"))

######################################################
################DAYS COVERAGE COUNT###################
######################################################
# estimates how many days the temperature data covers
# air
air_distribution <- oref_temperatures %>%
  filter(position == "A") %>%
  count(plot)   %>%
  mutate(n_day = n / 24) %>%
  mutate_at(3, round, 0) %>%
  mutate(pos = "Air")
# soil
soil_distribution <- oref_temperatures %>%
  filter(position == "S") %>%
  count(plot)   %>%
  mutate(n_day = n / 24) %>%
  mutate_at(3, round, 0) %>%
  mutate(pos = "Soil")
#merge
distribution <- rbind(air_distribution, soil_distribution)


# different approaches to achieve the exact samething (deprecated)
# temp_leafon <- oref_temperatures %>% ymd_hms(oref_temperatures$datetime >= "2022-04-01 00:00:00", 
#                                              oref_temperatures$datetime <= "2022-10-31 23:00:00")
# str(oref_temperatures)
# oref_temperatures$datetime <- as.POSIXct(oref_temperatures$datetime, tz = "UTC")
# class(oref_temperatures$datetime)

# library(tibbletime)
# oref_temperatures <- as_tbl_time(oref_temperatures, index = datetime)
# filter_time(oref_temperatures, time_formula = '2022-04-01' ~ '2022-10-31')

######################################################
################ SLOPE AND EQUILIBRIUM ###############
######################################################
# CHECK DAYS COVERAGE OF INDIVIDUAL PLOTS
air_distribution <- oref_temperatures %>%
  filter(position == "A") %>%
  filter(datetime >= as.POSIXct("2022-05-01 00:00:00 UTC", tz ="UTC"), 
         datetime <= as.POSIXct("2022-09-30 23:00:00 UTC", tz ="UTC")) %>%
  count(plot)   %>%
  mutate(n_day = n / 24) %>%
  mutate_at(3, round, 0) %>%
  mutate(pos = "Air")

# OREF FIELD AIR TEMPERATURES 
leafon_air <- oref_temperatures %>% 
  filter(position == "A") %>% # keep air temps
  filter(datetime >= as.POSIXct("2022-05-01 00:00:00 UTC", tz ="UTC"), 
         datetime <= as.POSIXct("2022-09-30 23:00:00 UTC", tz ="UTC")) %>% # between april and oct
  filter(plot != "240") %>% # remove 240 bc it has no full coverage
  droplevels() # drop unused levels

# WEATHER STATION TEMPERATURES
leafon_ws <- temperatures_WS2022 %>% 
  filter(datetime >= as.POSIXct("2022-05-01 00:00:00 UTC", tz ="UTC"), 
         datetime <= as.POSIXct("2022-09-30 23:00:00 UTC", tz ="UTC")) %>% # same timefrime
  add_row(datetime = as.POSIXct("2022-08-29 12:00:00 UTC", tz ="UTC"),
          T_WS = 21.07) # fill missing data entry
# LEFT JOIN
leafon_air_combined <- left_join(leafon_air, leafon_ws, by = join_by(datetime == datetime))

# ID LIST AND RESULT LIST FOR FOR LOOP
plots_id <- levels(leafon_air_combined$plot)
coef_mod_on <- list()

# FOR LOOP
for (i in plots_id) {
  temperatures_i <- na.omit(leafon_air_combined) %>% # omit NA and filter current plot
    filter(plot==i)
  
  mod <- lm(temperature ~ T_WS, # linear model between field temp and T ws
            data=temperatures_i, na.action = na.omit)
  # Then the equilibrium per month AND slope (constant):
  coef_mod_on[[i]] <-
    data.frame(as.list(coef(mod))) %>%    # to get both coefficients
    as_tibble() %>%
    dplyr::rename(intercept = 1,
                  slope = "T_WS") %>% 
    mutate(equilibrium=intercept/(1-slope),
           plot=as.factor(i),
           r_squared=summary(mod)$r.squared)
}

coef_mod_on <- bind_rows(coef_mod_on) %>%
  distinct()
slopes_lidar <- coef_mod_on %>% 
  select(plot, slope, equilibrium, r_squared) %>% 
  arrange(plot) 
rm(i,temperatures_i, coef_mod_on) # remove superfluous stuff from enviro

######################################################
############################ PLOTS ###################
######################################################
# plot amount of days covered by air and soil temperature measurements
d <- distribution %>%
  ggplot() +
  geom_bar(aes(x = plot, y = n_day, fill = pos, group = pos),
  stat = "identity",
  position = "dodge") +
  geom_text(aes(x = plot, y = n_day, label = n_day, group = pos, color = "white"),
    hjust = 1.5,
    vjust = 0.5,
    size = 3,
    position = position_dodge(width = 1),
    inherit.aes = TRUE ) +
  xlab("Plot Designation") + ylab("N Observations") +
  theme_minimal() +
  scale_fill_manual(values = c("#9dc6e0", "#4b8c79")) +
  scale_colour_manual(values = "white",
                      guide = "none") +
  theme(legend.position = "bottom",
        legend.title = element_blank(),
        strip.text = element_text(size = 9, hjust = 0.5),
        strip.background = element_rect(fill = "white", color = "white", linewidth = 1) ) +
  coord_flip()

# plot soil temperatures timeseries for all plots to compare coverage
s <- oref_temperatures %>%
  ggplot() +
  geom_line(
    aes(x = datetime, y = temperature, color = "HOBO Soil"),
    data = filter(oref_temperatures, position %in% "S")) +
  # geom_line(aes(x=datetime, y=temperature, color ="HOBO Air"),
  #           data = filter(oref_temperatures, position %in% "A"),
  # alpha=0.6) +
  scale_color_manual(values = c("#4b8c79"), name = "") +
  xlab("") + 
  ylab("Soil Temperature (°C)") +
  facet_wrap(vars(plot), ncol = 2) +
  theme_classic() +
  ggtitle("Soil Temperatures") +
  guides(alpha = F) +
  theme(legend.position = "bottom",
        strip.text = element_text(size = 9, hjust = 0.5),
        strip.background = element_rect(fill = "white", colour = "white", linewidth = 1))

# plot air temperatures timeseries for all plots to compare coverage
a <- oref_temperatures %>%
  ggplot() +
  # geom_line(aes(x=datetime, y=temperature, color ="HOBO Soil"),
  #           data = filter(oref_temperatures, position %in% "S")) +
  geom_line(
    aes(x = datetime, y = temperature, color = "HOBO Air"),
    data = filter(oref_temperatures, position %in% "A")
    ) +
  scale_color_manual(values = c("#9dc6e0"),
                     name = "") +
  xlab("") + ylab("Air Temperature (°C)") +
  facet_wrap(vars(plot), ncol = 2) +
  theme_classic() +
  ggtitle("1m Air Temperatures") +
  guides(alpha = F) +
  theme(legend.position = "bottom",
        strip.text = element_text(size = 9, hjust = 0.5),
        strip.background = element_rect(fill = "white", color = "white", linewidth = 1)
        )

# plot air temperatures timeseries for all plots against weather station reference time series
g <- leafon_air_combined %>%
  ggplot() +
  geom_line(aes(x=datetime, y=T_WS, color ="Weather station")) +
  geom_line(aes(x=datetime, y=temperature, color ="HOBO in the forest"), alpha=0.6) +
  scale_color_manual(values=c("#4b8c79", "#9dc6e0"),
                     name = "Measurements with:") +
  xlab("") + ylab("Temperature (°C)") +
  facet_wrap(vars(plot), ncol = 2) +
  theme_classic() +
  ggtitle("Temperatures: HOBOs vs. Weather stations") +
  guides(alpha=F) +
  theme(legend.position="bottom",
        strip.text = element_text(size=9, hjust=0.5),
        strip.background = element_rect(fill="white", colour="white",linewidth = 1))


# display plots
ggplotly(d)
ggplotly(s)
ggplotly(a)
ggplotly(g)

# plot coverages as boxplot (deprecated for now)
# oref_temperatures %>%
#   ggplot() +
#   geom_boxplot(aes(x = temperature, y = plot, color = plot), 
#                data = filter(oref_temperatures, position %in% "A")) +
#   labs(x = "Hourly standard deviation in each forest (°C)", y = "", title = "") +
#   guides(color = "none") +
#   scale_color_viridis_d(option = "magma", end = 0.95) +
#   theme_classic()