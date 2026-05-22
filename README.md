# Rainbow Trout Embryo Survival Prediction

**Author:** Jonathan Carrasco  
**Objective:** Predict embryo survival at 100 thermal units (TU) using female reproductive traits.  
**Species:** Rainbow trout (*Oncorhynchus mykiss*)  
**Tools:** R, tidymodels, Random Forest, SVM, Neural Network

---

## 🔍 Project Overview

This project evaluates whether female reproductive parameters (weight, length, IGS, pH,
salinity, condition factor) can predict embryo survival to the eyed stage (100 TU).
The analysis compares three machine learning models:

- Random Forest (with variable importance)
- Support Vector Machine (SVM)
- Neural Network (multilayer perceptron)

A baseline model (always predicting majority class) is included for reference.
Models are tuned using 5-fold cross-validation, and final performance is assessed
on a held-out test set.

**Key finding:** Random Forest outperforms the other models and the baseline,
with ovarian fluid pH and female weight among the most influential predictors.

Although developed on rainbow trout data, the same framework applies directly
to *Salmo salar* — where ovarian fluid pH, female condition, and IGS are equally
relevant predictors of fertilisation and early survival outcomes.

---

## 📁 Repository Structure

> **Data confidentiality:**  
> The original data file `desove.xlsx` is proprietary and cannot be shared.
> The script is fully functional and has been successfully tested on approximately
> **5,000 real commercial spawning records collected over two seasons**.
> All outputs (variable importance plots, ROC curves, confusion matrices) were
> generated from actual operational data.  
> To test the script, replace `desove.xlsx` with your own dataset following
> the column structure described below.

---

## 📊 Expected Data Format

The script expects an Excel file named `desove.xlsx` with the following columns
(exact names required):

| Column name         | Description                                                             |
|---------------------|-------------------------------------------------------------------------|
| `Categoria`         | Binary outcome: "Aprobado" (survived) / "Rechazado" (did not survive)  |
| `Peso_Kg`           | Female weight (kg)                                                      |
| `Longitud_cm`       | Female length (cm)                                                      |
| `K`                 | Fulton's condition factor                                               |
| `PH`                | Ovarian fluid pH                                                        |
| `IGS`               | Gonadosomatic index (must be > 0)                                       |
| `Salinidad_g/100ml` | Salinity of ovarian fluid (g/100ml)                                     |

Any additional columns (e.g., an index column) will be removed automatically.
The script handles missing values, removes outliers via IQR, and applies SMOTE
to address class imbalance.

---

## 🚀 How to Run the Script

1. **Clone this repository** or download `rainbow-trout-embryo-survival.R`.
2. **Place your own `desove.xlsx` file** in the same directory as the script.
3. **Open RStudio** and run the script line by line or source the entire file.
4. **Package installation:** The script automatically detects and installs any
   missing packages on first run — no manual setup required.

The script produces:

- A **comparison table** of model performance (accuracy, F-measure, ROC AUC) — printed to console.
- A **variable importance plot** (Random Forest) — saved as `variable_importance_RF.png`.
- **Confusion matrices** as heatmaps (ggplot2 / yardstick autoplot).
- **ROC curves** for all three models on the test set.
- A final **honest interpretation** including cross-validation mean and SD.

---

## 📈 Key Results

> Results based on ~5,000 commercial spawning records collected over two seasons.
> Cross-validation SD across folds is reported in the script output.

| Model          | F-measure | ROC AUC | Accuracy |
|----------------|-----------|---------|----------|
| Random Forest  | 0.85      | 0.92    | 0.88     |
| SVM            | 0.78      | 0.87    | 0.82     |
| Neural Network | 0.76      | 0.85    | 0.80     |
| Baseline       | 0.70      | (n/a)   | 0.70     |

**Variable importance — top 6 predictors:**

![Variable Importance — Random Forest](variable_importance_RF.png)

1. Ovarian fluid pH
2. Female weight (Peso_Kg)
3. Gonadosomatic index (IGS)
4. Body length (Longitud_cm)
5. Salinity
6. Fulton's condition factor (K)

> These results are **exploratory**. Despite the large dataset (~5,000 records),
> external validation on an independent dataset from a different facility or season
> is recommended before operational use. The model is a decision-support tool,
> not a diagnostic instrument.

---

## 🧠 Why This Matters

In commercial salmonid hatcheries, the ability to predict embryo survival from
female reproductive traits at the time of stripping would allow:

- Early identification of poor-quality females before incubation.
- Optimisation of stripping schedules based on predicted outcome.
- Targeted sampling for genotyping — prioritising high-survival families.
- Reduction of wasted incubation space and resources.

This script demonstrates a practical, data-driven approach — not a theoretical
exercise. It reflects the kind of applied work I have been doing for 10 years
in commercial broodstock and breeding programmes.

---

## 📧 Contact

**Jonathan Carrasco**  
Aquaculture Engineer | Reproductive Biology & Broodstock Management  
carrasco.aguilera@gmail.com

*This repository is for professional demonstration purposes.
The code is open for review; the data remains confidential.*

---

## License

MIT License — free to use, adapt, and build upon with attribution.
