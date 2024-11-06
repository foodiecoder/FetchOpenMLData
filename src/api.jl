"""
Constant for the base URL of the OpenML API.
"""
const BASE_URL = "https://www.openml.org/api/v1/json"
const MAX_RETRIES = 3
const RETRY_DELAY = 1  # seconds

"""
    get_dataset_id(name::Union{String, Nothing}, data_id::Union{Int, Nothing})

Get dataset ID from either name or data_id.
"""
function get_dataset_id(name::Union{String,Nothing}, data_id::Union{Integer,Nothing})::Int64
    if isnothing(name) && isnothing(data_id)
        throw(GeneralOpenMLError("Either name or data_id must be provided"))
    elseif !isnothing(data_id)
        return Int64(data_id)
    elseif !isnothing(name)
        try
            encoded_name = HTTP.escapeuri(name)
            response = HTTP.get("$BASE_URL/data/list/data_name/$encoded_name")
            if response.status == 404 || response.status == 412
                throw(DatasetNotFoundError("Dataset '$name' not found"))
            elseif response.status != 200
                throw(APIError("Failed to fetch dataset ID: $(response.status)"))
            end
            data_info = JSON3.read(IOBuffer(response.body))
            return data_info["data"]["dataset"][1]["did"] |> Int64
        catch e
            if isa(e, HTTP.ExceptionRequest.StatusError)
                if e.status == 404 || e.status == 412
                    throw(DatasetNotFoundError("Dataset '$name' not found"))
                else
                    throw(APIError("Failed to fetch dataset ID: $(e.status)"))
                end
            else
                throw(APIError("Failed to fetch dataset ID: $e"))
            end
        end
    else
        throw(GeneralOpenMLError("Either name or data_id must be provided"))
    end
end

"""
    get_dataset_info(dataset_id::Int, base_url::String)

Fetch dataset information from OpenML API.
"""
function get_dataset_info(dataset_id::Int64)::OrderedDict{String,Any}
    headers::Dict{String,String} = Dict("accept" => "application/json")

    try
        headers["apikey"] = get_api_key()
    catch e
        @warn "API key not set. Some datasets may be inaccessible."
    end

    url::String = "$(BASE_URL)/data/$(dataset_id)"
    local response::Union{HTTP.Messages.Response,Nothing} = nothing

    for attempt in 1:MAX_RETRIES
        try
            response = HTTP.request("GET", url; headers=headers)
            break
        catch e
            if e isa HTTP.StatusError && e.status >= 500
                if attempt == MAX_RETRIES
                    throw(APIError("Failed after $(MAX_RETRIES) attempts"))
                end
                @info "Request failed with status code $(e.status), retrying ($(attempt)/$(MAX_RETRIES))"
                sleep(RETRY_DELAY)
            else
                rethrow(e)
            end
        end
    end

    isnothing(response) && throw(APIError("No response received after $MAX_RETRIES attempts"))
    response.status != 200 && throw(APIError("Failed to fetch dataset info: $(response.status)"))

    dataset_description = JSON3.read(response.body).data_set_description
    result = OrderedDict{String,Any}(String(k) => v for (k, v) in pairs(dataset_description))

    if !haskey(result, "name")
        @warn "Dataset description does not contain a 'name' key for dataset ID: $dataset_id"
    end

    return result
end

#= 126 possible
function get_dataset_info(dataset_id::Int64)::OrderedDict{String,Any}
    # Pre-allocate headers with type annotation
    headers::Dict{String,String} = Dict("accept" => "application/json")

    try
        headers["apikey"] = get_api_key()::String
    catch e
        @warn "API key not set. Some datasets may be inaccessible."
    end

    # Type annotation for response
    local response::Union{HTTP.Messages.Response,Nothing} = nothing

    for attempt in 1:MAX_RETRIES
        try
            response = HTTP.get("$BASE_URL/data/$dataset_id", headers=headers)
            break
        catch e
            if e isa HTTP.ExceptionRequest.StatusError && e.status >= 500
                @info "Request failed with status code $(e.status), retrying ($attempt/$MAX_RETRIES)"
                sleep(RETRY_DELAY)
            else
                throw(e)
            end
        end
    end

    # Early return if response is nothing
    isnothing(response) && throw(APIError("No response received after $MAX_RETRIES attempts"))

    response.status != 200 && throw(APIError("Failed to fetch dataset info: $(response.status)"))

    # Parse response body
    response_data = JSON3.read(response.body)
    dataset_description = response_data.data_set_description

    # Create result dictionary with explicit type
    result::OrderedDict{String,Any} = OrderedDict{String,Any}()

    # Convert to OrderedDict with String keys
    for (k, v) in pairs(dataset_description)
        result[String(k)] = v
    end

    # Warn if name is missing
    if !haskey(result, "name")
        @warn "Dataset description does not contain a 'name' key for dataset ID: $dataset_id"
    end

    return result
end
=#

#= 300
function get_dataset_info(dataset_id::Int64)::OrderedDict{String,Any}
    headers = Dict("accept" => "application/json")
    try
        headers["apikey"] = get_api_key()
    catch e
        @warn "API key not set. Some datasets may be inaccessible."
    end
    response = nothing # Initialize response to nothing
    for attempt in 1:MAX_RETRIES
        try
            response = HTTP.get("$BASE_URL/data/$dataset_id", headers=headers)
            break
        catch e
            if e isa HTTP.ExceptionRequest.StatusError && e.status >= 500
                @info "Request failed with status code $(e.status), retrying ($attempt/$MAX_RETRIES)"
                sleep(RETRY_DELAY)
            else
                throw(e)
            end
        end
    end

    if response.status != 200
        throw(APIError("Failed to fetch dataset info: $(response.status)"))
    end
    allow_symbols = false
    response_data = JSON3.read(response.body)
    dataset_description = response_data.data_set_description

    if haskey(dataset_description, "name")
        return OrderedDict(String(k) => v for (k, v) in pairs(dataset_description)) # convert symbol to string
    else
        @warn "Dataset description does not contain a 'name' key for dataset ID: $dataset_id"
        return OrderedDict(String(k) => v for (k, v) in pairs(dataset_description))
    end
end
=#
