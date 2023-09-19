library(tidyverse) # load and manipulate data
library(plotly)

Sys.setlocale("LC_ALL", "English")
load(here::here("data", "temperature", "oref_temperatures_2019_2023.RData"))

air_distribution <- oref_temperatures %>%
  filter(position == "A") %>%
  count(plot)   %>%
  mutate(n_day = n / 24) %>%
  mutate_at(3, round, 0) %>%
  mutate(pos = "Air")
soil_distribution <- oref_temperatures %>%
  filter(position == "S") %>%
  count(plot)   %>%
  mutate(n_day = n / 24) %>%
  mutate_at(3, round, 0) %>%
  mutate(pos = "Soil")
distribution <- rbind(air_distribution, soil_distribution)

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
        strip.background = element_rect(fill = "white", color = "white", size = 1) ) +
  coord_flip()

a <- oref_temperatures %>%
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
        strip.background = element_rect(fill = "white", colour = "white", size = 1))

s <- oref_temperatures %>%
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
        strip.background = element_rect(fill = "white", color = "white", size = 1)
        )

ggplotly(d)
ggplotly(s)
ggplotly(a)

oref_temperatures %>%
  ggplot() +
  geom_boxplot(aes(x = temperature, y = plot, color = plot), 
               data = filter(oref_temperatures, position %in% "A")) +
  labs(x = "Hourly standard deviation in each forest (°C)", y = "", title = "") +
  guides(color = "none") +
  scale_color_viridis_d(option = "magma", end = 0.95) +
  theme_classic()