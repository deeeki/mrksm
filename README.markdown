# Mrksm

downloader for images on Mariko Shinoda's diary

## Install

    git clone git://github.com/deeeki/mrksm.git
    cd mrksm
    bundle install

## Usage

### Normal

    ruby mrksm.rb

images will be saved into "./image" directory.

### Saving specific directory

    ruby mrksm.rb -d /path/to/dist

## Features

- generate sub directory named with the entry posted date
- save images renaming sequential number
- next time, download only new images on a new entry

## Supported versions

- Ruby 1.9.2 or higher
