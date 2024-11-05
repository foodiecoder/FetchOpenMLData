using FetchOpenMLData
using DataFrames

function run_iris_example()
    println("Fetching iris dataset...")

    try
        # Fetch the dataset
        X_train, X_test, y_train, y_test = fetch_openml(
            data_id=61,
            data_home="examples/data/",
            target_column="class",
            cache=true
        )

        println("\nDataset information:")
        println("Number of features: $(ncol(X_train))")
        println("Feature names: $(names(X_train))")
        println("Unique classes: $(unique(y_train))")

        println("\nTrain set size: $(nrow(X_train))")
        println("Test set size: $(nrow(X_test))")

        return X_train, X_test, y_train, y_test
    catch e
        println("Error in example: $e")
        rethrow(e)
    end
end

function main()
    run_iris_example()
end

main()


#=
# Run the example if the file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    run_iris_example()
end
=#