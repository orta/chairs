# Musical Chairs

A gem for swapping between app version in the iOS Simulator

## Setup

    gem install chairs

The first time you run it, chairs will ask you to add "chairs/" to your .gitignore file if you have one, you should accept this, it gets big fast.

## Usage

Run `chairs` from the root folder of your project.

		chairs pull [name]        get documents and support files from latest built app and store as name.
		chairs push [name]        overwrite documents and support files from the latest build in Xcode.
		chairs rm   [name]        delete the files for the chair.
		chairs open               open the current app folder in Finder.
		chairs list               list all the current docs in working directory.


## Problems?

You can [open a new issue](https://github.com/orta/muscialchairs/issues). I'm usually very responsive to changes.

## Thanks to...
- [Frank Macreery](https://github.com/macreery) for giving some good advice.

## License
See the LICENSE.txt file included in the distribution.

## Copyright
Copyright (c) 2012 Art.sy