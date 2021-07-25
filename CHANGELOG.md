# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

# Unreleased
- Require Elixir 1.7 or newer
- Migrate from CircleCI to GitHub Actions

# 2.2.0 - 2020-02-01
- Require Elixir 1.6 or newer
- Enable locale to be passed as a string
- Update ExDoc dependency
- Remove Faker dependency

# 2.1.0 - 2018-12-08
- Update `Ecto` dependency to 3.0 version

# 2.0.4 - 2018-10-14
- Remove `Module.eval_quoted` calls.
- Migrate to CircleCI
- Add Apache 2.0 License
- Use Elixir formatter

# 2.0.3 - 2018-08-11
- Update cannonical URLs to GitHub repository

## 2.0.2 - 2017-09-29
- Support Elixir 1.5 and Erlant/OTP 20.
- Fix bug when passing the locale in a variable to `Trans.QueryBuilder.translated/3`.

## 2.0.1 - 2017-07-09
- Relax `Poison` dependency version restriction.
- Integrate Ebert for code style checks and static analysis.
- Fix typos and mistakes in README.

## 2.0.0 - 2017-04-11
- Rewrite the `Trans` module to use underscore functions to store configuration.
- Rewrite the `QueryBuilder` module to unify previous functions into a single macro with compile time checks. Translations can now be used directly when building queries and are compatible with functions and macros provided by `Ecto.Query` and `Ecto.Query.Api`.
- Update the `Translator` module to use the new underscore functions.
- Update documentation and improve the tests.

## 1.1.0 - 2017-02-28
- Make `Ecto` an optional dependency. If `Ecto` is not available the `QueryBuilder` module will not be compiled.

## 1.0.2 - 2017-02-19
- Remove `earmark` as a direct dependency since it is already required by `ex_doc`.
- Remove warnings when compiling with Elixir 1.4.
- Adds contribution guidelines detailed in `CONTRIBUTING.md`.

## 1.0.1 - 2016-10-22
- New testing environments for Travis CI.
- The project has now a changelog.
- Improved documentation.
- Improved README.

## 1.0.0 - 2016-07-30
- Support for Ecto 2.0.

## 0.1.0 - 2016-06-04
- Initial release with basic functionality and documentation.
