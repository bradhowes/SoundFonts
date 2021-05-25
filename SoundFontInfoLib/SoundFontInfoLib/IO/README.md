#  IO Namespace

These classes perform fast parsing of an SF2 file. There are actually two parsers here: 

* Parser -- only extracts the preset information and SF2 meta data from an SF2 file for use in the SoundFonts application
* File -- performs a more thorough parsing of an SF2 file, maintaining references to all of the various collections found in the file. Although 
this class can generate provide the same information that `Parser` can, this class can be used to build up rendering facilities to generate
audio samples based on the SF2 preset and instrument definitions.


