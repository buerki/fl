FL 0.5.5
======================


### DESCRIPTION


fl.sh is a shell script that facilitates the following tasks:

- annotation of text files with formulaic expressions
- production of a list of formulaic expressions that occur in a given text
- calculation of formulaic densities of a given text

All of these functions require a source list of expressions to be available.

### SUPPORTED PLATFORMS
This version is tested and validated on MacOS BigSur and Manjaro Linux, but should work on later versions of MacOS and on other distributions based on BSD and Linux.


### INSTALLATION

Some functions of this software require the N-Grams Package (NGP) to be installed first. The NGP can be obtained from [here](http://buerki.github.io/ngramprocessor/). Once the NGP is installed, follow the instructions below.

To permanently install the programme so it can be run from the command line in a terminal, place the `fl.sh`, `fl-density.sh` and `tidy.sh` files (they are in the `bin` directory) into the directory `/usr/local/bin`. Alternatively, double-click (on Manjaro, right-click and choose 'run as program') on the `installer.command` (on MacOS, if permission denied, right-click on the installer, then 'open' and 'open' again. If an error message says 'shell-init: error retrieving current directory', try opening a Terminal window, then type `cd ` (with a space after) and move the `fl_0.5.x` directory into the Terminal window, then press ENTER. After this, double-clicking on `installer.command` should work). <!--The programme can also be run without being permanently installed (see next section).-->

### OPERATION

Open a Terminal application window and type the following, then press ENTER:

		  fl.sh

<!--To run the programme without it being permanently installed, right-click on `fl.sh` and choose the option to run the file as a programme (or on MacOS, open with Terminal application). It may be necessary to give permission to execute the file, which can be done -->

The following screen should then appear:


          FL
          version 0.5.5


          A   annotate a text file with occurrences of formulaic sequences.
              (this additionally produces lists of sequences as in L)

          L   produce a list of formulaic sequences found in a text file.

          D   calculate the formulaic language density of a text file based
              on expression tokens.

          W   calculate the formulaic language density of a text file based
              on word tokens that are part of formulaic expressions.

          w   same as 'W' and 'D', but with overlapping expressions
              (including the words in them) consolidated.

          H   display help, including a glossary of terms

          x   exit
              
          >

You can then enter your choice and follow the instructions. For most functions, the programme will ask to be supplied with a plain text file with the extension `.txt` to be processed (or a folder that contains exclusively such files). Subsequently, a database file will need to be provided. This is the list of expressions that should be processed. This database file needs to be formatted in the format of the `FLtestdb.dat` file included with this programme. This is a sample list and can be opened with a word processor (it is in plain text format).

More advanced features are available by calling the programme `fl-density.sh`. A list of options are available by typing `fl-density.sh -h`.


#### TESTS

To test the operation of `fl` a number of test data files are included in the `test_data` directory. Those can be used to test the software and compare outputs. Please note that depending on the platform, there may be very slight variations in figures, especially consolidated frequencies. Test files include the following:

- `MSlist.dat` database of expressions included in the Phrasal Expressions list by Martinez and Schmitt, 2012 (doi:10.1093/applin/ams010)
- `FLtestdb.dat` database of 4,500 phrases extracted from Wikipedia dumps.
- `Fanon.txt` text of an extract of the English language Wikipedia entry for Franz Fanon (March 2025)
- `testtext.txt` a test text file
- `testtext.FSs.txt` list of expressions from the `FLtestdb.dat` database found in `testtext.txt` using the 'L' option.
- `testtext.md` is the `testtext.txt` input file, marked up with the expressions in `FLtestdb.dat` and saved as markdown file.
- `Fanon.FSs.txt` list of expressions from the `MSlist.dat` database found in `Fanon.txt` using the 'L' option.
- `Fanon.md` is the `Fanon.txt` input file, marked up with the expressions in `MSlist.dat` and saved as markdown file.
- `tallies_Fanon+MSlist.txt` shows the results of the `w` option with input files `Fanon.txt` and `MSlist.dat`.



#### AUTHOR

fl was written by [Andreas Buerki](https://www.cardiff.ac.uk/people/view/148384-buerki-andreas), contact: <buerkiA@cardiff.ac.uk> 





#### COPYRIGHT

This software is (c) 2017, 2020, 2021, 2025 Cardiff University.
Licensed under the EUPL v1.2 (the European Union Public Licence) which is an open-source licence (see the LICENSE.txt file for the full licence).

The project resides at [http://buerki.github.com/fl/](http://buerki.github.com/fl/) and new versions will be posted there. Suggestions and feedback are welcome. To be notified of new releases, click on the 'Watch' button at the above address and sign in.

