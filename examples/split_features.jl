using FetchOpenMLData
using DataFrames
using ARFFFiles

# Load your data into a DataFrame
df = ARFFFiles.load(DataFrame, "examples/data/Nutritional-Facts-for-most-common-foods_43423.arff")

# Specify the target column(s)
target_cols = ["Protein", "Fat", "Sat.Fat", "Carbs"]

# Prepare the data with a default random seed (different each time)
X_train, X_test, y_train, y_test = FetchOpenMLData.split_features_target(df, target_cols)

# Prepare the data with a specific random seed (e.g., 123)
X_train, X_test, y_train, y_test = FetchOpenMLData.split_features_target(df, target_cols, random_seed=123)

# Invalid test_size
try
    FetchOpenMLData.split_features_target(df, target_cols, test_size=1.2)
catch e
    @warn "Error: $(e.msg)"
end

# Invalid random_seed
try
    FetchOpenMLData.split_features_target(df, target_cols, random_seed=-1)
catch e
    @warn "Error: $(e.msg)"
end
