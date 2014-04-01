# Musical Chairs

A gem for swapping iOS simulator states. Saves all the documents, library and cache for the most recently used iOS app into the current folder with a named version. Commands are modeled after git. There's a writeup on the motivations for this: [artsy.github.com](http://artsy.github.com/blog/2013/03/29/musical-chairs/)

## Setup

    gem install chairs

The first time you run it, `chairs` will ask you to add `"chairs/"` to your .gitignore file if you have one, you should accept this, it gets big fast.

## Usage

Run `chairs` from the root folder of your project.

		chairs pull [name]        get documents and support files from latest built app and store as name.
		chairs push [name]        overwrite documents and support files from the latest build in Xcode.
		chairs rm   [name]        delete the files for the chair.
		chairs open               open the current app folder in Finder.
		chairs list               list all the current docs in working directory.


## Problems?

You can [open a new issue](/orta/chairs/issues). I'm usually very responsive to changes.

## Thanks to...
- [Frank Macreery](https://github.com/macreery) for giving some good advice.

## License
See the [LICENSE.txt](/orta/chairs/blob/master/LICENSE.txt) file included in the distribution.

## Copyright
Copyright (c) 2014 Orta Therox & Art.sy
