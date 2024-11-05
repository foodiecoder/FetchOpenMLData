# FetchOpenMLData

[![Build Status](https://github.com/foodiecoder/FetchOpenMLData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/foodiecoder/FetchOpenMLData.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/foodiecoder/FetchOpenMLData.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/foodiecoder/FetchOpenMLData.jl)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://foodiecoder.github.io/FetchOpenMLData.jl/stable)

A Julia package for efficiently fetching and processing datasets from OpenML.

## Features

- Easy dataset fetching from OpenML by ID or name
- Automatic caching of downloaded datasets
- Built-in preprocessing utilities
- Data splitting functionality
- Type-safe implementation
- Comprehensive error handling

## Installation

```julia
using Pkg
pkg"activate ."
pkg"instantiate"

## Quick Start

```julia
using OpenMLFetch

# Fetch the food dataset
X, y = fetch_openml(data_id=43423)

## Examples
```julia
# Fetching by Dataset Name
X_train, y_train = fetch_openml(name="iris", target_column="class")

# Using Custom Cache Directory
X_train, y_train = fetch_openml(
    data_id=iris,
    data_home="path/to/cache",
    target_column="class"
)
# Handling Multiple Target Columns
target_cols = ["Protein", "Fat", "Sat.Fat", "Carbs"]
X_train, y_train = fetch_openml(
    data_id=43423,
    target_column=target_cols
)

# Handling test.size and random_state
# Handling Multiple Target Columns
target_cols = ["Protein", "Fat", "Sat.Fat", "Carbs"]
X_train, y_train = fetch_openml(
    data_id=43423,
    target_column=target_cols,
    0.2, 123
)

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
