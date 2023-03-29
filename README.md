# GitHub Dependency Submission Action for Mix

:warning: This repository is not ready for use. Please check back later.

[![hex.pm badge](https://img.shields.io/badge/Package%20on%20hex.pm-informational)](https://hex.pm/packages/mix_dependency_submission)
[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)][docs]
[![.github/workflows/branch_main.yml](https://github.com/jshmrtn/mix-dependency-submission/actions/workflows/branch_main.yml/badge.svg)](https://github.com/jshmrtn/mix-dependency-submission/actions/workflows/branch_main.yml)
[![Coverage Status](https://coveralls.io/repos/github/jshmrtn/mix-dependency-submission/badge.svg?branch=main)](https://coveralls.io/github/jshmrtn/mix-dependency-submission?branch=main)

> Action that calculates dependencies for Mix and submits the list to the
> GitHub Dependency Submission API.

See [the documentation][docs].

## Installation

This package is not supposed to be installed directly. Use it inside inside your
GitHub Actions instead.

```yaml
on:
  push:
    branches:
      - "main"

name: "Dependency Submission"

jobs:
  report_mix_deps:
    name: "Report Mix Dependencies"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: jshmrtn/mix-dependency-submission@v0
        with:
          project-name: '[Project Application Name]'
```

## License

Copyright 2023 JOSHMARTIN GmbH

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:

  > <http://www.apache.org/licenses/LICENSE-2.0>

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

[docs]: https://hexdocs.pm/mix_dependency_submission

