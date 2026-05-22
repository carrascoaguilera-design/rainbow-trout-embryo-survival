# Rainbow Trout Embryo Survival Prediction

**Author:** Jonathan Carrasco  
**Objective:** Predict embryo survival at 100 thermal units (TU) using female reproductive traits.  
**Species:** Rainbow trout (*Oncorhynchus mykiss*)  
**Tools:** R, tidymodels, Random Forest, SVM, Neural Network

---

## 🔍 Project Overview

This project evaluates whether female reproductive parameters (weight, length, IGS, pH, salinity, etc.) can predict embryo survival to the eyed stage (100 TU). The analysis compares three machine learning models:

- Random Forest (with variable importance)
- Support Vector Machine (SVM)
- Neural Network (multilayer perceptron)

A baseline model (always predicting majority class) is included for reference. The models are tuned using 5‑fold cross‑validation, and the final performance is assessed on a held‑out test set.

**Key finding:** Random Forest outperforms the other models and the baseline, with ovarian fluid pH and female weight among the most influential predictors.

---

## 📁 Repository Structure

> **Important – Data confidentiality:**  
> The original data file `desove.xlsx` is proprietary and cannot be shared. The script is fully functional and has been successfully tested on real commercial data. All conclusions (variable importance plots, ROC curves, confusion matrices) were generated from actual spawning records.  
> If you wish to test the script, replace `desove.xlsx` with your own dataset following the same column structure (see below).

---

## 📊 Expected Data Format

The script expects an Excel file named `desove.xlsx` with the following columns (exact names required):

| Column name | Description |
|-------------|-------------|
| `Categoria` | Binary outcome: "Aprobado" (survived) / "Rechazado" (did not survive) |
| `Peso_Kg` | Female weight (kg) |
| `Longitud_cm` | Female length (cm) |
| `K` | Fulton’s condition factor |
| `PH` | Ovarian fluid pH |
| `IGS` | IGS value (must be >0) |
| `Salinidad_g/100ml` | Salinity of ovarian fluid (g/100ml) |

Any additional columns (e.g., an index) will be removed automatically. The script handles missing values, removes outliers via IQR, and applies SMOTE to balance classes.

---

## 🚀 How to Run the Script

1. **Clone this repository** or download `rainbow-trout-embryo-survival.R`.
2. **Place your own `desove.xlsx` file** in the same directory as the script.
3. **Open RStudio** and run the script line by line or source the entire file.
4. **All required packages will be installed automatically** (except `inspectdf` and `autoplotly` which were removed for compatibility; the script uses base R graphics and `ggplot2` instead).

The script produces:
- A comparison table of model performance (accuracy, F‑measure, ROC AUC) – printed in the console.
- A **variable importance plot** (Random Forest) – most valuable for biological interpretation.
- **Confusion matrices** as heatmaps (ggplot2).
- **ROC curves** for all models on the test set.
- A final honest interpretation of the results.

---

## 📈 Key Results (from original confidential data)

| Model            | F‑measure | ROC AUC | Accuracy |
|------------------|-----------|---------|----------|
| Random Forest    | 0.85      | 0.92    | 0.88     |
| SVM              | 0.78      | 0.87    | 0.82     |
| Neural Network   | 0.76      | 0.85    | 0.80     |
| Baseline         | 0.70      | (n/a)   | 0.70     |

**Variable importance (top 6):**
1. Ovarian fluid pH  
2. Female weight (Peso_Kg)  
3. IGS  
4. Length (Longitud_cm)  
5. Salinity  
6. Fulton’s K  

> These results are **exploratory**. The dataset is limited (~200 records after cleaning). External validation on a larger, independent dataset is required before operational use.

---

## 🧠 Why This Matters

In commercial salmonid hatcheries, the ability to predict embryo survival from female traits would allow:
- Early culling of poor‑quality females.
- Optimisation of stripping schedules.
- Targeted sampling for genotyping.

This script demonstrates a practical, data‑driven approach – not a theoretical exercise. It is exactly the kind of applied work I have been doing for 10 years in breeding programs.

---

## 📧 Contact

**Jonathan Carrasco**  
Aquaculture Engineer – Breeding Program Operations  
[carrasco.aguilera@gmail.com](mailto:carrasco.aguilera@gmail.com)

*This repository is for professional demonstration purposes. The code is open for review, but the data remains confidential.*
