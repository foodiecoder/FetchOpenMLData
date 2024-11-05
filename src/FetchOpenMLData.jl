module FetchOpenMLData

using Random
using HTTP
using JSON3
using TOML
using ARFFFiles
using CSV
using DataFrames
using OrderedCollections
using CategoricalArrays
using Printf
using Logging

include("errors.jl")
include("config.jl")
include("api.jl")
include("utils.jl")

export OpenMLError, APIError, DatasetNotFoundError, ConfigurationError
export fetch_openml, set_api_key

function __init__()
    api_key = load_api_key()
    if !isempty(api_key)
        set_api_key(api_key)
    else
        @warn "No API key found. Some datasets may be inaccessible."
    end
end

end
