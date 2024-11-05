"""
Configuration management for the OpenML API.
"""
mutable struct APIConfig
    key::String
    APIConfig() = new("")
end

const API_STATE = OrderedDict{Symbol,Any}(:config => APIConfig())

function set_api_key(key::String)
    API_STATE[:config].key = key
    nothing
end

function get_api_key()::String
    key = API_STATE[:config].key
    isempty(key) && throw(ConfigurationError("API key not set"))
    return key
end

"""
    load_api_key()::String
Load API key from the environment variable `OPENML_API_KEY` or from the config file.
"""
function load_api_key()::String
    env_api_key = get(ENV, "OPENML_API_KEY", "")
    if !isempty(env_api_key)
        return env_api_key
    else
        config_path = joinpath(@__DIR__, "config", "config.toml")
        if isfile(config_path)
            config = TOML.parsefile(config_path)
            return get(config, "api_key", "")
        else
            @warn "Config file not found at $config_path"
            return ""
        end
    end
end