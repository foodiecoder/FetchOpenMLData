"""
    get_cache_dir(data_home::Union{String, Nothing})

Get or create cache directory for downloaded datasets.
"""
function get_cache_dir(data_home::Union{String,Nothing})::String
    isnothing(data_home) ? joinpath(pwd(), "data") : data_home
end

"""
    get_cached_file(cache_dir::String, file_name::String, dataset_id::Int64, file_format::String)::Union{String,Nothing}

    Get cached file if it exists, otherwise return `nothing`.
"""
function get_cached_file(cache_dir::String, file_name::String, dataset_id::Int64, file_format::String)::Union{String,Nothing}
    cache_path = joinpath(cache_dir, "$(file_name)_$(dataset_id).$(file_format)")
    isfile(cache_path) ? cache_path : nothing
end

"""
    download_with_retry(url::String, cache_file::String, cache::Bool)::Vector{UInt8}
Download data from a URL with retries.
"""
function download_with_retry(url::String, cache_file::String, cache::Bool)::Vector{UInt8}
    for attempt in 1:MAX_RETRIES
        try
            response = HTTP.get(url)
            data = response.body
            if cache
                mkpath(dirname(cache_file))
                write(cache_file, data)
            end
            return data
        catch e
            if attempt == MAX_RETRIES
                throw(APIError("Download failed after $MAX_RETRIES attempts: $e"))
            end
            @warn "Download attempt $attempt failed, retrying..."
            sleep(RETRY_DELAY)
        end
    end
end

"""
    process_data(data::DataFrame, target_column)

Process the downloaded data and separate features and target.
"""
function process_dataset(dataset_info::OrderedDict, data_home::Union{String,Nothing}, cache::Bool)::DataFrame
    cache_dir = get_cache_dir(data_home)
    file_url = dataset_info["url"]
    file_name = dataset_info["name"]
    dataset_id = parse(Int64, dataset_info["id"])
    file_format = lowercase(split(file_url, ".")[end])

    cached_file = cache ? get_cached_file(cache_dir, file_name, dataset_id, file_format) : nothing

    if !isnothing(cached_file)
        @info "Loading cached data from $cached_file"
        return ARFFFiles.load(cached_file) |> DataFrame
    end

    @info "Downloading data from $file_url"
    cache_path = joinpath(cache_dir, "$(file_name)_$(dataset_id).$(file_format)")
    data = download_with_retry(file_url, cache_path, cache)

    return ARFFFiles.load(IOBuffer(data)) |> DataFrame
end

"""
    split_data(X::DataFrame, y::Vector; test_size=0.2, shuffle=true)

Split data into training and testing sets.
"""
function split_features_target(data::DataFrame, target_columns::Union{String,Vector{String}};
    test_size::Float64=0.2, random_seed::Union{Int,Nothing}=nothing)
    if test_size < 0 || test_size >= 1
        throw(ArgumentError("test_size must be between 0 and 1"))
    end

    if random_seed === nothing
        random_seed = rand(UInt32)
    elseif random_seed < 0
        throw(ArgumentError("random_seed must be a non-negative integer"))
    end

    Random.seed!(random_seed)

    if typeof(target_columns) <: String
        target_columns = [target_columns]
    end

    features = select(data, Not(target_columns))
    targets = select(data, target_columns)

    row_indices = randperm(size(data, 1))
    train_indices = row_indices[1:floor(Int, (1 - test_size) * length(row_indices))]
    test_indices = row_indices[floor(Int, (1 - test_size) * length(row_indices))+1:end]

    X_train = features[train_indices, :]
    X_test = features[test_indices, :]
    y_train = targets[train_indices, :]
    y_test = targets[test_indices, :]

    return X_train, X_test, y_train, y_test
end

"""
Main function
"""
function fetch_openml(;
    name::Union{String,Nothing}=nothing,
    version::Union{Int,Nothing}=nothing,
    data_id::Union{Int,Nothing}=nothing,
    data_home::Union{String,Nothing}=nothing,
    target_column::Union{String,Vector{String},Nothing}=nothing,
    cache::Bool=true,
    test_size::Float64=0.2,
    random_seed::Union{Int,Nothing}=nothing
)
    # Validate test_size
    if test_size < 0 || test_size >= 1
        throw(ArgumentError("test_size must be between 0 and 1"))
    end

    # Validate and set random_seed
    if random_seed === nothing
        random_seed = abs(rand(Int))  # Make sure it's positive
    elseif !(random_seed isa Int)
        throw(ArgumentError("random_seed must be an integer"))
    elseif random_seed < 0
        throw(ArgumentError("random_seed must be a non-negative integer"))
    end

    try
        dataset_id = get_dataset_id(name, data_id)
        dataset_info = get_dataset_info(dataset_id)

        data = process_dataset(dataset_info, data_home, cache)

        if !isnothing(target_column)
            X_train, X_test, y_train, y_test = split_features_target(data, target_column, test_size=test_size, random_seed=random_seed)
            return X_train, X_test, y_train, y_test
        elseif haskey(dataset_info, "default_target_attribute")
            default_target = dataset_info["default_target_attribute"]
            @info "Using default target column: $default_target"
            X_train, X_test, y_train, y_test = split_features_target(data, default_target, test_size=test_size, random_seed=random_seed)
            return X_train, X_test, y_train, y_test
        else
            @warn "No target column specified and no default target column found. Returning the entire dataset."
            return data
        end

    catch e
        if e isa DatasetNotFoundError
            throw(e)  # Re-throw DatasetNotFoundError as is
        elseif e isa HTTP.ExceptionRequest.StatusError && e.status == 404
            throw(DatasetNotFoundError("Dataset not found: $(name !== nothing ? name : data_id)"))
        else
            throw(APIError("Error in fetch_openml: $e"))
        end
    end
end


function format_info(i, col)
    io = IOBuffer()
    print(io, rpad("$i.", 3), "$col")
    return String(take!(io))
end

function fetch_openml_with_user_input(data::DataFrame, io::IO=stdin)::Tuple{DataFrame,DataFrame,DataFrame,DataFrame}
    @info "Available columns: "
    for (i, col) in enumerate(names(data))
        #@info @sprintf("%2d. %s", i, col) //using Printf like C std library
        @info format_info(i, col)
    end
    @info "Please enter the indices of the target column(s) separated by spaces: "
    #Read user input
    user_input = ""
    try
        if io == stdin
            user_input = readline()
        else
            user_input = String(take!(io))
        end
    catch e
        throw(ArgumentError("Failed to read input: $e"))
    end

    try
        target_indices = parse.(Int, split(user_input))

        if any(target_indices .< 1) || any(target_indices .> ncol(data))
            throw(ArgumentError("Invalid column index(es) provided."))
        end

        target_columns = names(data)[target_indices]
        return split_features_target(data, target_columns)
    catch e
        if isa(e, ArgumentError)
            throw(e)
        else
            throw(ArgumentError("Invalid input format. Please provide space-separated numbers."))
        end
    end
end
