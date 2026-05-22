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
