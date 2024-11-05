using Test
using HTTP
using DataFrames
using OrderedCollections
using CategoricalArrays
using FetchOpenMLData


@testset "FetchOpenMLData.jl" begin
    @testset "API Key Management" begin
        test_key = "your_api_key_here"
        FetchOpenMLData.set_api_key(test_key)
        @test FetchOpenMLData.get_api_key() == test_key
    end

    @testset "Dataset ID Fetching" begin
        @test_throws FetchOpenMLData.OpenMLError FetchOpenMLData.get_dataset_id(nothing, nothing)
        @test FetchOpenMLData.get_dataset_id(nothing, 42) == 42
        @test_throws Union{FetchOpenMLData.DatasetNotFoundError,FetchOpenMLData.APIError} FetchOpenMLData.get_dataset_id("nonexistent_dataset", nothing)
        @test FetchOpenMLData.get_dataset_id("iris", nothing) isa Int64
    end

    @testset "Dataset Info Fetching" begin
        try
            FetchOpenMLData.get_dataset_info(-1)
        catch e
            @test isa(e, HTTP.ExceptionRequest.StatusError)
            @test e.status == 412
        end

        iris_info = FetchOpenMLData.get_dataset_info(61)
        @test iris_info isa OrderedCollections.OrderedDict
        @test haskey(iris_info, "name")
        @test iris_info["name"] == "iris"
    end

    @testset "Cache Directory" begin
        @test FetchOpenMLData.get_cache_dir(nothing) == joinpath(pwd(), "data")
        @test FetchOpenMLData.get_cache_dir("/tmp") == "/tmp"
    end

    @testset "Dataset Processing" begin
        iris_info = FetchOpenMLData.get_dataset_info(61)
        df = FetchOpenMLData.process_dataset(iris_info, nothing, true)
        @test df isa DataFrame
        @test size(df, 1) == 150
        @test size(df, 2) == 5
    end

    @testset "Feature-Target Splitting" begin
        df = DataFrame(x1=[1, 2, 3], x2=[4, 5, 6], y=[7, 8, 9])
        X_train, X_test, y_train, y_test = FetchOpenMLData.split_features_target(df, "y") # Correctly unpack 4 return values

        @test size(X_train, 2) == 2  # Test X_train
        @test size(y_train, 2) == 1  # Test y_train and correct column count
        @test size(X_test, 2) == 2 # Test X_test
        @test size(y_test, 2) == 1 # Test y_test and correct column count

        @test_throws MethodError FetchOpenMLData.split_features_target(df, nothing) # Test for MethodError
    end

    @testset "Full fetch_openml Function" begin
        X_train, X_test, y_train, y_test = fetch_openml(
            name="iris",
            target_column="class"
        )

        # Test data structure
        @test X_train isa DataFrame
        @test X_test isa DataFrame
        @test y_train isa Vector || y_train isa CategoricalVector || (y_train isa DataFrame && size(y_train, 2) == 1)
        @test y_test isa Vector || y_test isa CategoricalVector || (y_test isa DataFrame && size(y_test, 2) == 1)

        # Test data splitting
        total_samples = size(X_train, 1) + size(X_test, 1)
        @test total_samples == 150  # Total number of samples in iris dataset
        @test size(X_train, 2) == 4  # Number of features
        @test isapprox(size(X_test, 1) / total_samples, 0.2, atol=0.01)  # Test split ratio

        # Test target values
        @test begin
            all_y = vcat(y_train[!, 1], y_test[!, 1])
            Set(unique(all_y)) == Set(["Iris-setosa", "Iris-versicolor", "Iris-virginica"])
        end

        # Test for non-existent dataset
        @test_throws Union{FetchOpenMLData.DatasetNotFoundError,FetchOpenMLData.APIError} fetch_openml(name="nonexistent_dataset")
    end

    @testset "Custom parameters fetch_openml Function" begin
        (X_train, X_test, y_train, y_test) = fetch_openml(
            name="iris",
            test_size=0.3,
            random_seed=42
        )

        @test isapprox(size(X_test, 1) / (size(X_train, 1) + size(X_test, 1)), 0.3, atol=0.01)
    end


    @testset "Caching Mechanism" begin end

    @testset "User Input for Target Column" begin
        # Create a sample dataset for testing
        data = DataFrame(
            sepal_length=[5.1, 4.9, 4.7],
            sepal_width=[3.5, 3.0, 3.2],
            petal_length=[1.4, 1.4, 1.3],
            petal_width=[0.2, 0.2, 0.2],
            class=["setosa", "setosa", "setosa"]
        )

        # Mock user input for target column indices
        input = IOBuffer("5 1\n")
        X_train, X_test, y_train, y_test = FetchOpenMLData.fetch_openml_with_user_input(data, input)
        @test X_train isa DataFrame
        @test y_train isa DataFrame
        @test size(y_train, 2) == 2
        @test names(y_train) == ["class", "sepal_length"]

        #Test invalid inputs
        @test_throws ArgumentError FetchOpenMLData.fetch_openml_with_user_input(data, IOBuffer("6 1\n"))  # Out of range
        @test_throws ArgumentError FetchOpenMLData.fetch_openml_with_user_input(data, IOBuffer("\n"))     # Empty input
        @test_throws ArgumentError FetchOpenMLData.fetch_openml_with_user_input(data, IOBuffer("a b\n"))  # Non-numeric
        @test_throws ArgumentError FetchOpenMLData.fetch_openml_with_user_input(data, IOBuffer("0 1\n"))  # Below range
    end
end

