"""
Configuration management for the OpenML API.
"""
@with_kw struct APIConfig
    key::String = ""
end

const API_STATE = Ref(APIConfig())

function set_api_key(key::String)
    API_STATE[] = APIConfig(key)
    nothing
end

function get_api_key()::String
    key = API_STATE[].key  # First get the APIConfig object, then access its key field
    isempty(key) && throw(ConfigurationError("API key not set"))
    return key
end

"""
    load_api_key()::String
Load API key from the environment variable `OPENML_API_KEY` or from the config file.
"""
function load_api_key()::String
    env_api_key = get(ENV, "OPENML_API_KEY", "")
    return !isempty(env_api_key) ? env_api_key :
           load_from_config_file(joinpath(@__DIR__, "config", "config.toml"), "api_key")
end

"""
Helper function to load a key from a config file.
"""
function load_from_config_file(config_path::String, key::String)::String
    isfile(config_path) || return ""
    config = TOML.parsefile(config_path)
    return get(config, key, "")
end