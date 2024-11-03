using FetchOpenMLData
using Documenter

DocMeta.setdocmeta!(FetchOpenMLData, :DocTestSetup, :(using FetchOpenMLData); recursive=true)

makedocs(;
    modules=[FetchOpenMLData],
    authors="Thura Z.",
    sitename="FetchOpenMLData.jl",
    format=Documenter.HTML(;
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
