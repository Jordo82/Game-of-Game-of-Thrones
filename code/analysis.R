library(tidyverse)
library(ggthemes)
library(ggrepel)
library(magick)
library(grid)


#grab just the column names
cn <- read_csv("csv/GoT_tournament_excel.csv") %>% 
  colnames() %>% 
  enframe() %>% 
  filter(substr(value, 1, 1) != "X") %>% 
  mutate(IsCharacter = (value != "Entry" & substr(value, 1, 5) != "Bonus")) %>% 
  left_join({
    tibble(Status = c("Dead", "Episode", "Wight"),
           IsCharacter = TRUE)
  }) %>% 
  mutate(colname = ifelse(IsCharacter, paste(value, Status, sep = "_"), value))

#now skip the headers and assign our own column names
entries <- read_csv("csv/GoT_tournament_excel.csv", skip = 2, col_names = cn$colname) %>% 
  mutate_at(vars(contains("Episode")), as.numeric) %>% 
  mutate_at(vars(contains("Dead")), ~.=="Yes") %>% 
  mutate_at(vars(contains("Wight")), ~.=="Yes") %>% 
  mutate_at(vars(contains("Dragon")), ~.=="Yes") %>% 
  mutate_at(vars(contains("Pregs")), ~.=="Yes") %>% 
  mutate_at(vars(contains("bowl")), ~.=="Yes")


#create a separate df just for character related questions
char <- entries %>% 
  select(-contains("Bonus")) %>% 
  gather(-Entry, key = Character_Status, value = value) %>% 
  separate(Character_Status, c("Character", "Status"), sep = "_") %>% 
  spread(key = Status, value = value) %>% 
  mutate(Dead = Dead == 1,
         Wight = Wight == 1,
         Wight = replace(Wight, !Dead, NA))



#summary metrics related to characters
# CharMet <- char %>%
#   mutate(IsStark = str_detect(Character, "Stark"),
#          IsLannister = str_detect(Character, "Lannister")) %>%
#   group_by(Entry) %>%
#   summarise(DeathRate = mean(Dead),
#             EpMean = mean(Episode, na.rm = TRUE),
#             EpVar = sd(Episode, na.rm = TRUE),
#             WightRate = mean(Wight, na.rm = TRUE),
#             Starks = sum(!Dead[IsStark]),
#             Lannisters = sum(!Dead[IsLannister]))

scale_this <- function(x){
  (x - mean(x, na.rm=TRUE)) / sd(x, na.rm=TRUE)
}

#scale & center the metrics
#what if we just look at who's living/dead?
cdata <- char %>% 
  select(-Episode, -Wight) %>% 
  spread(Character, Dead) %>% 
  mutate_at(vars(-one_of("Entry")), scale_this)
rownames(cdata) <- cdata$Entry
cdata <- cdata[,-c(1, 7)]

#principal components
pc <- princomp(cdata)

#clusters
set.seed(20190412)
km<-kmeans(cdata, centers=4)



#what is the death rate per cluster by character?  
#What makes each cluster distinct in terms of who they think will live and die?
Surprises <- char %>% 
  select(-Episode, -Wight) %>% 
  spread(Character, Dead) %>%  
  mutate(cluster = paste0("Cluster", km$cluster)) %>% 
  gather(-Entry, -cluster, key = Character, value = Dead) %>% 
  group_by(cluster, Character) %>% 
  summarise(DeathRate = mean(Dead), 
            Size = n()) %>% 
  group_by(Character) %>% 
  mutate(AvgDR = sum(DeathRate * Size) / sum(Size)) %>% 
  group_by(cluster) %>% 
  mutate(diff = DeathRate - AvgDR,
         rank = rank(-diff, ties.method = "first")) %>%
  filter(rank %in% c(1:3, 22:24)) %>% 
  select(cluster, Character, rank, DeathRate) %>% 
  arrange(cluster, rank) %>% 
  select(cluster, rank, Character) %>%
  spread(cluster, Character) %>% 
  select(-rank)



#plot entries by first two princomp and color by cluster
entries %>% 
  arrange(Entry) %>% 
  mutate(cluster = km$cluster,
         pc1 = pc$scores[, 1],
         pc2 = pc$scores[, 2],
         Name = str_replace(Entry, " ", "\n")) %>% 
  ggplot(aes(pc1, pc2)) + 
  geom_label_repel(aes(label = Name, fill = factor(cluster)), force = 0.1,
                   color = "white", segment.color = "black", size = 3, fontface = "bold") + 
  theme_fivethirtyeight() + 
  theme(axis.text = element_blank(),
        legend.position = "none") + 
  scale_y_continuous(breaks = seq(-10, 10, 10)) +
  scale_x_continuous(breaks = seq(-10, 10, 10)) + 
  labs(title = "Game of Game of Thrones",
       subtitle = "How similar were the picks of who will live and who die?\nColors indicate 'clusters' of individuals with similar picks.")
ggsave("plots/Pick Similarity.png", width = 11, height = 8, dpi = 300)

#read in the images of all characters in Surprises
for(i in seq_len(nrow(Surprises))){
  for(j in seq_along(Surprises)){
    assign(paste0("img", i, j), image_scale(image_read(paste0("pics/", Surprises[i,j], ".png")), "300x300"))
  }
}

#create composites for live/die for each cluster
for(k in c("die", "live")){
  for(j in 1:4){
    eval(parse(text = paste0(k, j, " <- image_append(c(img", 3*(k == "live") + 1, j, ", img",
                             3*(k == "live") + 2, j, ", img", 3*(k == "live") + 3, j,
                             "), stack = TRUE)")))
  }
}

#plot a grid of the distinctive characters in each cluster
tibble(xmin = -2:1, xmax = -1:2, ymin = rep(-3, 4), ymax = rep(3, 4), cluster = factor(1:4)) %>% 
  ggplot()+
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = cluster))+
  theme_fivethirtyeight() +
  theme(panel.grid = element_blank(),
        axis.text = element_blank(),
        legend.position = "none") + 
  annotate("rect", xmin = -2, xmax = 2, ymin = 0, ymax = 3, fill = "black", alpha = 0.2)+
  annotate("rect", xmin = -2, xmax = 2, ymin = -3, ymax = 0, fill = "white", alpha = 0.2)+
  annotation_raster(die1, -1.9,-1.1,0.1,2.9) + 
  annotation_raster(die2, -.9,-.1,0.1,2.9) + 
  annotation_raster(die3, 0.1,0.9,0.1,2.9) + 
  annotation_raster(die4, 1.1,1.9,0.1,2.9) + 
  annotation_raster(live1, -1.9,-1.1,-2.9,-0.1) + 
  annotation_raster(live2, -.9,-.1,-2.9,-.1) + 
  annotation_raster(live3, 0.1,0.9,-2.9,-.1) + 
  annotation_raster(live4, 1.1,1.9,-2.9,-.1) + 
  labs(title = "What makes the clusters distinctive?",
       subtitle = "The top 3 most distinctive choices to live and die in each cluster") + 
  geom_label(data = tibble(x = seq(-1.5, 1.5, 1), y = rep(3, 4), cluster = factor(1:4)),
             aes(x, y, label = paste0("Cluster ", 1:4), fill = cluster), 
             fontface = "bold", color = "white") + 
  geom_text(data = tibble(x = rep(-2.1, 2), y = c(-1.5, 1.5)),
            aes(x, y, label = c("Alive", "Dead")), fontface = "bold", angle = 90, size = 10)
ggsave("plots/Cluster Distinctiveness.png", height = 8, width = 6, dpi = 300)




#Overall odds to live/die
char %>% 
  group_by(Character) %>% 
  summarise(DeathRate = sum(Dead) / n()) %>%
  ggplot(aes(x = fct_reorder(Character, DeathRate), y = DeathRate)) + 
  geom_bar(stat = "identity") + 
  geom_text(aes(y = 0.01, label = Character), color = "white", fontface = "bold", hjust = 0, size = 2.0)+
  coord_flip() + 
  theme_fivethirtyeight() + 
  scale_y_continuous(labels = scales::percent) + 
  theme(panel.grid.major.y = element_blank(),
        axis.title = element_text(face = "bold"),
        axis.title.y = element_blank(),
        axis.text.y = element_blank()) + 
  labs(title = "Cersei's in trouble...",
       subtitle = "%of people who guessed the character would die",
       x = "Death  Rate")
ggsave("plots/Death Rate.png", width = 6, height = 4, dpi = 600)
