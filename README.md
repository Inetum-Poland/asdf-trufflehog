<div align="center">

# asdf-trufflehog [![Build](https://github.com/inetum-poland/asdf-trufflehog/actions/workflows/build.yml/badge.svg)](https://github.com/inetum-poland/asdf-trufflehog/actions/workflows/build.yml) [![Lint](https://github.com/inetum-poland/asdf-trufflehog/actions/workflows/lint.yml/badge.svg)](https://github.com/inetum-poland/asdf-trufflehog/actions/workflows/lint.yml)

[trufflehog](https://github.com/trufflesecurity/trufflehog) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [asdf-trufflehog  ](#asdf-trufflehog--)
- [Contents](#contents)
- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `curl`

# Install

Plugin:

```shell
asdf plugin add trufflehog
# or
asdf plugin add trufflehog https://github.com/inetum-poland/asdf-trufflehog.git
```

trufflehog:

```shell
# Show all installable versions
asdf list-all trufflehog

# Install specific version
asdf install trufflehog latest

# Set a version globally (on your ~/.tool-versions file)
asdf global trufflehog latest

# Now trufflehog commands are available
trufflehog --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/inetum-poland/asdf-trufflehog/graphs/contributors)!

# License

See [LICENSE](LICENSE) (C) [Inetum Poland](https://github.com/inetum-poland/)
