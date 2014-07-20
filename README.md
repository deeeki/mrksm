# Mrksm

A downloader for images on Mariko Shinoda's diary :dog:

## Install

    git clone https://github.com/deeeki/mrksm
    cd mrksm
    bundle install

## Usage

### Download Latest Images

    ./bin/mrksm

This detects images only on recent entries.
The images are saved into `./images` directory.

### Download All Images

    ./bin/mrksm --all

### Option - Specify the directory

    ./bin/mrksm --dir /path/to/dist

### Option - Specify the period

    ./bin/mrksm --all --from 201401 --to 201407

This works only in `--all` mode.

## Features

- saving into each sub directory named with the date which entry posted
- traffic friendly (hopefully)

## Supported versions

- Ruby 2.0.0 or higher
