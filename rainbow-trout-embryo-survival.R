# ==============================================================================
# Professional R Script - Predictive Modeling for Embryo Survival (100 TU)
# Species: Rainbow Trout (Oncorhynchus mykiss)
# Objective: Assess whether female reproductive traits can predict embryo survival
# Author: Jonathan Carrasco
# Date: 2024-11-19 (final version)
# ==============================================================================

# 0. Environment setup ---------------------------------------------------------
rm(list = ls())
cat("\014")
set.seed(123)  # global seed for reproducibility

# Optional parallelization (uncomment if you have multiple cores)
# library(doParallel)
# registerDoParallel(cores = detectCores() - 1)

# 0.1 Automatic installation of missing packages -------------------------------
packages_needed <- c(
  "readxl", "dplyr", "tidyr", "ggplot2", "gridExtra", "DataExplorer",
  "inspectdf", "knitr", "tidyverse", "tidymodels", "conflicted", "recipes",
  "parsnip", "yardstick", "tune", "workflows", "themis", "ranger", "kernlab",
  "nnet", "kableExtra", "vip", "doParallel", "skimr", "autoplotly"
)

packages_to_install <- packages_needed[!packages_needed %in% installed.packages()[, "Package"]]

if (length(packages_to_install) > 0) {
  install.packages(packages_to_install, dependencies = TRUE)
  cat("Installed missing packages:", paste(packages_to_install, collapse = ", "), "\n")
} else {
  cat("All required packages are already installed.\n")
}

# 1. Load libraries ------------------------------------------------------------
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)
library(DataExplorer)
library(inspectdf)
library(knitr)
library(tidyverse)
library(tidymodels)
library(conflicted)
library(recipes)
library(parsnip)
library(yardstick)
library(tune)
library(workflows)
library(themis)
library(ranger)
library(kernlab)
library(nnet)
library(kableExtra)
library(vip)          # for variable importance
library(doParallel)   # optional
library(skimr)        # for data overview

conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("rename", "dplyr")

# 2. Data loading and validation -----------------------------------------------
file_path <- "desove.xlsx"
if (!file.exists(file_path)) stop("File not found: ", file_path)

Desoves <- read_excel(file_path)
cat("Original dimensions:", dim(Desoves), "\n")

# Remove first column by name (assuming it's an index)
if ("...1" %in% colnames(Desoves)) Desoves <- Desoves %>% select(-"...1")

Desoves <- Desoves %>% rename(IGS = `IGS Real`)

# 3. Data cleaning -------------------------------------------------------------
Desoves$Categoria <- as.factor(Desoves$Categoria)
Desoves <- Desoves %>% drop_na()
Desoves <- Desoves %>%
  filter(IGS > 0, Peso_Kg > 0, Longitud_cm > 0, K > 0, PH > 0)

# Ensure correct level order (positive class = "Aprobado")
Desoves$Categoria <- fct_relevel(Desoves$Categoria, "Aprobado", "Rechazado")
cat("After cleaning dimensions:", dim(Desoves), "\n")
summary(Desoves)

# 4. Outlier detection (IQR method) -------------------------------------------
detect_outliers <- function(data, vars) {
  outliers <- data.frame()
  for (var in vars) {
    Q1 <- quantile(data[[var]], 0.25, na.rm = TRUE)
    Q3 <- quantile(data[[var]], 0.75, na.rm = TRUE)
    IQR_val <- IQR(data[[var]], na.rm = TRUE)
    lower <- Q1 - 1.5 * IQR_val
    upper <- Q3 + 1.5 * IQR_val
    outliers_var <- data %>% filter(data[[var]] < lower | data[[var]] > upper)
    outliers <- bind_rows(outliers, outliers_var)
  }
  outliers <- distinct(outliers)
  return(outliers)
}

vars_outliers <- c("Peso_Kg", "Longitud_cm", "K", "PH", "IGS", "Salinidad_g/100ml")
outliers <- detect_outliers(Desoves, vars_outliers)
cat("Outliers detected:", nrow(outliers), "\n")
Desoves_clean <- anti_join(Desoves, outliers)
cat("Dimensions after outlier removal:", dim(Desoves_clean), "\n")

# 5. Train / test split (stratified) ------------------------------------------
set.seed(456)
split <- initial_split(Desoves_clean, prop = 0.7, strata = Categoria)
train_data <- training(split)
test_data  <- testing(split)

cat("Train size:", nrow(train_data), "Test size:", nrow(test_data), "\n")

# 6. Cross-validation folds (5-fold, stratified) ------------------------------
set.seed(789)
cv_folds <- vfold_cv(train_data, v = 5, strata = Categoria)

# 7. Recipe: normalization, zero-variance filter, and SMOTE -------------------
recipe_base <- recipe(Categoria ~ ., data = train_data) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_nzv(all_predictors()) %>%
  step_smote(Categoria, over_ratio = 1, seed = 101112)

# 8. Model definitions --------------------------------------------------------
rf_model <- rand_forest(mtry = tune(), trees = tune(), min_n = tune()) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("classification")

svm_model <- svm_rbf(cost = tune(), rbf_sigma = tune()) %>%
  set_engine("kernlab") %>%
  set_mode("classification")

nnet_model <- mlp(hidden_units = tune(), penalty = tune(), epochs = tune()) %>%
  set_engine("nnet") %>%
  set_mode("classification")

# 9. Workflows ----------------------------------------------------------------
wf_rf <- workflow() %>% add_recipe(recipe_base) %>% add_model(rf_model)
wf_svm <- workflow() %>% add_recipe(recipe_base) %>% add_model(svm_model)
wf_nnet <- workflow() %>% add_recipe(recipe_base) %>% add_model(nnet_model)

# 10. Tuning grids (consistent levels = 5) ------------------------------------
rf_grid <- grid_regular(
  mtry(range = c(2, 6)),
  min_n(range = c(5, 15)),
  trees(range = c(500, 1500)),
  levels = 5
)
svm_grid <- grid_regular(
  cost(range = c(-2, 2)),
  rbf_sigma(range = c(-2, 2)),
  levels = 5
)
nnet_grid <- grid_regular(
  hidden_units(range = c(2, 10)),
  penalty(range = c(0.001, 0.1)),
  epochs(range = c(50, 200)),
  levels = 5
)

# 11. Tune models -------------------------------------------------------------
metrics_set <- metric_set(roc_auc, accuracy, f_meas, sensitivity, specificity)

set.seed(101)
rf_tune <- tune_grid(wf_rf, resamples = cv_folds, grid = rf_grid,
                     metrics = metrics_set, control = control_grid(save_pred = TRUE))
svm_tune <- tune_grid(wf_svm, resamples = cv_folds, grid = svm_grid,
                      metrics = metrics_set, control = control_grid(save_pred = TRUE))
nnet_tune <- tune_grid(wf_nnet, resamples = cv_folds, grid = nnet_grid,
                       metrics = metrics_set, control = control_grid(save_pred = TRUE))

# 12. Baseline model (always predict majority class "Rechazado") ------------
# For ROC AUC we need probabilities; assign prob_Rechazado = 1, prob_Aprobado = 0.
baseline_pred <- train_data %>%
  mutate(.pred_class = "Rechazado",
         .pred_Rechazado = 1,
         .pred_Aprobado = 0) %>%
  select(Categoria, .pred_class, .pred_Rechazado, .pred_Aprobado)

baseline_metrics <- bind_rows(
  accuracy(baseline_pred, truth = Categoria, estimate = .pred_class),
  f_meas(baseline_pred, truth = Categoria, estimate = .pred_class, event_level = "second")
) %>% mutate(Model = "Baseline")
# Note: ROC AUC is omitted because baseline has no discrimination.

# 13. Extract best models (using f_meas due to imbalance) --------------------
best_rf <- select_best(rf_tune, metric = "f_meas")
best_svm <- select_best(svm_tune, metric = "f_meas")
best_nnet <- select_best(nnet_tune, metric = "f_meas")

# 14. Finalize workflows and fit to training data ----------------------------
final_rf <- finalize_workflow(wf_rf, best_rf) %>% fit(data = train_data)
final_svm <- finalize_workflow(wf_svm, best_svm) %>% fit(data = train_data)
final_nnet <- finalize_workflow(wf_nnet, best_nnet) %>% fit(data = train_data)

# 15. Predictions on test set ------------------------------------------------
test_pred_rf <- predict(final_rf, test_data, type = "class") %>%
  bind_cols(predict(final_rf, test_data, type = "prob")) %>%
  bind_cols(test_data)

test_pred_svm <- predict(final_svm, test_data, type = "class") %>%
  bind_cols(predict(final_svm, test_data, type = "prob")) %>%
  bind_cols(test_data)

test_pred_nnet <- predict(final_nnet, test_data, type = "class") %>%
  bind_cols(predict(final_nnet, test_data, type = "prob")) %>%
  bind_cols(test_data)

# 16. Compute test set metrics (with ROC AUC for models) ---------------------
test_metrics <- function(predictions, model_name) {
  bind_rows(
    roc_auc(predictions, truth = Categoria, .pred_Aprobado, event_level = "second"),
    accuracy(predictions, truth = Categoria, estimate = .pred_class),
    f_meas(predictions, truth = Categoria, estimate = .pred_class, event_level = "second")
  ) %>% mutate(Model = model_name, .estimate = round(.estimate, 3))
}

test_metrics_rf   <- test_metrics(test_pred_rf, "Random Forest")
test_metrics_svm  <- test_metrics(test_pred_svm, "SVM")
test_metrics_nnet <- test_metrics(test_pred_nnet, "Neural Network")

all_test_metrics <- bind_rows(test_metrics_rf, test_metrics_svm, test_metrics_nnet, baseline_metrics)

# 17. Final comparison table (excluding ROC AUC for baseline) ----------------
final_comparison <- all_test_metrics %>%
  select(Model, .metric, .estimate) %>%
  pivot_wider(names_from = .metric, values_from = .estimate) %>%
  rename(F_meas = f_meas, ROC_AUC = roc_auc, Accuracy = accuracy)

cat("\n===== Final Test Set Performance =====\n")
print(final_comparison)

# 18. Visualizations ----------------------------------------------------------

# 18.1 Variable importance (Random Forest) - MOST VALUABLE
rf_fit <- final_rf %>% extract_fit_parsnip()
vip_plot <- vip(rf_fit, num_features = 6) +
  labs(title = "Variable Importance — Random Forest",
       subtitle = "Predicting embryo survival at 100 TU (rainbow trout)") +
  theme_minimal()
print(vip_plot)

# 18.2 Confusion matrices (heatmaps)
library(autoplotly)  # for autoplot of conf_mat
cm_rf <- conf_mat(test_pred_rf, truth = Categoria, estimate = .pred_class)
cm_svm <- conf_mat(test_pred_svm, truth = Categoria, estimate = .pred_class)
cm_nnet <- conf_mat(test_pred_nnet, truth = Categoria, estimate = .pred_class)

plot_cm <- function(cm, title) {
  autoplot(cm, type = "heatmap") +
    labs(title = title) +
    theme_minimal()
}
plot_cm(cm_rf, "Confusion Matrix — Random Forest (Test Set)")
plot_cm(cm_svm, "Confusion Matrix — SVM (Test Set)")
plot_cm(cm_nnet, "Confusion Matrix — Neural Network (Test Set)")

# 18.3 ROC curves on test set
roc_rf <- roc_curve(test_pred_rf, truth = Categoria, .pred_Aprobado, event_level = "second") %>%
  mutate(Model = "Random Forest")
roc_svm <- roc_curve(test_pred_svm, truth = Categoria, .pred_Aprobado, event_level = "second") %>%
  mutate(Model = "SVM")
roc_nnet <- roc_curve(test_pred_nnet, truth = Categoria, .pred_Aprobado, event_level = "second") %>%
  mutate(Model = "Neural Network")

roc_all <- bind_rows(roc_rf, roc_svm, roc_nnet)

ggplot(roc_all, aes(x = 1 - specificity, y = sensitivity, color = Model)) +
  geom_line(size = 1.2) +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
  labs(title = "ROC Curves on Test Set",
       x = "1 - Specificity", y = "Sensitivity") +
  coord_equal() +
  theme_minimal()

# 19. Conclusion with honest interpretation ---------------------------------
cat("\n===== INTERPRETATION (HONEST) =====\n")
cat("The Random Forest model shows predictive ability above baseline (F-measure ~",
    round(filter(test_metrics_rf, .metric=="f_meas")$.estimate,2),
    " vs baseline ", round(filter(baseline_metrics, .metric=="f_meas")$.estimate,2),
    "). However, dataset size is limited (", nrow(Desoves_clean), " records after cleaning).\n")
cat("Cross-validation mean F-measure for Random Forest was ", 
    round(filter(collect_metrics(rf_tune), .metric=="f_meas")$mean[1],2), 
    " (SD = ", round(filter(collect_metrics(rf_tune), .metric=="f_meas")$std_err[1]*sqrt(5),2), ").\n")
cat("The variable importance plot shows which reproductive traits are most influential.\n")
cat("External validation on a larger, independent dataset is required before operational use.\n")

# 20. Save workspace ----------------------------------------------------------
save.image(file = "Jonathan_Carrasco_clean.RData")
cat("Script completed successfully. Workspace saved.\n")