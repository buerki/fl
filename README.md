FL 0.5.3
======================


### DESCRIPTION
***********

fl.sh is a shell script that facilitates the following tasks:

- annotation of text files with formulaic expressions
- production of a list of formulaic expressions that occur in a given text
- calculation of formulaic densities of a given text

All of these functions require a source list of expressions to be available.


### INSTALLATION
************

This software requires the N-Grams Package (NGP) to be installed first. The NGP can be obtained from [here](http://buerki.github.io/ngramprocessor/). Once the NGP is installed, follow the instructions below.

#### Using the supplied installers (recommended):

Double-clickable installers are provided for OS X and Xubuntu-Linux
Inside the `fl` directory, double-click on `Xubuntu_installer` (for Xubuntu), `OSX_installer` (OS X). Follow the instructions of the installer. It may be necessary to log out of your computer and log in again before the installation is active.


#### Manual installation / other flavours of Linux

1. open a Terminal window
 
      OS X: in Applications/Utilities
      
      Xbuntu Linux: via menu Applications>Accessories>Terminal
      
2. drop the `install.sh` script (located inside the `bin` directory) onto the terminal window and press ENTER. This should start the installation process.


### OPERATION
************
Open a Terminal application window (on MacOS, located under Applications > Utilities > Terminal; on Linux under Applications > Accessories > Terminal), and type the following and press ENTER:

		  fl.sh

If this fails, even though the installation was successful, it may be necessary to log out of the computer and log in again after the first installation.

The following screen should then appear:


          FL
          version 0.5.3


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
              
          >

You can then enter your choice and follow the instructions. For most functions, the programme will ask to be supplied with a plain text file with the extension `.txt` to be processed (or a folder that contains exclusively such files). Subsequently, a database file will need to be provided. This is the list of expressions that should be processed. This database file needs to be formatted in the format of the `FLtestdb.dat` file included with this programme. This is a sample list and can be opened with a word processor (it is in plain text format).

More advanced features are available by calling the programme `fl-density.sh`. A list of options are available by typing `fl-density.sh -h`.



###AUTHOR
******
fl was written by [Andreas Buerki](https://www.cardiff.ac.uk/people/view/148384-buerki-andreas), contact: <buerkiA@cardiff.ac.uk> 


###COPYRIGHT
*********
This software is (c) 2017, 2020, 2021 Cardiff University. At this time, the software is NOT LICENSED FOR USE OUTSIDE OF THE CENTRE FOR LANGUAGE AND COMMUNICATION RESEARCH AT CARDIFF UNIVERSITY.
