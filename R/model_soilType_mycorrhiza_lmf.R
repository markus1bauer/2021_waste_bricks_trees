# Model for experiment mycorrhiza and soil type and leaf mass fraction ####
# Markus Bauer
# Citation: Markus Bauer, Martin Krause, Valentin Heizinger & Johannes Kollmann  (2021) ...
# DOI: ...



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# A Preparation ################################################################################################################
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

### Packages ###
library(tidyverse)
library(ggbeeswarm)
library(lmerTest)
library(DHARMa)
library(emmeans)

### Start ###
rm(list = ls())
setwd("Z:/Documents/0_Ziegelprojekt/3_Aufnahmen_und_Ergebnisse/2020_waste_bricks_trees/data/processed")

### Load data ###
data <- read_csv2("data_processed_brickRatio.csv", col_names = T, na = "na", col_types = 
                        cols(
                          .default = col_double(),
                          plot = col_factor(),
                          block = col_factor(),
                          replanted = col_factor(),
                          species = col_factor(),
                          mycorrhiza = col_factor(levels = c("Control","Mycorrhiza")),
                          substrate = col_factor(),
                          soilType = col_factor(levels = c("poor","rich")),
                          brickRatio = col_factor(levels = c("5","30")),
                          acid = col_factor(levels = c("Acid")),
                          acidbrickRatioTreat = col_factor()
                        )        
)
(data <- select(data, lmf, plot, block, replanted, species, brickRatio, soilType, mycorrhiza))


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# B Statistics ################################################################################################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


### 1 Data exploration #####################################################################################

#### a Graphs ---------------------------------------------------------------------------------------------
#simple effects:
par(mfrow = c(2,2))
plot(lmf ~ species, data)
plot(lmf ~ brickRatio, data)
plot(lmf ~ soilType, data)
plot(lmf ~ mycorrhiza, data)
par(mfrow = c(2,2))
plot(lmf ~ block, data)
#2way (brickRatio:species):
ggplot(data, aes(species, lmf, color = brickRatio)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#2way (brickRatio:soilType):
ggplot(data, aes(soilType, lmf, color = brickRatio)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#2way (brickRatio:mycorrhiza):
ggplot(data, aes(mycorrhiza, lmf, color = brickRatio)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#2way (species:soilType):
ggplot(data, aes(species, lmf, color = soilType)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#2way (species:mycorrhiza):
ggplot(data, aes(species, lmf, color = mycorrhiza)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#2way (soilType:mycorrhiza):
ggplot(data, aes(soilType, lmf, color = mycorrhiza)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#3way (brickRatio:species:soilType):
ggplot(data, aes(soilType, lmf, color = brickRatio)) + facet_grid(~species) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#3way (brickRatio:species:mycorrhiza):
ggplot(data, aes(mycorrhiza, lmf, color = brickRatio)) + facet_grid(~species) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#3way (species:soilType:mycorrhiza):
ggplot(data, aes(soilType, lmf, color = mycorrhiza)) + facet_grid(~species) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
#4way
ggplot(data,aes(soilType, lmf, color = brickRatio, shape = mycorrhiza)) + facet_grid(~species) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
# interactions with block:
ggplot(data,aes(brickRatio, lmf, color = species)) + geom_boxplot() + facet_wrap(~block) + geom_quasirandom(dodge.width = .7)
ggplot(data,aes(block, lmf, color = species)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
ggplot(data,aes(block, lmf, color = brickRatio)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
ggplot(data,aes(block, lmf, color = soilType)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)
ggplot(data,aes(block, lmf, color = mycorrhiza)) + geom_boxplot() + geom_quasirandom(dodge.width = .7)

##### b Outliers, zero-inflation, transformations? -----------------------------------------------------
par(mfrow = c(2,2))
dotchart((data$lmf), groups = factor(data$species), main = "Cleveland dotplot")
dotchart((data$lmf), groups = factor(data$brickRatio), main = "Cleveland dotplot")
dotchart((data$lmf), groups = factor(data$soilType), main = "Cleveland dotplot")
dotchart((data$lmf), groups = factor(data$mycorrhiza), main = "Cleveland dotplot")
dotchart((data$lmf), groups = factor(data$block), main = "Cleveland dotplot")
par(mfrow=c(1,1));
boxplot(data$lmf);#identify(rep(1,length(data$lmf)),data$lmf, labels = c(data$no))
plot(table((data$lmf)), type = "h", xlab = "Observed values", ylab = "Frequency")
ggplot(data, aes(lmf)) + geom_density()
ggplot(data, aes(log(lmf))) + geom_density()


## 2 Model building ################################################################################

#### a models ----------------------------------------------------------------------------------------
#random structure --> no random effect needed
m1 <- lmer(lmf ~ species * brickRatio + (1|block), data, REML = F)
VarCorr(m1)
#4w-model
m2 <- lmer(log(lmf) ~ species * brickRatio * soilType * mycorrhiza + 
             (1|block), data, REML = F)
simulateResiduals(m2, plot = T)
#full 3w-model
m3 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza)^3 + 
           (1|block), data, REML = F)
simulateResiduals(m3, plot = T)
#3w-model reduced
m4 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza)^2 +
           species:brickRatio:soilType + species:brickRatio:mycorrhiza + 
           (1|block), data, REML = F)
simulateResiduals(m4, plot = T)
#2w-model full
m5 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza)^2 + 
             (1|block), data, REML = F)
simulateResiduals(m5, plot = T)
#2w-model reduces
m6 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza) +
             species:brickRatio + species:soilType + species:mycorrhiza + 
             (1|block), data, REML = F)
simulateResiduals(m6, plot = T);
#1w-model full
m7 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza) + 
             (1|block), data, REML = F)
simulateResiduals(m7, plot = T);

#### b comparison -----------------------------------------------------------------------------------------
anova(m2,m3,m4,m5,m6,m7) # --> m7 BUT use m4 because of 3-fold interactions are of interest
rm(m1,m2,m3,m5,m6,m7)

#### c model check -----------------------------------------------------------------------------------------
simulationOutput <- simulateResiduals(m4, plot = T)
par(mfrow=c(2,2));
plotResiduals(main = "species", simulationOutput$scaledResiduals, data$species)
plotResiduals(main = "brickRatio", simulationOutput$scaledResiduals, data$brickRatio)
plotResiduals(main = "soilType", simulationOutput$scaledResiduals, data$soilType)
plotResiduals(main = "mycorrhiza", simulationOutput$scaledResiduals, data$mycorrhiza)
plotResiduals(main = "block", simulationOutput$scaledResiduals, data$block)


## 3 Chosen model output ################################################################################

### Model output ---------------------------------------------------------------------------------------------
m4 <- lmer(log(lmf) ~ (species + brickRatio + soilType + mycorrhiza)^2 +
             species:brickRatio:soilType + species:brickRatio:mycorrhiza +
             (1|block), data, REML = F)
MuMIn::r.squaredGLMM(m4) #R2m = 0.654, R2c = 0.654
VarCorr(m4)
sjPlot::plot_model(m4, type = "re", show.values = T)
car::Anova(m4, type = 3)

### Effect sizes -----------------------------------------------------------------------------------------
(emm <- emmeans(m4, revpairwise ~ brickRatio * soilType | species, type = "response"))
plot(emm, comparison = T)
contrast(emmeans(m4, ~ brickRatio * soilType | species, type = "response"), "trt.vs.ctrl", ref = 1)
(emm <- emmeans(m4, revpairwise ~ brickRatio | mycorrhiza | species, type = "response"))
plot(emm, comparison = T)
contrast(emmeans(m4, ~ brickRatio * mycorrhiza | species, type = "response"), "trt.vs.ctrl", ref = 1)
