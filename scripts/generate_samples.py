import os
from functools import reduce
from operator import and_
import numpy as np
import pandas as pd

np.random.seed(42)

def data_selection(df: pd.DataFrame, filters_: dict, sample: float = None, columns: list = None):
    filters = [df[column].apply(func) for column, func in filters_.items()]
    res = df[reduce(and_, filters)]
    if columns is None:
        pass
    else:
        res = res[columns] 
    res = res.copy().reset_index(drop = True)
    return res if sample is None else res.sample(sample)

def dist(x1, y1, x2, y2):
    # https://sciencing.com/understand-latitude-longitude-5752494.html
    return ((x1 - x2) ** 2 + (y1 - y2) ** 2) ** (1/2) * 10_000 / 90

# TODO parametrize numbers into variables

sample_size = 10_000
L = 50
n_samples = 4
N = 1_000

columns = ["parsed_date", "Primary Type", "Location Description", "Arrest", "Latitude", "Longitude", "Location"]

df_full = pd.read_csv("data/raw/Chicago_Crimes_2012_to_2017.csv", header = 0)
df_full["parsed_date"] = pd.to_datetime(df_full["Date"])
df_full.dropna(subset = columns, inplace = True)
df_full["weekofyear"] = df_full.parsed_date.dt.isocalendar().week
df_full["monthofyear"] = df_full.parsed_date.dt.month

crime_types_percentage = (df_full["Primary Type"].value_counts().cumsum() / df_full.shape[0]).iloc[:5]
crimes_types = crime_types_percentage.index.tolist()

filtered_df = data_selection(
    df_full, 
    {
        "Arrest": lambda x: x == False,
        "parsed_date": lambda x: x.month == 7,
        "Primary Type": lambda x: x in crimes_types
    },
    sample = sample_size,
    columns = columns
)

f"Keeping {filtered_df.shape[0]:,} ({filtered_df.shape[0] / df_full.shape[0] * 100:.2f}%) records"

filtered_df["shift"] = filtered_df.parsed_date.dt.hour // 8
# ["THEFT", "BATTERY", "CRIMINAL DAMAGE", "NARCOTICS", "ASSAULT"]
filtered_df["type_"] = filtered_df["Primary Type"].apply(lambda x: crimes_types.index(x))

# Touching a person that does not invite touching or blatantly says to stop is battery. 
# https://newmexicocriminallaw.com/typical-examples-of-assault-and-battery-acts/#:~:text=Touching%20a%20person%20that%20does,hurt%20them%2C%20would%20constitute%20battery.
costs = {"THEFT": 300, "BATTERY": 500, "CRIMINAL DAMAGE": 800, "NARCOTICS": 1_000, "ASSAULT": 500}
pd.Series(costs).to_csv(os.path.join("data", "cooked", "resource_cost.csv"))

# Select random locations
possible_locations = filtered_df.sample(L)["Location"]
possible_locations.to_csv(os.path.join("data", "cooked", "locations.csv"), index = False)

dist_from_center = possible_locations.apply(lambda loc: dist(*eval(loc), df_full.Latitude.mean(), df_full.Longitude.mean()))
dist_from_center.to_csv(os.path.join("data", "cooked", "dist_from_center.csv"))

# Select crime data (demand)
for i in range(n_samples + 1):
    sampled = filtered_df.sample(N, weights = filtered_df.groupby("Primary Type")["Primary Type"].transform("count"))
    distances = sampled.Location.apply(lambda loc: pd.Series(dist(*eval(loc), *eval(l)) for l in possible_locations))
    pd.concat([sampled, distances], axis = 1).to_csv(os.path.join("data", "cooked", f"col_sample_{i}.csv"))
    sampled[["type_", "shift"]].to_csv(os.path.join("data", "cooked", f"sample_{i}.csv"), index = False)
    distances.to_csv(os.path.join("data", "cooked", f"distances_{i}.csv"))