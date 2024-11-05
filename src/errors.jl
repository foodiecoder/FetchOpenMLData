"""
Custom error type for OpenML-related errors
"""
abstract type OpenMLError <: Exception end

struct APIError <: OpenMLError
    msg::String
end
struct DatasetNotFoundError <: OpenMLError
    msg::String
end

struct ConfigurationError <: OpenMLError
    msg::String
end

struct GeneralOpenMLError <: OpenMLError
    msg::String
end

# Add Base.showerror methods for nice error messages
Base.showerror(io::IO, e::OpenMLError) = print(io, e.msg)
Base.showerror(io::IO, e::APIError) = print(io, "API Error: ", e.msg)
Base.showerror(io::IO, e::DatasetNotFoundError) = print(io, "Dataset Not Found: ", e.msg)
Base.showerror(io::IO, e::ConfigurationError) = print(io, "Configuration Error: ", e.msg)