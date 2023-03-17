# Facility Location Problem on Chicago Crimes Dataset

This repository was created to store the final project developed for Decision and Risk Analysis discipline at [PUC-Rio](http://www.ind.puc-rio.br/en/). The objective is to choose a problem that has intrinsic uncertainty and use [Julia](https://julialang.org/) to model and optimize a decision.

## Optimization Background

The literature `TODO`

### Maximum Coverage

`TODO`

### FLEET ICT

`TODO` add model explanation

With this in mind, below is the maximum coverage formulation, as developed by [Oliveira, 2020 (PT)][DISSERTAO_CHARLES_PAULINO_DE_OLIVEIRA]:

$$
\begin{aligned}
    \text{MAX} \quad \Sigma_{i \in I, \; u \in U, \; t \in T} \quad d_{i, u}^t \cdot y_{i, u}^t \\
    s.a.\quad \Sigma_{j\in N_{i, j}} \quad x_{j, u}^{t} &\ge y_{i, u}^t \quad \forall i  \; \forall u  \; \forall t \\
    \Sigma_{j\in J}  \quad x_{j, u}^{t} &\le P_{u} \quad \forall u \; \forall t \\
    \Sigma_{u \in U}  \quad x_{j, u}^{t} &\le C_{j} \cdot z_{j}  \quad \forall j \; \forall t \\
    x_{j, u}^{t} &\le z_j \quad \forall j \; \forall u \; \forall t
\end{aligned}
$$

### Crimes in Chicago

For this project, crimes have three main components:

- type (e.g. `NARCOTICS`);
- location (e.g. `(41.827, -87.632)`);
- and time (e.g. `01/29/2013 03:33:00 PM`).

Given the objective to minimize cost given that it is possible to cover at least a certain percentage of reported crimes to the correct place and within a maximum distance. Therefore:

$$
\begin{gathered}
    \text{MIN} \quad \Sigma_{j \in J} \quad c_j \cdot z_j \\
    s.a. \quad
    \frac{\Sigma_{i \in I, \; u \in U, \; t \in T} \quad d_{i, u}^t \cdot y_{i, u}^t}{\Sigma_{i \in I, \; u \in U, \; t \in T} \quad d_{i, u}^{t}} &\ge \text{cov} \\
        ...
\end{gathered}
$$

## Running

### Data

The data used in this project is available at [Kaggle](https://www.kaggle.com/datasets/currie32/crimes-in-chicago) and can be downloaded directly using [Kaggle's API](https://www.kaggle.com/docs/api) using `kaggle datasets download -d currie32/crimes-in-chicago -p raw/ --unzip`, which will download and unzip directly inside `raw/` folder.

### Visualization and Selection

Both visualization and selection are done using `python`, and an environment with the needed packages can be created by running `poetry install`.

Visualization is done in `data.ipynb`

Data is then selected and filered to reduce the computational power needed for the optimization model.

`TODO` cooked folder

### Location definitions

`TODO` how will possible facility locations be defined?

### Optimization

`julia --project=coverenv/ cover.jl`

[GeoStats.jl](https://github.com/JuliaEarth/GeoStats.jl)

## Important Mentions

- [Charles][charles] also developed a C++ project, available at [optimization_mclp_fleet_ict](https://github.com/charlespaulinoo/optimization_mclp_fleet_ict)

## Troubleshooting

- If [`scipy`](https://scipy.org/)'s (and plotly, plotly-express, folium) installation fails by not finding BLAS or Lapack libraries, follow [these steps](https://stackoverflow.com/questions/69954587/no-blas-lapack-libraries-found-when-installing-scipy-on-macos), and make sure the python version that is being used has an available wheel for `scipy`.

[charles]: https://github.com/charlespaulinoo
[DISSERTAO_CHARLES_PAULINO_DE_OLIVEIRA]: https://sig-arquivos.cefetmg.br/arquivos/2020157098a09e2498076fd7bdf5ac24e/DISSERTAO_CHARLES_PAULINO_DE_OLIVEIRA.pdf
